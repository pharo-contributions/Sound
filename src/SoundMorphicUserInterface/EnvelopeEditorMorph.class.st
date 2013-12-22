"
I'm an editor to modify the envelops of a sound.

Here is a typical example of how to open me.

EnvelopeEditorMorph openOn: (FMsound brass1) copy title: 'brass1'
"
Class {
	#name : #EnvelopeEditorMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'sound',
		'soundName',
		'envelope',
		'hScale',
		'vScale',
		'graphArea',
		'pixPerTick',
		'limits',
		'limitXs',
		'limitHandles',
		'line',
		'prevMouseDown',
		'sampleDuration',
		'showAllEnvelopes',
		'denominator',
		'keyboard'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #open }
EnvelopeEditorMorph class >> openOn: aSound title: aString [
	"EnvelopeEditorMorph openOn: (FMsound brass1) copy title: 'brass1'"
	(self basicNew initOnSound: aSound title: aString) openInWorld
]

{ #category : #editing }
EnvelopeEditorMorph >> acceptGraphPoint: p at: index [ 
	| ms val points whichLim linePoint other boundedP |
	boundedP := p adhereTo: graphArea bounds.
	ms := self msFromX: boundedP x.
	points := envelope points.
	ms := self 
				constrain: ms
				adjacentTo: index
				in: points.
	(index = 1 or: [(whichLim := limits indexOf: index) > 0]) 
		ifTrue: 
			["Limit points must not move laterally"

			ms := (points at: index) x].
	val := self valueFromY: boundedP y.
	points at: index put: ms @ val.
	linePoint := (self xFromMs: ms) @ (self yFromValue: val).
	(whichLim notNil and: [whichLim between: 1 and: 2]) 
		ifTrue: 
			["Loop start and loop end must be tied together"

			other := limits at: 3 - whichLim.	" 1 <--> 2 "
			points at: other put: (points at: other) x @ val.
			line verticesAt: other put: (line vertices at: other) x @ linePoint y].
	"Make sure envelope feels the change in points array..."
	envelope 
		setPoints: points
		loopStart: limits first
		loopEnd: (limits second).
	^linePoint
]

{ #category : #construction }
EnvelopeEditorMorph >> addControls [
	| chooser |
	chooser := PopUpChoiceMorph new extent: 110@14;
		contentsClipped: 'Editing: ' , envelope name;
		target: self;
		actionSelector: #chooseFrom:envelopeItem:;
		getItemsSelector: #curveChoices.
	chooser arguments: (Array with: chooser).
	self addMorph: chooser.
	chooser align: chooser bounds topLeft with: graphArea bounds bottomLeft + (0@5).

	chooser := PopUpChoiceMorph new extent: 130@14;
		contentsClipped: 'Timbre: ' , soundName;
		target: self;
		actionSelector: #chooseFrom:soundItem:;
		getItemsSelector: #soundChoices.
	chooser arguments: (Array with: chooser).
	self addMorph: chooser.
	chooser align: chooser bounds topRight with: graphArea bounds bottomRight + (-50@5).

]

{ #category : #construction }
EnvelopeEditorMorph >> addCurves [
	"Add the polyLine corresponding to the currently selected envelope,
	and possibly all the others, too."
	| verts aLine |
	sound envelopes do:
		[:env | 
		(showAllEnvelopes or: [env == envelope]) ifTrue:
			[verts := env points collect:
				[:p | (self xFromMs: p x) @ (self yFromValue: p y)].
			aLine := EnvelopeLineMorph basicNew
						vertices: verts borderWidth: 1
						borderColor: (self colorForEnvelope: env).
			env == envelope
				ifTrue: [aLine borderWidth: 2.  line := aLine]
				ifFalse: [aLine on: #mouseUp send: #clickOn:evt:from:
							to: self withValue: env.
						self addMorph: aLine]]].
	self addMorph: line  "add the active one last (in front)"
]

{ #category : #menu }
EnvelopeEditorMorph >> addCustomMenuItems: menu hand: aHandMorph [
	super addCustomMenuItems: menu hand: aHandMorph.
	menu addLine.
	envelope updateSelector = #ratio: ifTrue:
		[menu add: 'choose denominator...' translated action: #chooseDenominator:].
	menu add: 'adjust scale...' translated action: #adjustScale:.
	SoundPlayer isReverbOn
		ifTrue: [menu add: 'turn reverb off' translated target: SoundPlayer selector: #stopReverb]
		ifFalse: [menu add: 'turn reverb on' translated target: SoundPlayer selector: #startReverb].
	menu addLine.
	menu add: 'get sound from lib' translated action: #chooseSound:.
	menu add: 'put sound in lib' translated action: #saveSound:.
	menu add: 'read sound from disk...' translated action: #readFromDisk:.
	menu add: 'save sound on disk...' translated action: #saveToDisk:.
	menu add: 'save library on disk...' translated action: #saveLibToDisk:.

]

{ #category : #editing }
EnvelopeEditorMorph >> addEnvelopeNamed: envName [
	| points env |
	points := OrderedCollection new.
	points add: 0@0.0;
		add: (envelope points at: envelope loopStartIndex) x@1.0;
		add: (envelope points at: envelope loopEndIndex) x@1.0;
		add: (envelope points last) x@0.0.
	envName = 'volume' ifTrue:
		[env := VolumeEnvelope points: points loopStart: 2 loopEnd: 3.
		env target: sound; scale: 0.7].
	envName = 'modulation' ifTrue:
		[env := Envelope points: (points collect: [:p | p x @ 0.5])
						loopStart: 2 loopEnd: 3.
		env target: sound; updateSelector: #modulation:;
			scale: sound modulation*2.0].
	envName = 'pitch' ifTrue:
		[env := PitchEnvelope points: (points collect: [:p | p x @ 0.5])
						loopStart: 2 loopEnd: 3.
		env target: sound; updateSelector: #pitch:; scale: 0.5].
	envName = 'random pitch:' ifTrue:
		[env := RandomEnvelope for: #pitch:.
		points := OrderedCollection new.
		points add: 0@(env delta * 5 + 0.5);
			add: (envelope points at: envelope loopStartIndex) x@(env highLimit - 1 * 5 + 0.5);
			add: (envelope points at: envelope loopEndIndex) x@(env highLimit - 1 * 5 + 0.5);
			add: (envelope points last) x@(env lowLimit - 1 * 5 + 0.5).
		env setPoints: points loopStart: 2 loopEnd: 3.
		env target: sound. ].
	envName = 'ratio' ifTrue:
		[denominator := 9999.  "No gridding"
		env := Envelope points: (points collect: [:p | p x @ 0.5])
						loopStart: 2 loopEnd: 3.
		env target: sound; updateSelector: #ratio:;
			scale: sound ratio*2.0].
	env ifNotNil:
		[sound addEnvelope: env.
		self editEnvelope: env]
]

{ #category : #construction }
EnvelopeEditorMorph >> addHandlesIn: frame [
	| handle |
	handle := PolygonMorph
		vertices: (Array with: 0@0 with: 8@0 with: 4@8)
		color: Color orange borderWidth: 1 borderColor: Color black.
	handle addMorph: ((BorderedMorph
			newBounds: ((self handleOffset: handle)-(2@0) extent: 1@(graphArea height-2))
			color: Color orange) borderWidth: 0).

	limitHandles := Array with: handle with: handle veryDeepCopy with: handle veryDeepCopy.
	1 to: limitHandles size do:
		[:i | handle := limitHandles at: i.
		handle on: #mouseDown
				send: #limitHandleMove:event:from:
				to: self withValue: i.
		handle on: #mouseMove
				send: #limitHandleMove:event:from:
				to: self withValue: i.
		self addMorph: handle.
		handle position: ((self xFromMs: 
			(envelope points at: (limits at: i)) x) @ 
				(graphArea top)) - (self handleOffset: handle)]
]

{ #category : #construction }
EnvelopeEditorMorph >> addKeyboard [
	keyboard := PianoKeyboardMorph new soundPrototype: sound.
	keyboard align: keyboard bounds bottomCenter with: bounds bottomCenter - (0@4).
	self addMorph: keyboard
]

{ #category : #menu }
EnvelopeEditorMorph >> adjustScale: evt [ 
	| scaleString oldScale baseValue |
	oldScale := envelope scale.
	scaleString := UIManager default request: 'Enter the new full-scale value...' translated
				initialAnswer: oldScale printString.
	scaleString isEmptyOrNil ifTrue: [^self].
	envelope scale: (Number readFrom: scaleString) asFloat.
	baseValue := envelope updateSelector = #pitch: ifTrue: [0.5] ifFalse: [0.0].
	envelope 
		setPoints: (envelope points collect: 
					[:p | 
					p x @ ((p y - baseValue) * oldScale / envelope scale + baseValue min: 1.0
								max: 0.0)])
		loopStart: (limits first)
		loopEnd: (limits second).
	self buildView
]

{ #category : #construction }
EnvelopeEditorMorph >> buildGraphAreaIn: frame [
	| r y |
	graphArea := BorderedMorph
		newBounds: ((frame left + 40) @ (frame top + 40)
		corner: (frame right+1) @ (frame bottom - 60))
		color: Color lightGreen lighter lighter.
	graphArea borderWidth: 1.
	self addMorph: graphArea.
	(envelope updateSelector = #pitch: and: [envelope scale <= 2.0]) ifTrue:
		["Show half-steps"
		r := graphArea innerBounds.
		0.0 to: 1.0 by: 1.0/12.0/envelope scale do:
			[:val |
			y := self yFromValue: val.
			graphArea addMorph: ((BorderedMorph
					newBounds: (r left@y extent: r width@1)
					color: Color veryLightGray)
						borderWidth: 0)]].
	(envelope updateSelector = #ratio: and: [denominator ~= 9999]) ifTrue:
		["Show denominator gridding"
		r := graphArea innerBounds.
		(0.0 to: 1.0 by: 1.0/denominator/envelope scale) do:
			[:v |
			y := self yFromValue: v.
			graphArea addMorph: ((BorderedMorph
					newBounds: (r left@y extent: r width@1)
					color: Color veryLightGray)
						borderWidth: 0)]].

]

{ #category : #editing }
EnvelopeEditorMorph >> buildScalesIn: frame [
	| env |
	env := envelope.
	pixPerTick := graphArea width // (self maxTime//10) max: 1.
	"hminortick := ( 1 + ( self maxTime // 800 ) ) * 10.
	hmajortick := ( 1 + ( self maxTime // 800 ) ) * 100."
	hScale := (Morph newBounds: ((graphArea left)@(frame top) corner: (self xFromMs: self maxTime)@(graphArea top - 1))) color: Color lightGreen.
"	hScale := (ScaleMorph newBounds: ((graphArea left)@(frame top) corner: (self xFromMs: self maxTime)@(graphArea top - 1)))
		start: 0 stop: self maxTime
		minorTick: hminortick minorTickLength: 3
		majorTick: hmajortick majorTickLength: 10
		caption: 'milliseconds' tickPrintBlock: [:v | v printString].
"
	self addMorph: hScale.
	vScale := (Morph newBounds: (0@0 extent: (graphArea height)@(graphArea left - frame left))) color: Color lightGreen.
	"vScale := ScaleMorph newBounds: (0@0 extent: (graphArea height)@(graphArea left - frame left))."
	env name = 'pitch'
		ifTrue:
		[env scale >= 2.0
			ifTrue:
			[vScale start: 0 stop: env scale
				minorTick: env scale / 24 minorTickLength: 3
				majorTick: env scale / 2.0 majorTickLength: 10
				caption: 'pitch (octaves)'
				tickPrintBlock: [:v | (v-(env scale/2)) asInteger printString]]
			ifFalse:
			[vScale start: 0 stop: env scale
				minorTick: 1.0/48.0 minorTickLength: 3
				majorTick: 1.0/12.0 majorTickLength: 10
				caption: 'pitch (half-steps)'
				tickPrintBlock: [:v | (v-(env scale/2)*12) rounded printString]]]
		ifFalse: [
			env name = 'random pitch:'
				ifTrue: [
					vScale start: 0.9 stop: 1.1
						minorTick: 0.2 / 50.0 minorTickLength: 3
						majorTick: 0.2 / 5.0 majorTickLength: 10
						caption: env name
						tickPrintBlock: [:v | v printString]]
				ifFalse: [
					vScale start: 0 stop: env scale
						minorTick: env scale / 50.0 minorTickLength: 3
						majorTick: env scale / 5.0 majorTickLength: 10
						caption: env name
						tickPrintBlock: [:v | v printString]].
		].
	vScale := TransformationMorph new asFlexOf: vScale.
	vScale angle: Float pi / 2.0.
	self addMorph: vScale.
	vScale position: (frame left)@(graphArea top-1) - (3@1).

]

{ #category : #construction }
EnvelopeEditorMorph >> buildView [
	| frame |
	self color: Color lightGreen.
	self removeAllMorphs.
	frame := self innerBounds.
	self buildGraphAreaIn: frame.
	self buildScalesIn: frame.
	self addHandlesIn: frame.
	self addCurves.
	line addHandles.
	self addControls.
	self addKeyboard
]

{ #category : #menu }
EnvelopeEditorMorph >> chooseDenominator: evt [
	| menu |
	menu := MenuMorph new.
	(Integer primesUpTo: 30) do:
		[:i |
		menu add: i printString
			target: self selector: #setDenominator:
			argument: i].
	menu addLine.
	menu add: 'none' target: self selector: #setDenominator: argument: 9999.
	menu popUpEvent: evt in: self world
]

{ #category : #menu }
EnvelopeEditorMorph >> chooseEnvelope: choice [
	| name |
	(choice beginsWith: 'edit ') ifTrue:
		[name := choice copyFrom: 'edit ' size+1 to: choice size.
		^ self editEnvelope: (sound envelopes detect:
				[:env | env name = name])].
	(choice beginsWith: 'add ') ifTrue:
		[name := choice copyFrom: 'add ' size+1 to: choice size.
		^ self addEnvelopeNamed: name].
	(choice beginsWith: 'remove ') ifTrue:
		[^ self removeEnvelope  "the current one"].

]

{ #category : #menu }
EnvelopeEditorMorph >> chooseFrom: chooserMorph envelopeItem: item [
	| name |
	(item beginsWith: 'edit ') ifTrue:
		[name := item copyFrom: 'edit ' size+1 to: item size.
		self editEnvelope: (sound envelopes detect:
				[:env | env name = name])].
	(item beginsWith: 'add ') ifTrue:
		[name := item copyFrom: 'add ' size+1 to: item size.
		self addEnvelopeNamed: name].
	(item beginsWith: 'remove ') ifTrue:
		[self removeEnvelope  "the current one"].
	chooserMorph contentsClipped: envelope name
]

{ #category : #menu }
EnvelopeEditorMorph >> chooseFrom: chooserMorph soundItem: item [
	self editSoundNamed: item.

]

{ #category : #menu }
EnvelopeEditorMorph >> chooseSound: evt [
	| menu |
	menu := MenuMorph new.
	menu add: 'new...' target: self selector: #editNewSound.
	menu addLine.
	AbstractSound soundNames do:
		[:name |
		menu add: name
			target: self selector: #editSoundNamed:
			argument: name].
	menu popUpEvent: evt in: self world
]

{ #category : #editing }
EnvelopeEditorMorph >> clickOn: env evt: anEvent from: aLine [
	self editEnvelope: env
]

{ #category : #editing }
EnvelopeEditorMorph >> clickOnLine: arg1 evt: arg2 envelope: arg3 [
	"Reorder the arguments for existing event handlers"
	(arg3 isMorph and:[arg3 eventHandler notNil]) ifTrue:[arg3 eventHandler fixReversedValueMessages].
	^self clickOn: arg1 evt: arg2 from: arg3
]

{ #category : #construction }
EnvelopeEditorMorph >> colorForEnvelope: env [
	| name index |
	name := env name.
	index := #('volume' 'modulation' 'pitch' 'ratio') indexOf: name
				ifAbsent: [5].
	^ Color perform: (#(red green blue magenta black) at: index)
]

{ #category : #editing }
EnvelopeEditorMorph >> constrain: xVal adjacentTo: ix in: points [
	"Return xVal, restricted between points adjacent to vertX"
	| newVal |
	newVal := xVal.
	ix > 1 ifTrue: [newVal := newVal max: (points at: ix-1) x].
	ix < points size ifTrue: [newVal := newVal min: (points at: ix+1) x].
	^ newVal
]

{ #category : #construction }
EnvelopeEditorMorph >> curveChoices [
	| extant others |
	extant := sound envelopes collect: [:env | env name].
	others := #('volume' 'modulation' 'pitch' 'random pitch:' 'ratio')
		reject: [:x | (extant includes: x) | ((x = 'pitch') & (extant includes: 'random pitch:')) | ((x = 'random pitch:') & (extant includes: 'pitch')) ].
	^ (extant collect: [:name | 'edit ' , name])
	, (others collect: [:name | 'add ' , name])
	, (sound envelopes size > 1
		ifTrue: [Array with: 'remove ' , envelope name]
		ifFalse: [Array new])
]

{ #category : #editing }
EnvelopeEditorMorph >> deletePoint: ix [ 
	"If the point is a limit point, return false,
	otherwise, delete the point at ix, and return true."

	(limits includes: ix) ifTrue: [^false].
	1 to: limits size
		do: 
			[:i | 
			"Decrease limit indices beyond the deletion"

			(limits at: i) > ix ifTrue: [limits at: i put: (limits at: i) - 1]].
	envelope 
		setPoints: (envelope points 
				copyReplaceFrom: ix
				to: ix
				with: Array new)
		loopStart: (limits first)
		loopEnd: (limits second).
	^true
]

{ #category : #initialization }
EnvelopeEditorMorph >> editEnvelope: env [
	envelope := env.
	limits := Array with: envelope loopStartIndex
				with: envelope loopEndIndex
				with: envelope points size.
	limitXs := limits collect: [:i | (envelope points at: i) x].
	self buildView
]

{ #category : #menu }
EnvelopeEditorMorph >> editNewSound [
	| known i |
	known := AbstractSound soundNames.
	i := 0.
	[soundName := 'unnamed' , i printString.
	known includes: soundName]
		whileTrue: [i := 1+1].
	soundName := soundName.
	self editSound: FMSound default copy
]

{ #category : #initialization }
EnvelopeEditorMorph >> editSound: aSound [

	| p |
	(aSound respondsTo: #envelopes)
		ifFalse: [
			self inform: 'You selected a ' translated, aSound class name, '.', String cr,
				'I can''t handle these kinds of sounds.' translated.
			^self ].
	sound := aSound.
	sound envelopes isEmpty ifTrue: [
		"provide a default volume envelope"
		p := OrderedCollection new.
		p add: 0@0.0; add: 10@1.0; add: 100@1.0; add: 120@0.0.
		sound addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3)].

	self editEnvelope: sound envelopes first.
	keyboard soundPrototype: sound.

]

{ #category : #menu }
EnvelopeEditorMorph >> editSoundNamed: name [

	name = 'new...' ifTrue: [^ self editNewSound].
	soundName := name.
	self editSound: (AbstractSound soundNamed: soundName) copy
]

{ #category : #geometry }
EnvelopeEditorMorph >> extent: newExtent [
	super extent: (newExtent max: (self maxTime//10*3+50 max: 355) @ 284).
	self buildView
]

{ #category : #construction }
EnvelopeEditorMorph >> handleOffset: handle [
	"This is the offset from position to the bottom vertex"
	^ (handle width//2+1) @ handle height

]

{ #category : #initialization }
EnvelopeEditorMorph >> initOnSound: aSound title: title [
	sound := aSound.
	soundName := title.
	self initialize.

]

{ #category : #initialization }
EnvelopeEditorMorph >> initialize [
	super initialize.
	prevMouseDown := false.
	showAllEnvelopes := true.
	soundName ifNil: [soundName := 'test'].
	self editSound: (sound ifNil: [FMSound brass1 copy]).
	sound duration: 0.25.
	denominator := 7.
	self extent: 10@10.  "ie the minimum"

]

{ #category : #editing }
EnvelopeEditorMorph >> insertPointAfter: ix [ 
	"If there is not enough roon (in x) then return false.
	Otherwise insert a point between ix and ix+1 and return true."

	| points pt |
	points := envelope points.
	(points at: ix + 1) x - (points at: ix) x < 20 ifTrue: [^false].
	pt := ((points at: ix + 1) + (points at: ix)) // 2.
	1 to: limits size
		do: 
			[:i | 
			"Increase limit indices beyond the insertion"

			(limits at: i) > ix ifTrue: [limits at: i put: (limits at: i) + 1]].
	envelope 
		setPoints: (points 
				copyReplaceFrom: ix + 1
				to: ix
				with: (Array with: pt))
		loopStart: (limits first)
		loopEnd: (limits second).
	^true
]

{ #category : #editing }
EnvelopeEditorMorph >> limitHandleMove: index event: evt from: handle [
	"index is the handle index = 1, 2 or 3"
	| ix p ms x points limIx |
	ix := limits at: index.  "index of corresponding vertex"
	p := evt cursorPoint adhereTo: graphArea bounds.
	ms := self msFromX: p x + (self handleOffset: handle) x.

	"Constrain move to adjacent points on ALL envelopes"
	sound envelopes do:
		[:env | limIx := env perform:
			(#(loopStartIndex loopEndIndex decayEndIndex) at: index).
		ms := self constrain: ms adjacentTo: limIx in: env points].

	"Update the handle, the vertex and the line being edited"
	x := self xFromMs: ms.
	handle position: (x @ graphArea top) - (self handleOffset: handle).
	line verticesAt: ix put: x @ (line vertices at: ix) y.

	sound envelopes do:
		[:env | limIx := env perform:
			(#(loopStartIndex loopEndIndex decayEndIndex) at: index).
		points := env points.
		points at: limIx put: ms @ (points at: limIx) y.
		env setPoints: points loopStart: env loopStartIndex loopEnd: env loopEndIndex].
]

{ #category : #editing }
EnvelopeEditorMorph >> limitHandleMoveEvent: arg1 from: arg2 index: arg3 [
	"Reorder the arguments for existing event handlers"
	(arg3 isMorph and:[arg3 eventHandler notNil]) ifTrue:[arg3 eventHandler fixReversedValueMessages].
	^self limitHandleMove: arg1 event: arg2 from: arg3
]

{ #category : #scaling }
EnvelopeEditorMorph >> maxTime [
	^ (envelope points at: limits last) x + 100
]

{ #category : #scaling }
EnvelopeEditorMorph >> msFromX: x [
	^ (x - graphArea left)//pixPerTick*10
]

{ #category : #playing }
EnvelopeEditorMorph >> playNothing [

]

{ #category : #menu }
EnvelopeEditorMorph >> readFileNamed: fileName [
	| snd |
	snd := Compiler evaluate:
		(FileStream readOnlyFileNamed: fileName) contentsOfEntireFile.
	soundName := fileName copyFrom: 1 to: fileName size-4. "---.fmp"
	self editSound: snd
]

{ #category : #menu }
EnvelopeEditorMorph >> readFromDisk: evt [
	| menu |
	menu := MenuMorph new.
	(FileSystem workingDirectory files collect:[:e | (e basename endsWith: '.fmp') ]) do:
		[:fileName |
		menu add: fileName
			target: self selector: #readFileNamed:
			argument: fileName].
	menu popUpEvent: evt in: self world
]

{ #category : #menu }
EnvelopeEditorMorph >> removeEnvelope [
	(self confirm: 'Really remove ' translated, envelope name , '?')
		ifFalse: [^ self].
	sound removeEnvelope: envelope.
	self editEnvelope: sound envelopes first.
]

{ #category : #menu }
EnvelopeEditorMorph >> saveLibToDisk: evt [
	"Save the library to disk"

	| newName f snd |
	newName := UIManager default request: 'Please confirm name for library...' translated
						initialAnswer: 'MySounds'.
	newName isEmptyOrNil ifTrue: [^ self].
	f := FileStream newFileNamed: newName , '.fml'.
	AbstractSound soundNames do:
		[:name | snd := AbstractSound soundNamed: name.
		"snd isStorable" true ifTrue: [f nextChunkPut: 'AbstractSound soundNamed: ' , name , ' put: ' , snd storeString; cr; cr]
			ifFalse: [self inform: name , ' is not currently storable']].
	f close
]

{ #category : #menu }
EnvelopeEditorMorph >> saveSound: evt [
	| newName |
	newName := UIManager default request: 'Please confirm name for save...' translated
						initialAnswer: soundName.
	newName isEmptyOrNil ifTrue: [^ self].
	AbstractSound soundNamed: newName put: sound.
	soundName := newName.
]

{ #category : #menu }
EnvelopeEditorMorph >> saveToDisk: evt [
	| newName f |
	newName := UIManager default request: 'Please confirm name for save...' translated
						initialAnswer: soundName.
	newName isEmptyOrNil ifTrue: [^ self].
	f := FileStream newFileNamed: newName , '.fmp'.
	sound storeOn: f.
	f close
]

{ #category : #menu }
EnvelopeEditorMorph >> setDenominator: denom [
	denominator := denom.
	self buildView
]

{ #category : #initialization }
EnvelopeEditorMorph >> soundBeingEdited [

	^ sound
]

{ #category : #construction }
EnvelopeEditorMorph >> soundChoices [
	^ #('new...') , AbstractSound soundNames
]

{ #category : #'stepping and presenter' }
EnvelopeEditorMorph >> step [
	| mouseDown hand |
	hand := self world firstHand.
	(bounds containsPoint: hand position) ifFalse: [^ self].

	mouseDown := hand lastEvent redButtonPressed.
	mouseDown not & prevMouseDown ifTrue:
		["Mouse just went up"
		limitXs = (limits collect: [:i | (envelope points at: i) x]) ifFalse:
			["Redisplay after changing limits"
			self editEnvelope: envelope]].
	prevMouseDown := mouseDown
]

{ #category : #testing }
EnvelopeEditorMorph >> stepTime [
	^ 100
]

{ #category : #scaling }
EnvelopeEditorMorph >> valueFromY: y [
	"The convention is that envelope values are between 0.0 and 1.0"
	| value |
	value := (graphArea bottom - y) asFloat / (graphArea height).
	envelope updateSelector = #ratio: ifTrue:
		["Ratio gets gridded by denominator"
		^ (value * envelope scale * denominator) rounded asFloat / denominator / envelope scale].
	^ value
]

{ #category : #rounding }
EnvelopeEditorMorph >> wantsRoundedCorners [
	^ UITheme currentSettings preferRoundCorner or: [super wantsRoundedCorners]
]

{ #category : #scaling }
EnvelopeEditorMorph >> xFromMs: ms [
	^ graphArea left + (ms//10*pixPerTick)
]

{ #category : #scaling }
EnvelopeEditorMorph >> yFromValue: val [
	"The convention is that envelope values are between 0.0 and 1.0"
	^ graphArea bottom - (val* (graphArea height))
]
