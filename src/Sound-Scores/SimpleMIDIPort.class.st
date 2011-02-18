"
This is a first cut at a simple MIDI output port.

"
Class {
	#name : #SimpleMIDIPort,
	#superclass : #Object,
	#instVars : [
		'portNumber',
		'accessSema',
		'lastCommandByteOut'
	],
	#classVars : [
		'DefaultPortNumber',
		'InterfaceClockRate'
	],
	#category : #'Sound-Scores'
}

{ #category : #utilities }
SimpleMIDIPort class >> closeAllPorts [
	"Close all MIDI ports."
	"SimpleMIDIPort closeAllPorts"

	| lastPortNum |
	lastPortNum := self primPortCount - 1.
	0 to: lastPortNum do: [:portNum | self basicNew primMIDIClosePort: portNum].

]

{ #category : #examples }
SimpleMIDIPort class >> examplePlayNoteNamedVelocityOnChannel [
	"self examplePlayNoteNamedVelocityOnChannel"
	
	|aPort|
	aPort:= self openOnPortNumber: 0.
	#('Bottle Blow' 'Shakuhachi' 'Whistle' 'Ocarina' 'Lead 1 (square)' 'Lead 2 (sawtooth)' 'Lead 3 (caliope lead)' 'Lead 4 (chiff lead)' 'Lead 5 (charang)' 'Lead 6 (voice)' 'Lead 7 (fifths)' 'Lead 8 (brass + lead)' 'Pad 1 (new age)' 'Pad 2 (warm)' 'Pad 3 (polysynth)' 'Pad 4 (choir)' 'Pad 5 (bowed)' 'Pad 6 (metallic)' 'Pad 7 (halo)' 'Pad 8 (sweep)' 'FX 1 (rain)' 'FX 2 (soundtrack)' 'FX 3 (crystal)' 'FX 4 (atmosphere)' 'FX 5 (brightness)' 'FX 6 (goblins)' 'FX 7 (echoes)' 'FX 8 (sci-fi)' 'Sitar' 'Banjo' 'Shamisen' 'Koto' 'Kalimba' 'Bagpipe' 'Fiddle' 'Shanai' 'Tinkle Bell' 'Agogo' 'Steel Drums' 'Woodblock' 'Taiko Drum' 'Melodic Tom' 'Synth Drum' 'Reverse Cymbal' 'Guitar Fret Noise' 'Breath Noise' 'Seashore' 'Bird Tweet' 'Telephone Ring' 'Helicopter' 'Applause' 'Gunshot' ) do: [:anInstrumentName | 
	[aPort useInstrument: anInstrumentName onChannel: 0.
	aPort playNoteNamed: 'c4' onChannel: 0.
	(Delay forMilliseconds: 250) wait.
	aPort stopNoteNamed: 'c4' onChannel: 0] ensure: [aPort close]]
]

{ #category : #initialization }
SimpleMIDIPort class >> initialize [
	"SimpleMIDIPort initialize"

	InterfaceClockRate := 1000000.
	DefaultPortNumber := 0.

]

{ #category : #utilities }
SimpleMIDIPort class >> inputPortNumFromUser [
	"Prompt the user for a MIDI input port. Answer a port number, or nil if the user does not select a port or if MIDI is not supported on this platform."
	"SimpleMIDIPort inputPortNumFromUser"

	| portCount aMenu dir col colVa colVal |
	portCount := self primPortCount.
	portCount = 0 ifTrue: [^ nil].
	col := OrderedCollection new. 
	colVa := OrderedCollection new. 
	0 to: portCount - 1 do:[:i |
		dir := self primPortDirectionalityOf: i.
		(dir = 1) | (dir = 3) ifTrue:[
			col add: (self portDescription: i).
			colVa add:  i]].
	^ MenuMorph 
		chooseFrom: col values: colVa lines: #()  title: 'MIDI port for input:' translated.
	
	 
]

{ #category : #utilities }
SimpleMIDIPort class >> midiInstruments [
	"self midiInstruments"
	^ #('Acoustic Grand Piano' 'Bright Acoustic Piano' 'Electric Grand Piano' 'Honky-tonk Piano' 'Rhodes Piano' 'Chorused Piano' 'Harpsichord' 'Clavinet' 'Celesta' 'Glockenspiel' 'Music box' 'Vibraphone' 'Marimba' 'Xylophone' 'Tubular Bells' 'Dulcimer' 'Hammond Organ' 'Percussive Organ' 'Rock Organ' 'Church Organ' 'Reed Organ' 'Accordian' 'Harmonica' 'Tango Accordian' 'Acoustic Guitar (nylon)' 'Acoustic Guitar (steel)' 'Electric Guitar (jazz)' 'Electric Guitar (clean)' 'Electric Guitar (muted)' 'Overdriven Guitar' 'Distortion Guitar' 'Guitar Harmonics' 'Acoustic Bass' 'Electric Bass (finger)' 'Electric Bass (pick)' 'Fretless Bass' 'Slap Bass 1' 'Slap Bass 2' 'Synth Bass 1' 'Synth Bass 2' 'Violin' 'Viola' 'Cello' 'Contrabass' 'Tremolo Strings' 'Pizzicato Strings' 'Orchestral Harp' 'Timpani' 'String Ensemble 1' 'String Ensemble 2' 'Synth Strings 1' 'Synth Strings 2' 'Choir Aahs' 'Voice Oohs' 'Synth Voice' 'Orchestra Hit' 'Trumpet' 'Trombone' 'Tuba' 'Muted Trumpet' 'French Horn' 'Brass Section' 'Synth Brass 1' 'Synth Brass 2' 'Soprano Sax' 'Alto Sax' 'Tenor Sax' 'Baritone Sax' 'Oboe' 'English Horn' 'Bassoon' 'Clarinet' 'Piccolo' 'Flute' 'Recorder' 'Pan Flute' 'Bottle Blow' 'Shakuhachi' 'Whistle' 'Ocarina' 'Lead 1 (square)' 'Lead 2 (sawtooth)' 'Lead 3 (caliope lead)' 'Lead 4 (chiff lead)' 'Lead 5 (charang)' 'Lead 6 (voice)' 'Lead 7 (fifths)' 'Lead 8 (brass + lead)' 'Pad 1 (new age)' 'Pad 2 (warm)' 'Pad 3 (polysynth)' 'Pad 4 (choir)' 'Pad 5 (bowed)' 'Pad 6 (metallic)' 'Pad 7 (halo)' 'Pad 8 (sweep)' 'FX 1 (rain)' 'FX 2 (soundtrack)' 'FX 3 (crystal)' 'FX 4 (atmosphere)' 'FX 5 (brightness)' 'FX 6 (goblins)' 'FX 7 (echoes)' 'FX 8 (sci-fi)' 'Sitar' 'Banjo' 'Shamisen' 'Koto' 'Kalimba' 'Bagpipe' 'Fiddle' 'Shanai' 'Tinkle Bell' 'Agogo' 'Steel Drums' 'Woodblock' 'Taiko Drum' 'Melodic Tom' 'Synth Drum' 'Reverse Cymbal' 'Guitar Fret Noise' 'Breath Noise' 'Seashore' 'Bird Tweet' 'Telephone Ring' 'Helicopter' 'Applause' 'Gunshot' )
]

{ #category : #utilities }
SimpleMIDIPort class >> midiIsSupported [
	"Answer true if this platform supports MIDI."

	^ self primPortCount > 0

]

{ #category : #'instance creation' }
SimpleMIDIPort class >> openDefault [
	"Answer a new instance of me opened on the default MIDI port."

	^ self openOnPortNumber: DefaultPortNumber

]

{ #category : #'instance creation' }
SimpleMIDIPort class >> openOnPortNumber: portNum [
	"Answer a new instance of me for the given MIDI port number."
	"Details: All clients of a particular MIDI port should share the same instance of me. This allows accesses to the port to be serialized and shared port-related state state to be maintained."

	SimpleMIDIPort allSubInstancesDo: [:p |
		p portNumber = portNum ifTrue: [
			"share the existing port object for this port number"
			^ p]].

	^ super new openOnPortNumber: portNum

]

{ #category : #utilities }
SimpleMIDIPort class >> outputPortNumFromUser [
	"Prompt the user for a MIDI output port. Answer a port number, or nil if the user does not select a port or if MIDI is not supported on this platform."
	"SimpleMIDIPort outputPortNumFromUser"

	| portCount aMenu dir col colVa |
	portCount := self primPortCount.
	portCount = 0 ifTrue: [^ nil].
	col := OrderedCollection new. 
	colVa := OrderedCollection new. 
	0 to: portCount - 1 do:[:i |
		dir := self primPortDirectionalityOf: i.
		(dir = 2) | (dir = 3) ifTrue:[
			col add: (self portDescription: i).
			colVa add: i]].
	^ MenuMorph 
		chooseFrom: col values: colVa lines: #() title: 'MIDI port for output:' translated.

]

{ #category : #utilities }
SimpleMIDIPort class >> percussionInstruments [
	"self percussionInstruments"
	^ #('Bottle Blow' 'Shakuhachi' 'Whistle' 'Ocarina' 'Lead 1 (square)' 'Lead 2 (sawtooth)' 'Lead 3 (caliope lead)' 'Lead 4 (chiff lead)' 'Lead 5 (charang)' 'Lead 6 (voice)' 'Lead 7 (fifths)' 'Lead 8 (brass + lead)' 'Pad 1 (new age)' 'Pad 2 (warm)' 'Pad 3 (polysynth)' 'Pad 4 (choir)' 'Pad 5 (bowed)' 'Pad 6 (metallic)' 'Pad 7 (halo)' 'Pad 8 (sweep)' 'FX 1 (rain)' 'FX 2 (soundtrack)' 'FX 3 (crystal)' 'FX 4 (atmosphere)' 'FX 5 (brightness)' 'FX 6 (goblins)' 'FX 7 (echoes)' 'FX 8 (sci-fi)' 'Sitar' 'Banjo' 'Shamisen' 'Koto' 'Kalimba' 'Bagpipe' 'Fiddle' 'Shanai' 'Tinkle Bell' 'Agogo' 'Steel Drums' 'Woodblock' 'Taiko Drum' 'Melodic Tom' 'Synth Drum' 'Reverse Cymbal' 'Guitar Fret Noise' 'Breath Noise' 'Seashore' 'Bird Tweet' 'Telephone Ring' 'Helicopter' 'Applause' 'Gunshot' )
]

{ #category : #utilities }
SimpleMIDIPort class >> portDescription: portNum [
	"Answer a string indicating the directionality of the given MIDI port."
	"(0 to: SimpleMIDIPort primPortCount - 1) collect:
		[:i | SimpleMIDIPort portDescription: i]"

	| portName dir |
	portName := (self primPortNameOf: portNum) convertFromSystemString.
	dir := self primPortDirectionalityOf: portNum.
	dir = 1 ifTrue: [^ portName, ' (in)'].
	dir = 2 ifTrue: [^ portName, ' (out)'].
	dir = 3 ifTrue: [^ portName, ' (in/out)'].
	^ self error: 'unknown MIDI port directionality'

]

{ #category : #primitives }
SimpleMIDIPort class >> primPortCount [
	"Answer the number of MIDI ports supported by this platform, or zero if this primitive is not implemented."

	<primitive: 'primitiveMIDIGetPortCount' module: 'MIDIPlugin'>
	^ 0

]

{ #category : #primitives }
SimpleMIDIPort class >> primPortDirectionalityOf: portNum [
	"Answer the platform-specific name for the given MIDI port."

	<primitive: 'primitiveMIDIGetPortDirectionality' module: 'MIDIPlugin'>
	self primitiveFailed.

]

{ #category : #primitives }
SimpleMIDIPort class >> primPortNameOf: portNum [
	"Answer the platform-specific name for the given MIDI port."

	<primitive: 'primitiveMIDIGetPortName' module: 'MIDIPlugin'>
	self primitiveFailed.

]

{ #category : #input }
SimpleMIDIPort >> bufferTimeStampFrom: aByteArray [
	"Return the timestamp from the given MIDI input buffer. Assume the given buffer is at least 4 bytes long."

	^ ((aByteArray at: 1) bitShift: 24) +
	  ((aByteArray at: 2) bitShift: 16) +
	  ((aByteArray at: 3) bitShift: 8) +
	   (aByteArray at: 4)

]

{ #category : #'open/close' }
SimpleMIDIPort >> close [
	"Close this MIDI port."

	portNumber ifNotNil: [self primMIDIClosePort: portNumber].
	accessSema := nil.
	lastCommandByteOut := nil.

]

{ #category : #'open/close' }
SimpleMIDIPort >> ensureOpen [
	"Make sure this MIDI port is open. It is good to call this before starting to use a port in case an intervening image save/restore has caused the underlying hardware port to get closed."

	portNumber ifNil: [^ self error: 'Use "openOn:" to open a MIDI port initially'].
	self primMIDIClosePort: portNumber.
	self primMIDIOpenPort: portNumber readSemaIndex: 0 interfaceClockRate: InterfaceClockRate.
	accessSema := Semaphore forMutualExclusion.
	lastCommandByteOut := Array new: 16 withAll: 0.  "clear running status"

]

{ #category : #input }
SimpleMIDIPort >> flushInput [
	"Read any lingering MIDI data from this port's input buffer."

	| buf |
	buf := ByteArray new: 1000.
	[(self readInto: buf) > 0] whileTrue.

]

{ #category : #output }
SimpleMIDIPort >> midiCmd: cmd channel: channel byte: dataByte [
	"Immediately output the given MIDI command with the given channel and argument byte to this MIDI port. Assume that the port is open."

	accessSema critical: [
		self primMIDIWritePort: portNumber
			from: (ByteArray
					with: (cmd bitOr: channel)
					with: dataByte)
			at: 0].

]

{ #category : #output }
SimpleMIDIPort >> midiCmd: cmd channel: channel byte: dataByte1 byte: dataByte2 [
	"Immediately output the given MIDI command with the given channel and argument bytes to this MIDI port. Assume that the port is open."

	accessSema critical: [
		self primMIDIWritePort: portNumber
			from: (ByteArray
					with: (cmd bitOr: channel)
					with: dataByte1
					with: dataByte2)
			at: 0].

]

{ #category : #output }
SimpleMIDIPort >> midiOutput: aByteArray [
	"Output the given bytes to this MIDI port immediately. Assume that the port is open."

	accessSema critical: [
		self primMIDIWritePort: portNumber from: aByteArray at: 0].

]

{ #category : #'open/close' }
SimpleMIDIPort >> openOnPortNumber: portNum [
	"Open this MIDI port on the given port number."

	self close.
	portNumber := portNum.
	accessSema := Semaphore forMutualExclusion.
	self ensureOpen.

]

{ #category : #primitives }
SimpleMIDIPort >> playNote: aNote onChannel: aChannel [
	self playNote: aNote velocity: 64 onChannel: aChannel
]

{ #category : #primitives }
SimpleMIDIPort >> playNote: aNote velocity: aVel onChannel: aChannel [
	self midiCmd: 144 channel: aChannel byte: aNote byte: aVel
]

{ #category : #primitives }
SimpleMIDIPort >> playNoteNamed: aNotename onChannel: aChannel [
	self playNoteNamed: aNotename velocity: 64 onChannel: aChannel
]

{ #category : #primitives }
SimpleMIDIPort >> playNoteNamed: aNotename velocity: aVel onChannel: aChannel [
	self playNote: (AbstractSound midiKeyForPitch: aNotename) velocity: aVel onChannel: aChannel

	
]

{ #category : #'open/close' }
SimpleMIDIPort >> portNumber [
	"Answer my port number."

	^ portNumber

]

{ #category : #primitives }
SimpleMIDIPort >> primMIDIClosePort: portNum [
	"Close the given MIDI port. Don't fail if port is already closed."

	<primitive: 'primitiveMIDIClosePort' module: 'MIDIPlugin'>

]

{ #category : #primitives }
SimpleMIDIPort >> primMIDIOpenPort: portNum readSemaIndex: readSemaIndex interfaceClockRate: interfaceClockRate [
	"Open the given MIDI port. If non-zero, readSemaIndex specifies the index in the external objects array of a semaphore to be signalled when incoming MIDI data is available. Not all platforms support signalling the read semaphore. InterfaceClockRate specifies the clock rate of the external MIDI interface adaptor on Macintosh computers; it is ignored on other platforms."

	<primitive: 'primitiveMIDIOpenPort' module: 'MIDIPlugin'>
	self primitiveFailed.

]

{ #category : #primitives }
SimpleMIDIPort >> primMIDIReadPort: portNum into: byteArray [
	"Read any available MIDI data into the given buffer (up to the size of the buffer) and answer the number of bytes read."

	<primitive: 'primitiveMIDIRead' module: 'MIDIPlugin'>
	self primitiveFailed.

]

{ #category : #primitives }
SimpleMIDIPort >> primMIDIWritePort: portNum from: byteArray at: midiClockValue [
	"Queue the given data to be sent through the given MIDI port at the given time. If midiClockValue is zero, send the data immediately."

	<primitive: 'primitiveMIDIWrite' module: 'MIDIPlugin'>
	self primitiveFailed.

]

{ #category : #input }
SimpleMIDIPort >> readInto: aByteArray [
	"Read any data from this port into the given buffer."

	^ self primMIDIReadPort: portNumber into: aByteArray

]

{ #category : #primitives }
SimpleMIDIPort >> stopNote: aNote onChannel: aChannel [
	self stopNote: aNote velocity: 64 onChannel: aChannel
]

{ #category : #primitives }
SimpleMIDIPort >> stopNote: aNote velocity: aVel onChannel: aChannel [
	self midiCmd: 128 channel: aChannel byte: aNote byte: aVel
]

{ #category : #primitives }
SimpleMIDIPort >> stopNoteNamed: aNotename onChannel: aChannel [
	self stopNoteNamed: aNotename velocity: 64 onChannel: aChannel
]

{ #category : #primitives }
SimpleMIDIPort >> stopNoteNamed: aNotename velocity: aVel onChannel: aChannel [
	self stopNote: (AbstractSound midiKeyForPitch: aNotename) velocity: aVel onChannel: aChannel
	 
]

{ #category : #'open/close' }
SimpleMIDIPort >> useInstrument: aName onChannel: aChannel [
	self useInstrumentNumber: (self class midiInstruments indexOf: aName)-1 onChannel: aChannel
]

{ #category : #'open/close' }
SimpleMIDIPort >> useInstrumentNumber: aNumber onChannel: aChannel [
	self ensureOpen.
	self midiCmd: 192 channel: aChannel byte: aNumber 
]
