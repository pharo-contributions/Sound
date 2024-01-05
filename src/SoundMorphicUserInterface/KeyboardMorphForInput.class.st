"
This class adds state and controls to the basic PianoKeyboardMorph so that notes of reliable duration can be keyed into a score without the need for a real keyboard.

To try this out, execute...

	| n score | n := 3.
	score := (MIDIScore new tracks: ((1 to: n) collect: [:i | Array new]);
		trackInfo: ((1 to: n) collect: [:i | 'Instrument' , i printString]);
		tempoMap: nil; ticksPerQuarterNote: 96).
	ScorePlayerMorph openOn: score title: 'empty score'

Then open a pianoRoll and, from that, open a keyboard.  The rule is that the keyboard will append after the current selection.  If the current selection is muted or nil, then input will go to the end of the first non-muted track.
"
Class {
	#name : 'KeyboardMorphForInput',
	#superclass : 'PianoKeyboardMorph',
	#instVars : [
		'pianoRoll',
		'duration',
		'durationModifier',
		'articulation',
		'buildingChord',
		'insertMode',
		'prevSelection',
		'startOfNextNote'
	],
	#category : 'SoundMorphicUserInterface',
	#package : 'SoundMorphicUserInterface'
}

{ #category : 'initialization' }
KeyboardMorphForInput >> addRecordingControls [
	| button switch playRow durRow articRow modRow |

	"Add chord, rest and delete buttons"
	playRow := AlignmentMorph newRow.
	playRow color: color; borderWidth: 0; layoutInset: 0.
	playRow hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	playRow addMorphBack: (switch label: 'chord' translated; actionSelector: #buildChord:).
	button := SimpleButtonMorph new target: self;
		borderColor: #raised; borderWidth: 2; color: color.
	playRow addMorphBack: (button label: '          rest          ' translated; actionSelector: #emitRest).
	button := SimpleButtonMorph new target: self;
		borderColor: #raised; borderWidth: 2; color: color.
	playRow addMorphBack: (button label: 'del' translated; actionSelector: #deleteNotes).
	self addMorph: playRow.
	playRow align: playRow fullBounds topCenter
			with: self fullBounds bottomCenter.

	"Add note duration buttons"
	durRow := AlignmentMorph newRow.
	durRow color: color; borderWidth: 0; layoutInset: 0.
	durRow hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	durRow addMorphBack: (switch label: 'whole' translated;
				actionSelector: #duration:onOff:; arguments: #(1)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	durRow addMorphBack: (switch label: 'half' translated;
				actionSelector: #duration:onOff:; arguments: #(2)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	durRow addMorphBack: (switch label: 'quarter' translated;
				actionSelector: #duration:onOff:; arguments: #(4)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	durRow addMorphBack: (switch label: 'eighth' translated;
				actionSelector: #duration:onOff:; arguments: #(8)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	durRow addMorphBack: (switch label: 'sixteenth' translated;
				actionSelector: #duration:onOff:; arguments: #(16)).
	self addMorph: durRow.
	durRow align: durRow fullBounds topCenter
			with: playRow fullBounds bottomCenter.

	"Add note duration modifier buttons"
	modRow := AlignmentMorph newRow.
	modRow color: color; borderWidth: 0; layoutInset: 0.
	modRow hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	modRow addMorphBack: (switch label: 'dotted' translated;
				actionSelector: #durMod:onOff:; arguments: #(dotted)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	modRow addMorphBack: (switch label: 'normal' translated;
				actionSelector: #durMod:onOff:; arguments: #(normal)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	modRow addMorphBack: (switch label: 'triplets' translated;
				actionSelector: #durMod:onOff:; arguments: #(triplets)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	modRow addMorphBack: (switch label: 'quints' translated;
				actionSelector: #durMod:onOff:; arguments: #(quints)).
	self addMorph: modRow.
	modRow align: modRow fullBounds topCenter
			with: durRow fullBounds bottomCenter.

	"Add articulation buttons"
	articRow := AlignmentMorph newRow.
	articRow color: color; borderWidth: 0; layoutInset: 0.
	articRow hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	articRow addMorphBack: (switch label: 'legato' translated;
				actionSelector: #articulation:onOff:; arguments: #(legato)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	articRow addMorphBack: (switch label: 'normal' translated;
				actionSelector: #articulation:onOff:; arguments: #(normal)).
	switch := SimpleSwitchMorph new target: self; borderWidth: 2;
		offColor: color; onColor: (Color r: 1.0 g: 0.6 b: 0.6); setSwitchState: false.
	articRow addMorphBack: (switch label: 'staccato' translated;
				actionSelector: #articulation:onOff:; arguments: #(staccato)).
	self addMorph: articRow.
	articRow align: articRow fullBounds topCenter
			with: modRow fullBounds bottomCenter.

	self bounds: (self fullBounds expandBy: (0@0 extent: 0@borderWidth))

]

{ #category : 'note controls' }
KeyboardMorphForInput >> articulation: artic onOff: ignored [    "artic = eg, #legato, #normal, #staccato."
	"Set the articulation of notes to be emitted when a key is pressed."

	self allMorphsDo:
		[:m | ((m isMemberOf: SimpleSwitchMorph)
				and: [m actionSelector == #articulation:onOff:])
				ifTrue: [m setSwitchState: m arguments first == artic]].
	articulation := artic
]

{ #category : 'note controls' }
KeyboardMorphForInput >> backspaceNote [

	self deleteNotes
]

{ #category : 'note controls' }
KeyboardMorphForInput >> buildChord: onOff [
]

{ #category : 'note controls' }
KeyboardMorphForInput >> deleteNotes [

	pianoRoll deleteSelection
]

{ #category : 'note controls' }
KeyboardMorphForInput >> durMod: durMod onOff: ignored [    "durMod = eg, #dotted, #normal, #triplets, #quints"
	"Set the duration of notes to be emitted when a key is pressed."

	self allMorphsDo:
		[:m | ((m isMemberOf: SimpleSwitchMorph)
				and: [m actionSelector == #durMod:onOff:])
				ifTrue: [m setSwitchState: m arguments first = durMod]].
	durationModifier := durMod
]

{ #category : 'note controls' }
KeyboardMorphForInput >> duration: denom onOff: ignored [    "denom = eg, 1, 2, 4, 8, 16"
	"Set the duration of notes to be emitted when a key is pressed."

	self allMorphsDo:
		[:m | ((m isMemberOf: SimpleSwitchMorph)
				and: [m actionSelector == #duration:onOff:])
				ifTrue: [m setSwitchState: m arguments first = denom]].
	duration := denom.
	self durMod: #normal onOff: true
]

{ #category : 'note controls' }
KeyboardMorphForInput >> emitRest [

	| sel noteEvent |

	"All this selection logic should be shared with mouseDown..."
	(sel := pianoRoll selection) ifNil: [^ self].
	insertMode ifTrue:
		[sel := pianoRoll selectionForInsertion.
		insertMode := false].
	sel = prevSelection ifFalse:
		["This is a new selection -- need to determine start time"
		sel third = 0
			ifTrue: [startOfNextNote := 0]
			ifFalse: [startOfNextNote := ((pianoRoll score tracks at: sel first)
										at: sel third) endTime.
					startOfNextNote := startOfNextNote + self fullDuration - 1
										truncateTo: self fullDuration]].
	noteEvent := NoteEvent new time: startOfNextNote; duration: self noteDuration;
			key: -1 "my flag for rest" velocity: self velocity channel: 1.
	pianoRoll appendEvent: noteEvent fullDuration: self fullDuration.
	soundPlaying ifNotNil: [soundPlaying stopGracefully].
	prevSelection := pianoRoll selection.
	startOfNextNote := startOfNextNote + self fullDuration.
]

{ #category : 'note controls' }
KeyboardMorphForInput >> fullDuration [

	| num denom |
	num := denom := 1.
	durationModifier == #dotted ifTrue: [num := 3.  denom := 2].
	durationModifier == #triplets ifTrue: [num := 2.  denom := 3].
	durationModifier == #quints ifTrue: [num := 2.  denom := 5].
	^ pianoRoll score ticksPerQuarterNote * 4 * num // duration // denom
]

{ #category : 'initialization' }
KeyboardMorphForInput >> initialize [
"initialize the state of the receiver"
	super initialize.
""
	buildingChord := false.
	self addRecordingControls.
	self duration: 4 onOff: true.
	self durMod: #normal onOff: true.
	self articulation: #normal onOff: true.
	insertMode := false
]

{ #category : 'simple keyboard' }
KeyboardMorphForInput >> mouseDownPitch: midiKey event: event noteMorph: keyMorph [

	| sel noteEvent |
	event hand hasSubmorphs ifTrue: [^ self  "no response if drag something over me"].
	keyMorph color: playingKeyColor.
	(sel := pianoRoll selection) ifNil: [^ self].
	insertMode ifTrue:
		[sel := pianoRoll selectionForInsertion.
		insertMode := false].
	sel = prevSelection ifFalse:
		["This is a new selection -- need to determine start time"
		sel third = 0
			ifTrue: [startOfNextNote := 0]
			ifFalse: [startOfNextNote := ((pianoRoll score tracks at: sel first)
										at: sel third) endTime.
					startOfNextNote := startOfNextNote + self fullDuration - 1
										truncateTo: self fullDuration]].
	noteEvent := NoteEvent new time: startOfNextNote; duration: self noteDuration;
			key: midiKey + 23 velocity: self velocity channel: 1.
	pianoRoll appendEvent: noteEvent fullDuration: self fullDuration.
	soundPlaying ifNotNil: [soundPlaying stopGracefully].
	(soundPlaying := self soundForEvent: noteEvent inTrack: sel first) play.
	prevSelection := pianoRoll selection.
	startOfNextNote := startOfNextNote + self fullDuration.
]

{ #category : 'simple keyboard' }
KeyboardMorphForInput >> mouseUpPitch: pitch event: event noteMorph: noteMorph [
	noteMorph color: ((#(0 1 3 5 6 8 10) includes: pitch\\12)
					ifTrue: [whiteKeyColor]
					ifFalse: [blackKeyColor]).

]

{ #category : 'note controls' }
KeyboardMorphForInput >> noteDuration [

	articulation == #staccato ifTrue: [^ (self fullDuration * 0.65) asInteger].
	articulation == #normal ifTrue: [^ (self fullDuration * 0.8) asInteger].
	articulation == #legato ifTrue: [^ (self fullDuration * 0.95) asInteger].

]

{ #category : 'initialization' }
KeyboardMorphForInput >> pianoRoll: prMorph [

	pianoRoll := prMorph
]

{ #category : 'events' }
KeyboardMorphForInput >> soundForEvent: noteEvent inTrack: trackIndex [

	| sound player |
	player := pianoRoll scorePlayer.
	sound := MixedSound new.
	sound add: ((player instrumentForTrack: trackIndex)
					soundForMidiKey: noteEvent midiKey
					dur: noteEvent duration / (pianoRoll scorePlayer ticksForMSecs: 1000)
					loudness: (noteEvent velocity asFloat / 127.0))
			pan: (player panForTrack: trackIndex)
			volume: player overallVolume *
						(player volumeForTrack: trackIndex).
	^ sound

]

{ #category : 'note controls' }
KeyboardMorphForInput >> velocity [

	^ 80  "Later put a slider on the keyboard control"
]
