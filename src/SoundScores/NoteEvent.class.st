"
Represents a note on or off event in a MIDI score.

"
Class {
	#name : #NoteEvent,
	#superclass : #AbstractScoreEvent,
	#instVars : [
		'duration',
		'midiKey',
		'velocity',
		'channel'
	],
	#category : #SoundScores
}

{ #category : #accessing }
NoteEvent >> channel [

	^ channel

]

{ #category : #accessing }
NoteEvent >> channel: midiChannel [

	channel := midiChannel.

]

{ #category : #accessing }
NoteEvent >> duration [

	^ duration

]

{ #category : #accessing }
NoteEvent >> duration: aNumber [

	duration := aNumber.

]

{ #category : #midi }
NoteEvent >> endNoteOnMidiPort: aMidiPort [
	"Output a noteOff event to the given MIDI port. (Actually, output a noteOff event with zero velocity. This does the same thing, but allows running status to be used when sending a mixture of note on and off commands.)"

	aMidiPort
		midiCmd: 16r90
		channel: channel
		byte: midiKey
		byte: 0.

]

{ #category : #accessing }
NoteEvent >> endTime [

	^ time + duration

]

{ #category : #classification }
NoteEvent >> isNoteEvent [

	^ true

]

{ #category : #accessing }
NoteEvent >> key: midiKeyNum velocity: midiVelocity channel: midiChannel [

	midiKey := midiKeyNum.
	velocity := midiVelocity.
	channel := midiChannel.

]

{ #category : #printing }
NoteEvent >> keyName [
	"Return a note name for my pitch."

	| pitchName octave |
	pitchName := #(c cs d ef e f fs g af a bf b) at: (midiKey \\ 12) + 1.
	octave := (#(-1 0 1 2 3 4 5 6 7 8 9) at: (midiKey // 12) + 1) printString.
	^ pitchName, octave

]

{ #category : #accessing }
NoteEvent >> midiKey [

	^ midiKey

]

{ #category : #accessing }
NoteEvent >> midiKey: midiKeyNum [

	midiKey := midiKeyNum.

]

{ #category : #accessing }
NoteEvent >> pitch [
	"Convert my MIDI key number to a pitch and return it."

	^ AbstractSound pitchForMIDIKey: midiKey

]

{ #category : #printing }
NoteEvent >> printOn: aStream [

	aStream nextPut: $(.
	time printOn: aStream.
	aStream nextPutAll: ': '.
	aStream nextPutAll: self keyName.
	aStream space.
	duration printOn: aStream.
	aStream nextPut: $).

]

{ #category : #midi }
NoteEvent >> startNoteOnMidiPort: aMidiPort [
	"Output a noteOn event to the given MIDI port."

	aMidiPort
		midiCmd: 16r90
		channel: channel
		byte: midiKey
		byte: velocity.

]

{ #category : #accessing }
NoteEvent >> velocity [

	^ velocity

]

{ #category : #accessing }
NoteEvent >> velocity: midiVelocity [

	velocity := midiVelocity.

]
