"
A BusySignal is a simple sound.


(BusySignal count: 3) play
"
Class {
	#name : #BusySignal,
	#superclass : #FMSound,
	#category : #'Sound-Synthesis'
}

{ #category : #'instance creation' }
BusySignal class >> count: count [
	"self new count: 3"
	
	^ self new count: 3; yourself
	
]

{ #category : #'as yet unclassified' }
BusySignal >> count:  aNumber [

	count := aNumber.
	self recalculate. 
]

{ #category : #'as yet unclassified' }
BusySignal >> recalculate [

	| m s |
	s := SequentialSound new.
	m := MixedSound new.
	m	add: (FMSound new setPitch: 480 dur: 0.5 loudness: 0.5);
		add: (FMSound new setPitch: 620 dur: 0.5 loudness: 0.5).
	s add: m.
	s add: (FMSound new setPitch: 1 dur: 0.5 loudness: 0).
	^ (RepeatingSound repeat: s count: count).

]
