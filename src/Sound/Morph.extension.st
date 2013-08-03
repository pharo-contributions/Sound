Extension { #name : #Morph }

{ #category : #'*sound-piano rolls' }
Morph >> addMorphsTo: morphList pianoRoll: pianoRoll eventTime: t betweenTime: leftTime and: rightTime [

	"a hack to allow for abitrary morphs to be dropped into piano roll"
	t > rightTime ifTrue: [^ self].  
	t < leftTime ifTrue: [^ self].
	morphList add: (self left: (pianoRoll xForTime: t)).

]

{ #category : #'*sound-piano rolls' }
Morph >> encounteredAtTime: ticks inScorePlayer: scorePlayer atIndex: index inEventTrack: track secsPerTick: secsPerTick [

	"a hack to allow for abitrary morphs to be dropped into piano roll"
	self triggerActionFromPianoRoll.
]

{ #category : #'*sound-piano rolls' }
Morph >> justDroppedIntoPianoRoll: pianoRoll event: evt [
	
	| ambientEvent startTimeInScore |
	startTimeInScore := pianoRoll timeForX: self left.

	ambientEvent := AmbientEvent new 
		morph: self;
		time: startTimeInScore.

	pianoRoll score addAmbientEvent: ambientEvent.

	"self endTime > pianoRoll scorePlayer durationInTicks ifTrue:
		[pianoRoll scorePlayer updateDuration]"

]

{ #category : #'*sound-piano rolls' }
Morph >> pauseFrom: scorePlayer [

	"subclasses should take five"
]

{ #category : #'*sound-piano rolls' }
Morph >> resetFrom: scorePlayer [

	"subclasses should revert to their initial state"
]

{ #category : #'*sound-piano rolls' }
Morph >> resumeFrom: scorePlayer [

	"subclasses should continue from their current position"
	"a hack to allow for abitrary morphs to be dropped into piano roll"
]

{ #category : #'*sound-piano rolls' }
Morph >> triggerActionFromPianoRoll [

	| evt |
	"a hack to allow for abitrary morphs to be dropped into piano roll"
	self world ifNil: [^self].
	evt := MouseEvent basicNew setType: nil position: self center buttons: 0 hand: self world activeHand.
	self programmedMouseUp: evt for: self.


]
