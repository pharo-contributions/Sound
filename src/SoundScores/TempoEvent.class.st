"
Represents a tempo change in a MIDI score.

"
Class {
	#name : #TempoEvent,
	#superclass : #AbstractScoreEvent,
	#instVars : [
		'tempo'
	],
	#category : #'SoundScores-Events'
}

{ #category : #classification }
TempoEvent >> isTempoEvent [

	^ true

]

{ #category : #printing }
TempoEvent >> printOn: aStream [

	aStream nextPut: $(.
	time printOn: aStream.
	aStream nextPutAll: ': tempo '.
	((120.0 * (500000.0 / tempo)) roundTo: 0.01) printOn: aStream.
	aStream nextPut: $).

]

{ #category : #accessing }
TempoEvent >> tempo [

	^ tempo

]

{ #category : #accessing }
TempoEvent >> tempo: anInteger [

	tempo := anInteger.

]
