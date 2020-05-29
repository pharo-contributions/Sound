Class {
	#name : #SoundEventMorph,
	#superclass : #AbstractMediaEventMorph,
	#instVars : [
		'sound'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #'piano rolls' }
SoundEventMorph >> addMorphsTo: morphList pianoRoll: pianoRoll eventTime: t betweenTime: leftTime and: rightTime [

	| startX lengthInTicks endX |

	startTimeInScore > rightTime ifTrue: [^ self].  
	lengthInTicks := pianoRoll scorePlayer ticksForMSecs: sound duration * 1000.0.
	startTimeInScore + lengthInTicks < leftTime ifTrue: [^ self].
	startX := pianoRoll xForTime: startTimeInScore.
	endX := pianoRoll xForTime: startTimeInScore + lengthInTicks.
	morphList add: 
		(self left: startX; width: endX - startX).


]

{ #category : #initialization }
SoundEventMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color lightGreen
]

{ #category : #'piano rolls' }
SoundEventMorph >> encounteredAtTime: ticks inScorePlayer: scorePlayer atIndex: index inEventTrack: track secsPerTick: secsPerTick [

	"hack... since we are called from within the SoundPlayer loop, the Semaphore will
	block attempts to play directly from here"
	WorldState addDeferredUIMessage: [sound play].
]

{ #category : #initialization }
SoundEventMorph >> initialize [
"initialize the state of the receiver"
	super initialize.
""
	self height: 10
]

{ #category : #'piano rolls' }
SoundEventMorph >> justDroppedIntoPianoRoll: newOwner event: evt [
	
	| startX lengthInTicks endX |

	super justDroppedIntoPianoRoll: newOwner event: evt.

	startTimeInScore := newOwner timeForX: self left.
	lengthInTicks := newOwner scorePlayer ticksForMSecs: sound duration * 1000.0.
	endTimeInScore := startTimeInScore + lengthInTicks.

	endTimeInScore > newOwner scorePlayer durationInTicks ifTrue:
		[newOwner scorePlayer updateDuration].

	startX := newOwner xForTime: startTimeInScore.
	endX := newOwner xForTime: endTimeInScore.
	self width: endX - startX.


]

{ #category : #caching }
SoundEventMorph >> releaseCachedState [

	super releaseCachedState.
	sound := sound compressWith: GSMCodec.

]

{ #category : #accessing }
SoundEventMorph >> sound: aSound [

	sound := aSound.
	self setBalloonText: 'a sound of duration ',(sound duration roundTo: 0.1) printString,' seconds'.
]
