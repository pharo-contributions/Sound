"
A BusySignal is a simple sound.


(BusySignal count: 3) play
"
Class {
	#name : #BusySignal,
	#superclass : #FMSound,
	#category : #'Sound-Core'
}

{ #category : #'instance creation' }
BusySignal class >> count: count [
	"self new count: 3"
	
	^ self new count: 3; yourself
	
]

{ #category : #accessing }
BusySignal >> count:  aNumber [

	count := aNumber.
	self recalculate. 
]

{ #category : #operation }
BusySignal >> recalculate [

	| m s |
	s := SequentialSound new.
	m := MixedSound new.
	m	add: (FMSound pitch: 480 duration: 0.5 loudness: 0.5);
		add: (FMSound pitch: 620 duration: 0.5 loudness: 0.5).
	s add: m.
	s add: (FMSound pitch: 1 duration: 0.5 loudness: 0).
	^ (RepeatingSound repeat: s count: count).

]
