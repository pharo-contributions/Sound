"
A PianoRollScoreMorph displays a score such as a MIDIScore, and will scroll through it tracking the progress of a ScorePlayerMorph (from which it is usually spawned).

timeScale is in pixels per score tick.

Currently the ambient track (for synchronizing thumbnails, eg) is treated specially here and in the score.  This should be cleaned up by adding a trackType or something like it in the score.
"
Class {
	#name : #PianoRollScoreMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'scorePlayer',
		'score',
		'colorForTrack',
		'lowestNote',
		'leftEdgeTime',
		'timeScale',
		'indexInTrack',
		'lastUpdateTick',
		'lastMutedState',
		'cursor',
		'selection',
		'timeSignature',
		'beatsPerMeasure',
		'notePerBeat',
		'showMeasureLines',
		'showBeatLines',
		'soundsPlaying',
		'soundsPlayingMorph',
		'movieClipPlayer'
	],
	#classVars : [
		'NotePasteBuffer'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #layout }
PianoRollScoreMorph >> acceptDroppingMorph: aMorph event: evt [
	"In addition to placing this morph in the pianoRoll, add a corresponding
	event to the score so that it will always appear when played, in addition
	to possibly triggering other actions"

	aMorph justDroppedIntoPianoRoll: self event: evt.
	super acceptDroppingMorph: aMorph event: evt.


]

{ #category : #menu }
PianoRollScoreMorph >> addCustomMenuItems: aMenu hand: aHandMorph [

	super addCustomMenuItems: aMenu hand: aHandMorph.
	aMenu add: 'expand time' translated action: #expandTime.
	aMenu add: 'contract time' translated action: #contractTime.
	aMenu addLine.
	aMenu add: 'add movie clip player' translated action: #addMovieClipPlayer.
	(self valueOfProperty: #dragNDropEnabled) == true
		ifTrue: [aMenu add: 'close drag and drop' translated action: #disableDragNDrop]
		ifFalse: [aMenu add: 'open drag and drop' translated action: #enableDragNDrop].

]

{ #category : #menu }
PianoRollScoreMorph >> addKeyboard [

	(KeyboardMorphForInput new pianoRoll: self) openInWorld
]

{ #category : #drawing }
PianoRollScoreMorph >> addNotes [
	"Recompute the set of morphs that should be visible at the current scroll position."

	| visibleMorphs rightEdge topEdge rightEdgeTime |
	visibleMorphs := OrderedCollection new: 500.
	rightEdge := self right - borderWidth.
	rightEdgeTime := self timeForX: rightEdge.
	topEdge := self top + borderWidth + 1.

	"Add ambient morphs first (they will be front-most)"
	score eventMorphsWithTimeDo:
		[:m :t | m addMorphsTo: visibleMorphs pianoRoll: self eventTime: t
					betweenTime: leftEdgeTime and: rightEdgeTime].

	"Then add note morphs"
	score tracks withIndexDo:
		[:track :trackIndex | | done n i nRight nTop nLeft trackColor |
		trackColor := colorForTrack at: trackIndex.
		i := indexInTrack at: trackIndex.
		done := scorePlayer mutedForTrack: trackIndex.
		[done | (i > track size)] whileFalse: [
			n := track at: i.
			(n isNoteEvent and: [n midiKey >= lowestNote]) ifTrue: [
				n time > rightEdgeTime
					ifTrue: [done := true]
					ifFalse: [
						nLeft := self xForTime: n time.
						nTop := (self yForMidiKey: n midiKey) - 1.
						nTop > topEdge ifTrue: [
							nRight := nLeft + (n duration * timeScale) truncated - 1.
							visibleMorphs add:
								((PianoRollNoteMorph
									newBounds: (nLeft@nTop corner: nRight@(nTop + 3))
									color: trackColor)
									trackIndex: trackIndex indexInTrack: i)]]].
			i := i + 1].
			(selection notNil
				and: [trackIndex = selection first
				and: [i >= selection second and: [(indexInTrack at: trackIndex) <= selection third]]])
				ifTrue: [visibleMorphs do:
						[:vm | (vm isKindOf: PianoRollNoteMorph) ifTrue: [vm selectFrom: selection]]]].

	"Add the cursor morph in front of all notes; height and position are set later."
	cursor ifNil: [cursor := Morph newBounds: (self topLeft extent: 1@1) color: Color red].
	visibleMorphs addFirst: cursor.

	self changed.
	self removeAllMorphs.
	self addAllMorphs: visibleMorphs.

]

{ #category : #editing }
PianoRollScoreMorph >> appendEvent: noteEvent fullDuration: fullDuration [ 

	| sel x |
	score appendEvent: noteEvent fullDuration: fullDuration at: (sel := self selection).
	noteEvent midiKey = -1 ifFalse:  "Unless it is a rest..."
		["Advance the selection to the note just entered"
		selection := Array with: sel first with: sel third + 1 with: sel third + 1].

	"This is all horribly inefficient..."
	scorePlayer updateDuration.
	(x := self xForTime: noteEvent endTime) > (self right - 30) ifTrue:
		[self autoScrollForX: x + (30 + self width // 4)].
	self updateLowestNote.
	self rebuildFromScore
]

{ #category : #scrolling }
PianoRollScoreMorph >> autoScrollForX: x [
	"Scroll by the amount x lies outside of my innerBounds.  Return true if this happens."

	| d ticks |
	((d := x - self innerBounds right) > 0
		or: [(d := x - self innerBounds left) < 0])
		ifTrue: [ticks := (self timeForX: self bounds center x + d+1)
						min: score durationInTicks max: 0.
				self moveCursorToTime: ticks.
				scorePlayer ticksSinceStart: ticks.
				^ true].
	^ false

]

{ #category : #menu }
PianoRollScoreMorph >> beatLinesOnOff [

	showBeatLines := showBeatLines not.
	self changed
]

{ #category : #accessing }
PianoRollScoreMorph >> beatsPerMeasure: n [

	^ self timeSignature: n over: notePerBeat
]

{ #category : #geometry }
PianoRollScoreMorph >> contractTime [

	timeScale := timeScale / 1.5.
	self rebuildFromScore.

]

{ #category : #editing }
PianoRollScoreMorph >> copySelection [
	selection isNil ifTrue: [^self].
	NotePasteBuffer := (score tracks at: selection first) 
				copyFrom: selection second
				to: selection third
]

{ #category : #editing }
PianoRollScoreMorph >> cutSelection [
	selection isNil ifTrue: [^self].
	self copySelection.
	self deleteSelection
]

{ #category : #initialization }
PianoRollScoreMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 1
]

{ #category : #initialization }
PianoRollScoreMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color white
]

{ #category : #editing }
PianoRollScoreMorph >> deleteSelection [
	| selMorphs priorEvent x |
	(selection isNil or: [selection second = 0]) ifTrue: [^self].
	score cutSelection: selection.
	selection second > 1 
		ifTrue: 
			[selection at: 2 put: selection second - 1.
			selection at: 3 put: selection second.
			priorEvent := (score tracks at: selection first) at: selection second.
			(x := self xForTime: priorEvent time) < (self left + 30) 
				ifTrue: [self autoScrollForX: x - ((30 + self width) // 4)]]
		ifFalse: [selection := nil].
	scorePlayer updateDuration.
	self rebuildFromScore.
	selMorphs := self 
				submorphsSatisfying: [:m | (m isKindOf: PianoRollNoteMorph) and: [m selected]].
	selMorphs isEmpty ifFalse: [(selMorphs last noteOfDuration: 0.3) play]
]

{ #category : #drawing }
PianoRollScoreMorph >> drawMeasureLinesOn: aCanvas [

	| ticksPerMeas x measureLineColor inner |
	showBeatLines ifNil: [showBeatLines := false].
	showMeasureLines ifNil: [showMeasureLines := true].
	notePerBeat ifNil: [self timeSignature: 4 over: 4].
	showBeatLines ifTrue:
		[measureLineColor := Color gray: 0.8.
		ticksPerMeas := score ticksPerQuarterNote.
		inner := self innerBounds.
		(leftEdgeTime + ticksPerMeas truncateTo: ticksPerMeas)
			to: ((self timeForX: self right - borderWidth) truncateTo: ticksPerMeas)
			by: ticksPerMeas
			do: [:tickTime | x := self xForTime: tickTime.
				aCanvas fillRectangle: (x @ inner top extent: 1 @ inner height)
					color: measureLineColor]].

	showMeasureLines ifTrue:
		[measureLineColor := Color gray: 0.7.
		ticksPerMeas := beatsPerMeasure*score ticksPerQuarterNote*4//notePerBeat.
		inner := self innerBounds.
		(leftEdgeTime + ticksPerMeas truncateTo: ticksPerMeas)
			to: ((self timeForX: self right - borderWidth) truncateTo: ticksPerMeas)
			by: ticksPerMeas
			do: [:tickTime | x := self xForTime: tickTime.
				aCanvas fillRectangle: (x @ inner top extent: 1 @ inner height)
						color: (tickTime = 0 ifTrue: [Color black] ifFalse: [measureLineColor])]].

]

{ #category : #drawing }
PianoRollScoreMorph >> drawOn: aCanvas [

	super drawOn: aCanvas.
	self drawStaffOn: aCanvas.

]

{ #category : #drawing }
PianoRollScoreMorph >> drawStaffOn: aCanvas [

	| blackKeyColor l r topEdge y |
	self drawMeasureLinesOn: aCanvas.

	blackKeyColor := Color gray: 0.5.
	l := self left + borderWidth.
	r := self right - borderWidth.
	topEdge := self top + borderWidth + 3.
	lowestNote to: 127 do: [:k |
		y := self yForMidiKey: k.
		y <= topEdge ifTrue: [^ self].  "over the top!"
		(self isBlackKey: k) ifTrue: [
			aCanvas
				fillRectangle: (l@y corner: r@(y + 1))
				color: blackKeyColor]].

]

{ #category : #geometry }
PianoRollScoreMorph >> expandTime [

	timeScale := timeScale * 1.5.
	self rebuildFromScore.

]

{ #category : #geometry }
PianoRollScoreMorph >> extent: aPoint [
	"Force rebuild when re-sized."

	super extent: aPoint. 
	score ifNotNil: [self updateLowestNote].
	self rebuildFromScore.

]

{ #category : #layout }
PianoRollScoreMorph >> fullBounds [
	"Overridden to clip submorph hit detection to my bounds."

	fullBounds ifNil: [fullBounds := bounds].
	^ bounds

]

{ #category : #scrolling }
PianoRollScoreMorph >> goToTime: scoreTime [

	| track trackSize index newLeftEdgeTime |
	newLeftEdgeTime := scoreTime asInteger.
	newLeftEdgeTime < leftEdgeTime
		ifTrue: [indexInTrack := Array new: score tracks size+1 withAll: 1].
	leftEdgeTime := newLeftEdgeTime.
	1 to: score tracks size do: [:trackIndex |
		track := score tracks at: trackIndex.
		index := indexInTrack at: trackIndex.
		trackSize := track size.
		[(index < trackSize) and:
		 [(track at: index) endTime < leftEdgeTime]]
			whileTrue: [index := index + 1].
		indexInTrack at: trackIndex put: index].
	self addNotes.

]

{ #category : #'event handling' }
PianoRollScoreMorph >> handlesMouseDown: evt [

	^ true
]

{ #category : #initialization }
PianoRollScoreMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	
	self extent: 400 @ 300.
	showMeasureLines := true.
	showBeatLines := false.
	self timeSignature: 4 over: 4.
	self clipSubmorphs: true
]

{ #category : #editing }
PianoRollScoreMorph >> insertSelection [
	self selection isNil ifTrue: [^self].
	score insertEvents: NotePasteBuffer at: self selection.
	scorePlayer updateDuration.
	self rebuildFromScore
]

{ #category : #editing }
PianoRollScoreMorph >> insertTransposed [
	| delta transposedNotes list |
	list := (12 to: -12 by: -1) collect: [:i | i printString].
	delta := UIManager default chooseFrom: list values: list title: 'Offset' translated.
 	delta ifNil: [^self].
	transposedNotes := NotePasteBuffer 
				collect: [:note | note copy midiKey: note midiKey + delta].
	selection isNil ifTrue: [^self].
	score insertEvents: transposedNotes at: self selection.
	scorePlayer updateDuration.
	self rebuildFromScore
]

{ #category : #menu }
PianoRollScoreMorph >> invokeScoreMenu: evt [
	"Invoke the score's edit menu."

	| menu subMenu |
	menu := MenuMorph new defaultTarget: self.
	menu addList:
		{{'cut' translated.		#cutSelection}.
		{'copy' translated.		#copySelection}.
		{'paste' translated.		#insertSelection}.
		{'paste...' translated.		#insertTransposed}}.
	menu addLine.
	menu addList:
		{{'legato' translated.		#selectionBeLegato}.
		{'staccato' translated.	#selectionBeStaccato}.
		{'normal' translated.		#selectionBeNormal}}.
	menu addLine.
	menu addList:
		{{'expand time' translated.		#expandTime}.
		{'contract time' translated.		#contractTime}}.
	menu addLine.
	subMenu := MenuMorph new defaultTarget: self.
		(2 to: 12) do: [:i | subMenu add: i printString selector: #beatsPerMeasure: argument: i].
		menu add: 'time   ' translated, beatsPerMeasure printString subMenu: subMenu.
	subMenu := MenuMorph new defaultTarget: self.
		#(2 4 8) do: [:i | subMenu add: i printString selector: #notePerBeat: argument: i].
		menu add: 'sig     ' translated, notePerBeat printString subMenu: subMenu.
	menu addLine.
	showMeasureLines
		ifTrue: [menu add: 'hide measure lines' translated action: #measureLinesOnOff]
		ifFalse: [menu add: 'show measure lines' translated action: #measureLinesOnOff].
	showBeatLines
		ifTrue: [menu add: 'hide beat lines' translated action: #beatLinesOnOff]
		ifFalse: [menu add: 'show beat lines' translated action: #beatLinesOnOff].

	menu addLine.
	menu add: 'add keyboard' translated action: #addKeyboard.

	menu popUpEvent: evt in: self world.

]

{ #category : #drawing }
PianoRollScoreMorph >> isBlackKey: midiKey [
	"Answer true if the given MIDI key corresponds to a black key on the piano keyboard."

	| note |
	note := midiKey \\ 12.
	note = 1 ifTrue: [^ true].
	note = 3 ifTrue: [^ true].
	note = 6 ifTrue: [^ true].
	note = 8 ifTrue: [^ true].
	note = 10 ifTrue: [^ true].
	^ false

]

{ #category : #layout }
PianoRollScoreMorph >> layoutChanged [
	"Override this to avoid propagating 'layoutChanged' when just adding/removing note objects."

	fullBounds = bounds ifTrue: [^ self].
	super layoutChanged.

]

{ #category : #menu }
PianoRollScoreMorph >> measureLinesOnOff [

	showMeasureLines := showMeasureLines not.
	self changed
]

{ #category : #geometry }
PianoRollScoreMorph >> midiKeyForY: y [

	^ lowestNote - ((y - (bounds bottom - borderWidth - 4)) // 3)

]

{ #category : #'event handling' }
PianoRollScoreMorph >> mouseDown: evt [

	| noteMorphs chordRect |
	(self notesInRect: ((evt cursorPoint extent: 1@0) expandBy: 2@30)) isEmpty
		ifTrue: ["If not near a note, then put up score edit menu"
				^ self invokeScoreMenu: evt].

	"Clicked near (but not on) a note, so play all notes at the cursor time"
	noteMorphs := self notesInRect: ((evt cursorPoint extent: 1@0) expandBy: 0@self height).
	chordRect := (self innerBounds withLeft: evt cursorPoint x) withWidth: 1.
	soundsPlayingMorph := Morph newBounds: chordRect color: Color green.
	self addMorphBack: soundsPlayingMorph.
	
	soundsPlaying := IdentityDictionary new.
	noteMorphs do:
		[:m | | sound | sound := m soundOfDuration: 999.0.
		soundsPlaying at: m put: sound.
		SoundPlayer resumePlaying: sound quickStart: false].


]

{ #category : #'event handling' }
PianoRollScoreMorph >> mouseMove: evt [

	| noteMorphs chordRect |
	soundsPlaying ifNil: [^ self].
	self autoScrollForX: evt cursorPoint x.

	"Play all notes at the cursor time"
	noteMorphs := self notesInRect: ((evt cursorPoint extent: 1@0) expandBy: 0@self height).
	chordRect := (self innerBounds withLeft: evt cursorPoint x) withWidth: 1.
	soundsPlayingMorph delete.
	soundsPlayingMorph := Morph newBounds: chordRect color: Color green.
	self addMorphBack: soundsPlayingMorph.
	
	noteMorphs do:
		[:m | | sound |  "Add any new sounds"
		(soundsPlaying includesKey: m)
			ifFalse: [sound := m soundOfDuration: 999.0.
					soundsPlaying at: m put: sound.
					SoundPlayer resumePlaying: sound quickStart: false]].
	soundsPlaying keys do:
		[:m |  "Remove any sounds no longer in selection."
		(noteMorphs includes: m)
			ifFalse: [(soundsPlaying at: m) stopGracefully.
					soundsPlaying removeKey: m]].


]

{ #category : #'event handling' }
PianoRollScoreMorph >> mouseUp: evt [

	soundsPlayingMorph ifNotNil: [soundsPlayingMorph delete].
	soundsPlaying ifNotNil: [soundsPlaying do: [:s | s stopGracefully]].
	soundsPlayingMorph := soundsPlaying := nil

]

{ #category : #scrolling }
PianoRollScoreMorph >> moveCursorToTime: scoreTime [

	| cursorOffset desiredCursorHeight |
	scorePlayer isPlaying
		ifTrue:
			[cursorOffset := ((scoreTime - leftEdgeTime) asFloat * timeScale) asInteger.
			(cursorOffset < 0
				or: [cursorOffset > (self width-20)])
				ifTrue:
				[self goToTime: scoreTime - (20/timeScale).
				cursorOffset := ((scoreTime - leftEdgeTime) asFloat * timeScale) asInteger]]
		ifFalse:
			[self goToTime: (scoreTime - (self width//2 / timeScale)
							max: (self width//10 / timeScale) negated).
			cursorOffset := ((scoreTime - leftEdgeTime) asFloat * timeScale) asInteger].

	cursor position: (self left + borderWidth + cursorOffset)@(self top + borderWidth).
	desiredCursorHeight := self height.
	cursor height ~= desiredCursorHeight ifTrue: [cursor extent: 1@desiredCursorHeight].

]

{ #category : #accessing }
PianoRollScoreMorph >> movieClipPlayer [

	^ movieClipPlayer
]

{ #category : #accessing }
PianoRollScoreMorph >> movieClipPlayer: moviePlayer [

	movieClipPlayer := moviePlayer

]

{ #category : #accessing }
PianoRollScoreMorph >> notePerBeat: n [

	^ self timeSignature: beatsPerMeasure over: n
]

{ #category : #scrolling }
PianoRollScoreMorph >> notesInRect: timeSlice [

	^ self submorphsSatisfying:
		[:m | (timeSlice intersects: m bounds)
				and: [m isKindOf: PianoRollNoteMorph]]
]

{ #category : #initialization }
PianoRollScoreMorph >> on: aScorePlayer [

	scorePlayer := aScorePlayer.
	score := aScorePlayer score.
	colorForTrack := Color wheel: score tracks size.
	leftEdgeTime := 0.
	timeScale := 0.1.
	indexInTrack := Array new: score tracks size withAll: 1.
	lastUpdateTick := -1.

	self updateLowestNote

]

{ #category : #drawing }
PianoRollScoreMorph >> rebuildFromScore [
	"Rebuild my submorphs from the score. This method should be invoked after changing the time scale, the color or visibility of a track, the extent of this morph, etc."

	score ifNil: [^ self].
	self addNotes.

]

{ #category : #private }
PianoRollScoreMorph >> removedMorph: aMorph [
	| trackSize |
	trackSize := score ambientTrack size.
	score removeAmbientEventWithMorph: aMorph.
	trackSize = score ambientTrack size ifFalse:
		["Update duration if we removed an event"
		scorePlayer updateDuration].
	^super removedMorph: aMorph
]

{ #category : #accessing }
PianoRollScoreMorph >> score [

	^ score
]

{ #category : #accessing }
PianoRollScoreMorph >> scorePlayer [

	^ scorePlayer
]

{ #category : #accessing }
PianoRollScoreMorph >> selection [
	"Returns an array of 3 elements:
		trackIndex
		indexInTrack of first note
		indexInTrack of last note"

	| trackIndex track |
	selection ifNil:  "If no selection, return last event of 1st non-muted track (or nil)"
		[trackIndex := (1 to: score tracks size)
			detect: [:i | (scorePlayer mutedForTrack: i) not] ifNone: [^ nil].
		track := score tracks at: trackIndex.
		^ Array with: trackIndex with: track size with: track size].
	(scorePlayer mutedForTrack: selection first)
		ifTrue: [selection := nil.  ^ self selection].
	^ selection
]

{ #category : #accessing }
PianoRollScoreMorph >> selection: anArray [

	selection := anArray
]

{ #category : #'stepping and presenter' }
PianoRollScoreMorph >> step [

	| t |
	score ifNil: [^ self].

	lastMutedState ~= scorePlayer mutedState ifTrue: [
		self rebuildFromScore.
		lastMutedState := scorePlayer mutedState copy].

	t := scorePlayer ticksSinceStart.
	t = lastUpdateTick ifFalse: [
		self moveCursorToTime: t.
		lastUpdateTick := t].

]

{ #category : #testing }
PianoRollScoreMorph >> stepTime [

	^ 0

]

{ #category : #geometry }
PianoRollScoreMorph >> tickTimeAtCursor [
	cursor ifNil: [^ 0].
	^ self timeForX: cursor left
]

{ #category : #geometry }
PianoRollScoreMorph >> timeForX: aNumber [

	^ ((aNumber - bounds left - borderWidth) asFloat / timeScale + leftEdgeTime) asInteger
]

{ #category : #accessing }
PianoRollScoreMorph >> timeScale [

	^ timeScale  "in pixels per tick"
]

{ #category : #accessing }
PianoRollScoreMorph >> timeSignature: num over: denom [

	beatsPerMeasure := num.
	notePerBeat := denom.  "a number like 2, 4, 8"
	self changed
]

{ #category : #initialization }
PianoRollScoreMorph >> updateLowestNote [
	"find the actual lowest note in the score"

	
	lowestNote := 128 - (self innerBounds height // 3).
	score tracks do: [:track | | n |
		1 to: track size do: [:i |
			n := track at: i.
			(n isNoteEvent and: [n midiKey < lowestNote])
				ifTrue: [lowestNote := n midiKey - 4]]].

]

{ #category : #geometry }
PianoRollScoreMorph >> xForTime: aNumber [

	^ ((aNumber - leftEdgeTime) asFloat * timeScale) asInteger + bounds left + borderWidth

]

{ #category : #geometry }
PianoRollScoreMorph >> yForMidiKey: midiKey [

	^ (bounds bottom - borderWidth - 4) - (3 * (midiKey - lowestNote))

]
