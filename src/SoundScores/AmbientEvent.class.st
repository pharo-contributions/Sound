Class {
	#name : #AmbientEvent,
	#superclass : #AbstractScoreEvent,
	#instVars : [
		'morph',
		'target',
		'selector',
		'arguments'
	],
	#category : #'SoundScores-Events'
}

{ #category : #accessing }
AmbientEvent >> morph [ 
	^ morph
]

{ #category : #accessing }
AmbientEvent >> morph: m [
	morph := m
]

{ #category : #action }
AmbientEvent >> occurAtTime: ticks inScorePlayer: player atIndex: index inEventTrack: track secsPerTick: secsPerTick [
	(target isNil or: [selector isNil]) ifTrue:
		[morph ifNil: [^ self].
		^ morph encounteredAtTime: ticks inScorePlayer: player atIndex: index
				inEventTrack: track secsPerTick: secsPerTick].
	target perform: selector withArguments: arguments
]

{ #category : #accessing }
AmbientEvent >> target: t selector: s arguments: a [
	target := t.
	selector := s.
	arguments := a.

]
