"
I implement a piano keyboard that can be played with the mouse. I can output to a MIDI port, if MIDI is supported on this platform. I can also spawn controllers for other MIDI parameters, such as pitch bend.

"
Class {
	#name : #MIDIPianoKeyboardMorph,
	#superclass : #PianoKeyboardMorph,
	#instVars : [
		'midiPort',
		'channel',
		'velocity'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #menus }
MIDIPianoKeyboardMorph >> addCustomMenuItems: aCustomMenu hand: aHandMorph [

	super addCustomMenuItems: aCustomMenu hand: aHandMorph.
	midiPort
		ifNil: [aCustomMenu add: 'play via MIDI' translated action: #openMIDIPort]
		ifNotNil: [
			aCustomMenu add: 'play via built in synth' translated action: #closeMIDIPort.
			aCustomMenu add: 'new MIDI controller' translated action: #makeMIDIController:].

]

{ #category : #'as yet unclassified' }
MIDIPianoKeyboardMorph >> closeMIDIPort [

	midiPort := nil.

]

{ #category : #initialization }
MIDIPianoKeyboardMorph >> initialize [
"initialize the state of the receiver"
	super initialize.
""
	SimpleMIDIPort midiIsSupported
		ifTrue: [midiPort := SimpleMIDIPort openDefault].
	channel := 1.
	velocity := 100
]

{ #category : #'as yet unclassified' }
MIDIPianoKeyboardMorph >> makeMIDIController: evt [

	self world activeHand attachMorph:
		(MIDIControllerMorph new midiPort: midiPort).

]

{ #category : #'simple keyboard' }
MIDIPianoKeyboardMorph >> mouseDownPitch: midiKey event: event noteMorph: noteMorph [

	midiPort ifNil: [^ super mouseDownPitch: midiKey-1 event: event noteMorph: noteMorph].
	noteMorph color: playingKeyColor.
	soundPlaying
		ifNil: [midiPort ensureOpen]
		ifNotNil: [self turnOffNote].
	self turnOnNote: midiKey + 23.

]

{ #category : #'simple keyboard' }
MIDIPianoKeyboardMorph >> mouseUpPitch: midiKey event: event noteMorph: noteMorph [

	midiPort ifNil: [
		^ super mouseUpPitch: midiKey event: event noteMorph: noteMorph].

	noteMorph color:
		((#(0 1 3 5 6 8 10) includes: midiKey \\ 12)
			ifTrue: [whiteKeyColor]
			ifFalse: [blackKeyColor]).
	soundPlaying ifNotNil: [self turnOffNote].

]

{ #category : #'as yet unclassified' }
MIDIPianoKeyboardMorph >> openMIDIPort [

	| portNum |
	portNum := SimpleMIDIPort outputPortNumFromUser.
	portNum ifNil: [^ self].
	midiPort := SimpleMIDIPort openOnPortNumber: portNum.

]

{ #category : #'as yet unclassified' }
MIDIPianoKeyboardMorph >> turnOffNote [

	midiPort notNil & soundPlaying notNil ifTrue: [
		soundPlaying isInteger ifTrue: [
			midiPort midiCmd: 16r90 channel: channel byte: soundPlaying byte: 0]].
	soundPlaying := nil.

]

{ #category : #'as yet unclassified' }
MIDIPianoKeyboardMorph >> turnOnNote: midiKey [

	midiPort midiCmd: 16r90 channel: channel byte: midiKey byte: velocity.
	soundPlaying := midiKey.

]
