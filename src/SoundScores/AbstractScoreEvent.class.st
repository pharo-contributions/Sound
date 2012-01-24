"
Abstract class for timed events in a MIDI score.

"
Class {
	#name : #AbstractScoreEvent,
	#superclass : #Object,
	#instVars : [
		'time'
	],
	#category : #SoundScores
}

{ #category : #accessing }
AbstractScoreEvent >> adjustTimeBy: delta [

	time := time + delta

]

{ #category : #accessing }
AbstractScoreEvent >> endTime [
	"Subclasses should override to return the ending time if the event has some duration."

	^ time

]

{ #category : #classification }
AbstractScoreEvent >> isControlChange [

	^ false

]

{ #category : #classification }
AbstractScoreEvent >> isNoteEvent [

	^ false

]

{ #category : #classification }
AbstractScoreEvent >> isPitchBend [

	^ false

]

{ #category : #classification }
AbstractScoreEvent >> isProgramChange [

	^ false

]

{ #category : #classification }
AbstractScoreEvent >> isTempoEvent [

	^ false

]

{ #category : #midi }
AbstractScoreEvent >> outputOnMidiPort: aMidiPort [
	"Output this event to the given MIDI port. This default implementation does nothing."

]

{ #category : #accessing }
AbstractScoreEvent >> time [

	^ time

]

{ #category : #accessing }
AbstractScoreEvent >> time: aNumber [

	time := aNumber.

]
