"
Represents a tempo change in a MIDI score.

"
Class {
	#name : #TempoEvent,
	#superclass : #AbstractScoreEvent,
	#instVars : [
		'tempo'
	],
	#category : #SoundScores
}

{ #category : #'as yet unclassified' }
TempoEvent >> isTempoEvent [

	^ true

]

{ #category : #'as yet unclassified' }
TempoEvent >> printOn: aStream [

	aStream nextPut: $(.
	time printOn: aStream.
	aStream nextPutAll: ': tempo '.
	((120.0 * (500000.0 / tempo)) roundTo: 0.01) printOn: aStream.
	aStream nextPut: $).

]

{ #category : #'as yet unclassified' }
TempoEvent >> tempo [

	^ tempo

]

{ #category : #'as yet unclassified' }
TempoEvent >> tempo: anInteger [

	tempo := anInteger.

]
