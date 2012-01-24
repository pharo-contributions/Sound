Class {
	#name : #AmbientEvent,
	#superclass : #AbstractScoreEvent,
	#instVars : [
		'morph',
		'target',
		'selector',
		'arguments'
	],
	#category : #SoundScores
}

{ #category : #'as yet unclassified' }
AmbientEvent >> morph [ 
	^ morph
]

{ #category : #'as yet unclassified' }
AmbientEvent >> morph: m [
	morph := m
]

{ #category : #'as yet unclassified' }
AmbientEvent >> occurAtTime: ticks inScorePlayer: player atIndex: index inEventTrack: track secsPerTick: secsPerTick [
	(target isNil or: [selector isNil]) ifTrue:
		[morph ifNil: [^ self].
		^ morph encounteredAtTime: ticks inScorePlayer: player atIndex: index
				inEventTrack: track secsPerTick: secsPerTick].
	target perform: selector withArguments: arguments
]

{ #category : #'as yet unclassified' }
AmbientEvent >> target: t selector: s arguments: a [
	target := t.
	selector := s.
	arguments := a.

]
