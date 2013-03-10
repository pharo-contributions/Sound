"
I implement one polyphonic channel of a 16-channel MIDI synthesizer. Many MIDI commands effect all the notes played on a particular channel, so I record the state for a single channel, including a list of notes currently playing.

This initial implementation is extremely spartan, having just enough functionality to play notes. Things that are not implemented include:

  1. program changes
  2. sustain pedal
  3. aftertouch (either kind)
  4. most controllers
  5. portamento
  6. mono-mode

"
Class {
	#name : #MIDISynthChannel,
	#superclass : #Object,
	#instVars : [
		'channel',
		'instrument',
		'muted',
		'masterVolume',
		'channelVolume',
		'pan',
		'pitchBend',
		'activeSounds'
	],
	#category : #'Sound-Scores'
}

{ #category : #other }
MIDISynthChannel >> adjustPitch: bend [
	"Handle a pitch-bend change."

	| pitchAdj |
	pitchBend := bend.
	pitchAdj := 2.0 raisedTo: (bend asFloat / 8192.0) / 6.0.
	activeSounds copy do: [:entry | | snd centerPitch |
		snd := entry at: 2.
		centerPitch := entry at: 3.
		snd pitch: pitchAdj * centerPitch.
		snd internalizeModulationAndRatio].

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> channelPressure: newPressure [
	"Handle a channel pressure (channel aftertouch) change."

	self newVolume: newPressure.

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> control: control value: newValue [
	"Handle a continuous controller change."

	control = 2 ifTrue: [self newVolume: newValue].  "breath controller"

]

{ #category : #other }
MIDISynthChannel >> convertVelocity: valueByte [
	"Map a value in the range 0..127 to a volume in the range 0.0..1.0."
	"Details: A quadratic function seems to give a good keyboard feel."

	| r |
	r := (valueByte * valueByte) / 12000.0.
	r > 1.0 ifTrue: [^ 1.0].
	r < 0.08 ifTrue: [^ 0.08].
	^ r

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> doChannelCmd: cmdByte byte1: byte1 byte2: byte2 [
	"Dispatch a channel command with the given arguments."
	"Details: Cases appear in order of expected frequency, most frequent cases first."

	cmdByte = 144 ifTrue: [
		byte2 = 0
			ifTrue: [^ self keyUp: byte1 vel: 0]
			ifFalse: [^ self keyDown: byte1 vel: byte2]].
	cmdByte = 128 ifTrue: [^ self keyUp: byte1 vel: byte2].
	cmdByte = 224 ifTrue: [^ self pitchBend: ((byte2 bitShift: 7) + byte1) - 8192].
	cmdByte = 176 ifTrue: [^ self control: byte1 value: byte2].
	cmdByte = 208 ifTrue: [^ self channelPressure: byte1].
	cmdByte = 160 ifTrue: [^ self key: byte1 pressure: byte2].
	cmdByte = 192 ifTrue: [^ self programChange: byte1].

]

{ #category : #initialization }
MIDISynthChannel >> initialize [

	super initialize.
	instrument := FMSound default.
	muted := false.
	masterVolume := 0.5.
	channelVolume := 1.0.
	pan := 0.5.
	pitchBend := 0.0.
	activeSounds := OrderedCollection new.

]

{ #category : #accessing }
MIDISynthChannel >> instrument [

	^ instrument

]

{ #category : #accessing }
MIDISynthChannel >> instrument: aSound [

	instrument := aSound.

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> key: key pressure: press [
	"Handle a key pressure (polyphonic aftertouch) change. Rarely implemented."

	"Do nothing for now."

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> keyDown: key vel: vel [
	"Handle a key down event with non-zero velocity."

	| pitch snd |
	muted ifTrue: [^ self].
	pitch := AbstractSound pitchForMIDIKey: key.
	snd := instrument
		soundForPitch: pitch
		dur: 10000.0  "sustain a long time, or until turned off"
		loudness: masterVolume * channelVolume * (self convertVelocity: vel).
	snd := (MixedSound new add: snd pan: pan) reset.
	SoundPlayer resumePlaying: snd quickStart: false.
	activeSounds add: (Array with: key with: snd with: pitch).

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> keyUp: key vel: vel [
	"Handle a key up event."

	
	activeSounds copy do: [:entry | | snd |
		(entry at: 1) = key ifTrue: [
			snd := entry at: 2.
			snd stopGracefully.
			activeSounds remove: entry]].

]

{ #category : #accessing }
MIDISynthChannel >> masterVolume [

	^ masterVolume

]

{ #category : #accessing }
MIDISynthChannel >> masterVolume: aNumber [
	"Set the master volume the the given value (0.0 to 1.0)."

	masterVolume := aNumber asFloat.

]

{ #category : #accessing }
MIDISynthChannel >> muted [

	^ muted

]

{ #category : #accessing }
MIDISynthChannel >> muted: aBoolean [

	muted := aBoolean.

]

{ #category : #other }
MIDISynthChannel >> newVolume: valueByte [
	"Set the channel volume to the level given by the given number in the range 0..127."

	| newVolume |
	channelVolume := valueByte asFloat / 127.0.
	newVolume := masterVolume * channelVolume.
	activeSounds do: [:entry | | snd |
		snd := entry at: 2.
		snd adjustVolumeTo: newVolume overMSecs: 10].

]

{ #category : #accessing }
MIDISynthChannel >> pan [

	^ pan

]

{ #category : #accessing }
MIDISynthChannel >> pan: aNumber [
	"Set the left-right pan to the given value (0.0 to 1.0)."

	pan := aNumber asFloat.

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> pitchBend: bend [
	"Handle a pitch-bend change."

	self adjustPitch: bend.

]

{ #category : #'midi dispatching' }
MIDISynthChannel >> programChange: newProgram [
	"Handle a program (instrument) change."

	"Do nothing for now."

]
