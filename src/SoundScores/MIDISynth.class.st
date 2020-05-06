"
I implement a simple real-time MIDI synthesizer on platforms that support MIDI input. I work best on platforms that allow the sound buffer to be made very short--under 50 milliseconds is good and under 20 milliseconds is preferred (see below). The buffer size is changed by modifying the class initialization method of SoundPlayer and executing the do-it there to re-start the sound player.

Each instance of me takes input from a single MIDI input port. Multiple instances of me can be used to handle multiple MIDI input ports. I distribute incoming commands among my sixteen MIDISynthChannel objects. Most of the interpretation of the MIDI commands is done by these channel objects. 

Buffer size notes: At the moment, most fast PowerPC Macintosh computers can probably work with buffer sizes down to 50 milliseconds, and the Powerbook G3 works down to about 15 milliseconds. You will need to experiment to discover the minimum buffer size that does not result in clicking during sound output. (Hint: Be sure to turn off power cycling on your Powerbook. Other applications and extensions can steal cycles from Squeak, causing intermittent clicking. Experimentation may be necessary to find a configuration that works for you.)

"
Class {
	#name : #MIDISynth,
	#superclass : #Object,
	#instVars : [
		'midiParser',
		'channels',
		'process'
	],
	#category : #'SoundScores-MIDI'
}

{ #category : #examples }
MIDISynth class >> example [
	"Here's one way to run the MIDI synth. It will get a nice Morphic UI later. Click the mouse to stop running it. (Mac users note: be sure you have MIDI interface adaptor plugged in, or Squeak will hang waiting for the external clock signal.)."
	"MIDISynth example"

	| portNum synth |
	portNum := SimpleMIDIPort inputPortNumFromUser.
	portNum ifNil: [^ self].
	SoundPlayer useShortBuffer.
	synth := MIDISynth new
		midiPort: (SimpleMIDIPort openOnPortNumber: portNum).
	synth midiParser ignoreCommand: 224.  "filter out pitch bends"
	1 to: 16 do: [:i |
		(synth channel: i) instrument:
 			 (AbstractSound soundNamed: 'oboe1')].
	1 to: 16 do: [:ch | synth volumeForChannel: ch put: 0.2].

	synth processMIDIUntilMouseDown.
	SoundPlayer shutDown; initialize.  "revert to normal buffer size"

]

{ #category : #accessing }
MIDISynth >> channel: i [

	^ channels at: i

]

{ #category : #initialization }
MIDISynth >> closeMIDIPort [

	midiParser midiPort ifNil: [^ self].
	midiParser midiPort close.
	midiParser midiPort: nil.

]

{ #category : #initialization }
MIDISynth >> initialize [

	super initialize.
	midiParser := MIDIInputParser on: nil.
	channels := (1 to: 16) collect: [:ch | MIDISynthChannel new initialize].

]

{ #category : #'accessing-midi' }
MIDISynth >> instrumentForChannel: channelIndex [

	^ (channels at: channelIndex) instrument

]

{ #category : #'accessing-midi' }
MIDISynth >> instrumentForChannel: channelIndex put: aSoundProto [

	(channels at: channelIndex) instrument: aSoundProto.

]

{ #category : #testing }
MIDISynth >> isOn [

	^ process notNil

]

{ #category : #accessing }
MIDISynth >> midiParser [

	^ midiParser

]

{ #category : #accessing }
MIDISynth >> midiPort [

	^ midiParser midiPort

]

{ #category : #accessing }
MIDISynth >> midiPort: aMIDIPortOrNil [

	midiParser midiPort: aMIDIPortOrNil.

]

{ #category : #actions }
MIDISynth >> midiTrackingLoop [

	midiParser clearBuffers.
	[true] whileTrue: [
		self processMIDI ifFalse: [(Delay forMilliseconds: 5) wait]].

]

{ #category : #'accessing-midi' }
MIDISynth >> mutedForChannel: channelIndex put: aBoolean [

	^ (channels at: channelIndex) muted: aBoolean

]

{ #category : #'accessing-midi' }
MIDISynth >> panForChannel: channelIndex [

	^ (channels at: channelIndex) pan

]

{ #category : #'accessing-midi' }
MIDISynth >> panForChannel: channelIndex put: newPan [

	(channels at: channelIndex) pan: newPan.

]

{ #category : #actions }
MIDISynth >> processMIDI [
	"Process some MIDI commands. Answer true if any commands were processed."

	| didSomething |
	didSomething := false.
	midiParser midiDo: [:item | | cmdByte byte1 chan cmd byte2 |
		didSomething := true.
		cmdByte := item at: 2.
		byte1 := byte2 := nil.
		item size > 2 ifTrue: [
			byte1 := item at: 3.
			item size > 3 ifTrue: [byte2 := item at: 4]].
		cmdByte < 240
			ifTrue: [  "channel message" 
				cmd := cmdByte bitAnd: 2r11110000.
				chan := (cmdByte bitAnd: 2r00001111) + 1.
				(channels at: chan) doChannelCmd: cmd byte1: byte1 byte2: byte2]
			ifFalse: [  "system message"
				"process system messages here"
			]].
	^ didSomething

]

{ #category : #actions }
MIDISynth >> processMIDIUntilMouseDown [
	"Used for debugging. Do MIDI processing until the mouse is pressed."

	midiParser clearBuffers.
	[Sensor anyButtonPressed] whileFalse: [self processMIDI].

]

{ #category : #'accessing-midi' }
MIDISynth >> setAllChannelMasterVolumes: aNumber [

	| vol |
	vol := (aNumber asFloat min: 1.0) max: 0.0.
	channels do: [:ch | ch masterVolume: vol].

]

{ #category : #actions }
MIDISynth >> startMIDITracking [

	midiParser ifNil: [^ self].
	midiParser midiPort ifNil: [^ self].
	midiParser midiPort ensureOpen.
	self stopMIDITracking.
	SoundPlayer useShortBuffer.
	process := [self midiTrackingLoop] newProcess.
	process priority: Processor userInterruptPriority.
	process resume.

]

{ #category : #actions }
MIDISynth >> stopMIDITracking [

	process ifNotNil: [
		process terminate.
		process := nil].
	SoundPlayer shutDown; initialize.  "revert to normal buffer size"

]

{ #category : #'accessing-midi' }
MIDISynth >> volumeForChannel: channelIndex [

	^  (channels at: channelIndex) masterVolume

]

{ #category : #'accessing-midi' }
MIDISynth >> volumeForChannel: channelIndex put: newVolume [

	(channels at: channelIndex) masterVolume: newVolume.

]
