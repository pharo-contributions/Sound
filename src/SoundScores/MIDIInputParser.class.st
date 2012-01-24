"
I am a parser for a MIDI data stream. I support:

	real-time MIDI recording,
	overdubbing (recording while playing),
	monitoring incoming MIDI, and
	interactive MIDI performances.

Note: MIDI controllers such as pitch benders and breath controllers generate large volumes of data which consume processor time. In cases where this information is not of interest to the program using it, it is best to filter it out as soon as possible. I support various options for doing this filtering, including filtering by MIDI channel and/or by command type.

"
Class {
	#name : #MIDIInputParser,
	#superclass : #Object,
	#instVars : [
		'cmdActionTable',
		'midiPort',
		'received',
		'rawDataBuffer',
		'sysExBuffer',
		'ignoreSysEx',
		'startTime',
		'timeNow',
		'state',
		'lastSelector',
		'lastCmdByte',
		'argByte1',
		'argByte2'
	],
	#classVars : [
		'DefaultMidiTable'
	],
	#category : #SoundScores
}

{ #category : #initialization }
MIDIInputParser class >> initialize [
	"Build the default MIDI command-byte action table. This table maps MIDI command bytes to the action to be performed when that is received. Note that MIDI data bytes (bytes whose value is < 128) are never used to index into this table."
	"MIDIInputParser initialize"

	DefaultMidiTable := Array new: 255 withAll: #undefined:.
	128 to: 143 do: [:i | DefaultMidiTable at: i put: #recordTwo:].		"key off"
	144 to: 159 do: [:i | DefaultMidiTable at: i put: #recordTwo:].		"key on"
	160 to: 175 do: [:i | DefaultMidiTable at: i put: #recordTwo:].		"polyphonic after-touch"
	176 to: 191 do: [:i | DefaultMidiTable at: i put: #recordTwo:].		"control change"
	192 to: 207 do: [:i | DefaultMidiTable at: i put: #recordOne:].		"program change"
	208 to: 223 do: [:i | DefaultMidiTable at: i put: #recordOne:].		"channel after-touch"
	224 to: 239 do: [:i | DefaultMidiTable at: i put: #recordTwo:].		"pitch bend"

	DefaultMidiTable at: 240 put: #startSysExclusive:.		"start a system exclusive block"
	DefaultMidiTable at: 241 put: #recordOne:.			"MIDI time code quarter frame"
	DefaultMidiTable at: 242 put: #recordTwo:.			"song position select"
	DefaultMidiTable at: 243 put: #recordOne:.			"song select"
	DefaultMidiTable at: 244 put: #undefined:.
	DefaultMidiTable at: 245 put: #undefined:.
	DefaultMidiTable at: 246 put: #recordZero:.			"tune request"
	DefaultMidiTable at: 247 put: #endSysExclusive:.		"end a system exclusive block"
	DefaultMidiTable at: 248 put: #recordZero:.			"timing clock"
	DefaultMidiTable at: 249 put: #undefined:.
	DefaultMidiTable at: 250 put: #recordZero:.			"start"
	DefaultMidiTable at: 251 put: #recordZero:.			"continue"
	DefaultMidiTable at: 252 put: #recordZero:.			"stop/Clock"
	DefaultMidiTable at: 253 put: #undefined:.
	DefaultMidiTable at: 254 put: #recordZero:.			"active sensing"
	DefaultMidiTable at: 255 put: #recordZero:.			"system reset"

]

{ #category : #'instance creation' }
MIDIInputParser class >> on: aSimpleMIDIPort [
	"Answer a new MIDI parser on the given port."

	^ super new setMIDIPort: aSimpleMIDIPort

]

{ #category : #recording }
MIDIInputParser >> clearBuffers [
	"Clear the MIDI record buffers. This should be called at the start of recording or real-time MIDI processing."	

	received := received species new: 5000.
	rawDataBuffer := ByteArray new: 1000.
	sysExBuffer := WriteStream on: (ByteArray new: 100).
	midiPort ifNotNil: [midiPort ensureOpen; flushInput].
	startTime := Time millisecondClockValue.
	state := #idle.

]

{ #category : #'private-state machine' }
MIDIInputParser >> endSysExclusive: cmdByte [
	"Error! Received 'end system exclusive' command when not receiving system exclusive data."

	self error: 'unexpected ''End of System Exclusive'' command'.

]

{ #category : #'midi filtering' }
MIDIInputParser >> ignoreChannel: channel [
	"Don't record any events arriving on the given MIDI channel (in the range 1-16)."

	((channel isInteger not) | (channel < 1) | (channel > 16))
		ifTrue: [^ self error: 'bad MIDI channel number', channel printString].

	"two-arg channel messages"
	#(128 144 160 176 224) do: [:i | cmdActionTable at: (i bitOr: channel - 1) put: #ignoreTwo:].

	"one-arg channel messages"
	#(192 208) do: [:i | cmdActionTable at: (i bitOr: channel - 1) put: #ignoreOne:].

]

{ #category : #'midi filtering' }
MIDIInputParser >> ignoreCommand: midiCmd [
	"Don't record the given MIDI command on any channel."

	| cmd sel | 
	((midiCmd isInteger not) | (midiCmd < 128) | (midiCmd > 255))
		ifTrue: [^ self error: 'bad MIDI command'].

	midiCmd < 240 ifTrue: [  "channel commands; ignore on all channels"
		cmd := midiCmd bitAnd: 2r11110000.
		sel := (#(128 144 160 176 224) includes: cmd)
			ifTrue: [#ignoreTwo:]
			ifFalse: [#ignoreOne:].
		 1 to: 16 do: [:ch | cmdActionTable at: (cmd bitOr: ch - 1) put: sel].
		^ self].

	(#(240 241 244 245 247 249 253) includes: midiCmd) ifTrue: [
		^ self error: 'You can''t ignore the undefined MIDI command: ', midiCmd printString].

	midiCmd = 242 ifTrue: [  "two-arg command"
		cmdActionTable at: midiCmd put: #ignoreTwo:.
		 ^ self].

	midiCmd = 243 ifTrue: [  "one-arg command"
		cmdActionTable at: midiCmd put: #ignoreOne:.
		^ self].

	(#(246 248 250 251 252 254 255) includes: midiCmd) ifTrue:	[  "zero-arg command"
		cmdActionTable at: midiCmd put: #ignore.
		 ^ self].

	"we should not get here"
	self error: 'implementation error'.

]

{ #category : #'private-state machine' }
MIDIInputParser >> ignoreOne: cmdByte [
	"Ignore a one argument command."	

	lastCmdByte := cmdByte.
	lastSelector := #ignoreOne:.
	state := #ignore1.

]

{ #category : #'midi filtering' }
MIDIInputParser >> ignoreSysEx: aBoolean [
	"If the argument is true, then ignore incoming system exclusive message."

	ignoreSysEx := aBoolean.

]

{ #category : #'midi filtering' }
MIDIInputParser >> ignoreTuneAndRealTimeCommands [
	"Ignore tuning requests and real-time commands."

	cmdActionTable at: 246 put: #ignoreZero:.	"tune request"
	cmdActionTable at: 248 put: #ignoreZero:.	"timing clock"
	cmdActionTable at: 250 put: #ignoreZero:.	"start"
	cmdActionTable at: 251 put: #ignoreZero:.		"continue"
	cmdActionTable at: 252 put: #ignoreZero:.	"stop/Clock"
	cmdActionTable at: 254 put: #ignoreZero:.	"active sensing"
	cmdActionTable at: 255 put: #ignoreZero:.	"system reset"

]

{ #category : #'private-state machine' }
MIDIInputParser >> ignoreTwo: cmdByte [
	"Ignore a two argument command."	

	lastCmdByte := cmdByte.
	lastSelector := #ignoreTwo:.
	state := #ignore2.

]

{ #category : #'private-state machine' }
MIDIInputParser >> ignoreZero: cmdByte [
	"Ignore a zero argument command, such as tune request or a real-time message. Stay in the current and don't change active status. Note that real-time messages can arrive between data bytes without disruption."	

	"do nothing"

]

{ #category : #'real-time processing' }
MIDIInputParser >> midiDo: aBlock [
	"Poll the incoming MIDI stream in real time and call the given block for each complete command that has been received. The block takes one argument, which is an array of the form (<time><cmd byte>[<arg1>[<arg2>]]). The number of arguments depends on the command byte. For system exclusive commands, the argument is a ByteArray containing the system exclusive message."

	self processMIDIData.
	[received isEmpty] whileFalse:
		[aBlock value: received removeFirst].

]

{ #category : #'real-time processing' }
MIDIInputParser >> midiDoUntilMouseDown: midiActionBlock [
	"Process the incoming MIDI stream in real time by calling midiActionBlock for each MIDI event. This block takes three arguments: the MIDI command byte and two argument bytes. One or both argument bytes may be nil, depending on the MIDI command. If not nil, evaluatue idleBlock regularly whether MIDI data is available or not. Pressing any mouse button terminates the interaction."

	| time cmd arg1 arg2 |
	self clearBuffers.
	[Sensor anyButtonPressed] whileFalse: [
		self midiDo: [:item |
			time := item at: 1.
			cmd := item at: 2.
			arg1 := arg2 := nil.
			item size > 2 ifTrue: [
				arg1 := item at: 3.
				item size > 3 ifTrue: [arg2 := item at: 4]].
				midiActionBlock value: cmd value: arg1 value: arg2]].

]

{ #category : #accessing }
MIDIInputParser >> midiPort [

	^ midiPort

]

{ #category : #accessing }
MIDIInputParser >> midiPort: aMIDIPort [
	"Use the given MIDI port."

	midiPort := aMIDIPort.
	self clearBuffers.

]

{ #category : #'midi monitor' }
MIDIInputParser >> monitor [
	"Print MIDI messages to the transcript until any mouse button is pressed."

	self midiDoUntilMouseDown: [:cmd :arg1 :arg2 |
		self printCmd: cmd with: arg1 with: arg2].

]

{ #category : #'midi filtering' }
MIDIInputParser >> noFiltering [
	"Revert to accepting all MIDI commands on all channels. This undoes any earlier request to filter the incoming MIDI stream."

	cmdActionTable := DefaultMidiTable deepCopy.
	ignoreSysEx := false.

]

{ #category : #'midi monitor' }
MIDIInputParser >> printCmd: cmdByte with: arg1 with: arg2 [
	"Print the given MIDI command."

	| cmd ch bend |
	cmdByte < 240
		ifTrue: [  "channel message" 
			cmd := cmdByte bitAnd: 2r11110000.
			ch := (cmdByte bitAnd: 2r00001111) + 1]
		ifFalse: [cmd := cmdByte].  "system message"

	cmd = 128 ifTrue: [
		^ Transcript show: ('key up ', arg1 printString, ' vel: ', arg2 printString, ' chan: ', ch printString); cr].
	cmd = 144 ifTrue: [
		^ Transcript show: ('key down: ', arg1 printString, ' vel: ', arg2 printString, ' chan: ', ch printString); cr].
	cmd = 160 ifTrue: [
		^ Transcript show: ('key pressure: ', arg1 printString, ' val: ', arg2 printString, ' chan: ', ch printString); cr].
	cmd = 176 ifTrue: [
		^ Transcript show: ('CC', arg1 printString, ': val: ', arg2 printString, ' chan: ', ch printString); cr].
	cmd = 192 ifTrue: [
		^ Transcript show: ('prog: ', (arg1 + 1) printString, ' chan: ', ch printString); cr].
	cmd = 208 ifTrue: [
		^ Transcript show: ('channel pressure ', arg1 printString, ' chan: ', ch printString); cr].
	cmd = 224 ifTrue: [
		bend := ((arg2 bitShift: 7) + arg1) - 8192.
		^ Transcript show: ('bend: ', bend printString, ' chan: ', ch printString); cr].

	cmd = 240 ifTrue: [
		^ Transcript show: ('system exclusive: ', (arg1 at: 1) printString, ' (', arg1 size printString, ' bytes)'); cr].

	Transcript show: 'cmd: ', cmd printString, ' arg1: ', arg1 printString, ' arg2: ', arg2 printString; cr.

]

{ #category : #'private-state machine' }
MIDIInputParser >> processByte: aByte [
	"Process the given incoming MIDI byte and record completed commands."
	"Details: Because this must be fast, it has been hand-tuned. Be careful!"

	aByte > 247 ifTrue: [  "real-time message; can arrive at any time"
		^ self perform: (cmdActionTable at: aByte) with: aByte].

	#idle = state ifTrue: [
		aByte >= 128
			ifTrue: [  "command byte in idle state: start new command"
				^ self perform: (cmdActionTable at: aByte) with: aByte]
			ifFalse: [  "data byte in idle state: use running status if possible"
				lastCmdByte ifNil: [^ self].  "running status unknown; skip byte"
				"process this data as if it had the last command byte in front of it"
				 self perform: lastSelector with: lastCmdByte.

				"the previous line put us into a new state; we now 'fall through'
				 to process the data byte given this new state."]].

	#ignore1 = state ifTrue: [^ state := #idle].
	#ignore2 = state ifTrue: [^ state := #ignore1].

	#want1of2 = state ifTrue: [
		argByte1 := aByte.
		^ state := #want2of2].

	#want2of2 = state ifTrue: [
		argByte2 := aByte.
		received addLast: (Array with: timeNow with: lastCmdByte with: argByte1 with: argByte2).
		^ state := #idle].

	#want1only = state ifTrue: [
		argByte1 := aByte.
		received addLast: (Array with: timeNow with: lastCmdByte with: argByte1).
		^ state := #idle].

	#sysExclusive = state ifTrue: [
		aByte < 128 ifTrue: [
			"record a system exclusive data byte"
			ignoreSysEx ifFalse: [sysExBuffer nextPut: aByte].
			^ self]
		ifFalse: [
			aByte < 248 ifTrue: [
				"a system exclusive message is terminated by any non-real-time command byte"
				ignoreSysEx ifFalse: [
					received addLast: (Array with: timeNow with: lastCmdByte with: sysExBuffer contents)].
				state := #idle.
				aByte = 247
					ifTrue: [^ self]							"endSysExclusive command, nothing left to do"
					ifFalse: [^ self processByte: aByte]]]].  	"no endSysExclusive; just start the next command"

]

{ #category : #recording }
MIDIInputParser >> processMIDIData [
	"Process all MIDI data that has arrived since the last time this method was executed. This method should be called frequently to process, filter, and timestamp MIDI data as it arrives."

	| bytesRead |
	[(bytesRead := midiPort readInto: rawDataBuffer) > 0] whileTrue: [
		timeNow := (midiPort bufferTimeStampFrom: rawDataBuffer) - startTime.
		5 to: bytesRead do: [:i | self processByte: (rawDataBuffer at: i)]].

]

{ #category : #recording }
MIDIInputParser >> received [
	"Answer my current collection of all MIDI commands received. Items in this list have the form (<time><cmd byte>[<arg1>[<arg2>]]). Note that the real-time processing facility, midiDo:, removes items from this list as it processes them."

	^ received

]

{ #category : #'private-state machine' }
MIDIInputParser >> recordOne: cmdByte [
	"Record a one argument command at the current time."	

	lastCmdByte := cmdByte.
	lastSelector := #recordOne:.
	state := #want1only.

]

{ #category : #'midi filtering' }
MIDIInputParser >> recordOnlyChannels: channelList [
	"Record only MIDI data arriving on the given list of channel numbers (in the range 1-16)."

	channelList do: [:ch |
		((ch isInteger not) | (ch < 1) | (ch > 16))
			ifTrue: [^ self error: 'bad Midi channel specification: ', ch printString]].

	1 to: 16 do: [:ch | (channelList includes: ch) ifFalse: [self ignoreChannel: ch]].

]

{ #category : #'private-state machine' }
MIDIInputParser >> recordTwo: cmdByte [
	"Record a two argument command at the current time."	

	lastCmdByte := cmdByte.
	lastSelector := #recordTwo:.
	state := #want1of2.

]

{ #category : #'private-state machine' }
MIDIInputParser >> recordZero: cmdByte [
	"Record a zero-byte message, such as tune request or a real-time message. Don't change active status. Note that real-time messages can arrive between data bytes without disruption."	

	received addLast: (Array with: timeNow with: cmdByte).

]

{ #category : #'private-other' }
MIDIInputParser >> setMIDIPort: aMIDIPort [
	"Initialize this instance for recording from the given MIDI port. Tune and real-time commands are filtered out by default; the client can send noFiltering to receive these messages."

	midiPort := aMIDIPort.
	received := OrderedCollection new.
	self noFiltering.  "initializes cmdActionTable"
	self ignoreTuneAndRealTimeCommands.

]

{ #category : #'private-state machine' }
MIDIInputParser >> startSysExclusive: cmdByte [
	"The beginning of a variable length 'system exclusive' command."

	sysExBuffer resetContents.
	lastCmdByte := nil.  "system exclusive commands clear running status"
	lastSelector := nil.
	state := #sysExclusive.

]

{ #category : #'private-state machine' }
MIDIInputParser >> undefined: cmdByte [
	"We have received an unexpected MIDI byte (e.g., a data byte when we were expecting a command). This should never happen."

	self error: 'unexpected MIDI byte ', cmdByte printString.

]
