Class {
	#name : #SoundSequencerMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'controlPanel'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #initialization }
SoundSequencerMorph >> initialize [
	super initialize.
	self extent: 550@350.
	self makeControlPanel.
	self addMorph: controlPanel.
	self addMorph: ((SoundLoopMorph newBounds: (10@40 extent: 128@128)) extent: 128@128).
	self addMorph: ((SoundLoopMorph newBounds: (10@200 extent: 512@128)) extent: 512@128).
]

{ #category : #'as yet unclassified' }
SoundSequencerMorph >> makeControlPanel [
	| bb cc |
	cc := Color black.
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	controlPanel := AlignmentMorph newRow.
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	controlPanel color: bb color; borderWidth: 0; layoutInset: 0.
	controlPanel hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	controlPanel addMorphBack: (bb label: 'reset';	actionSelector: #reset).
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	controlPanel addMorphBack: (bb label: 'stop';		actionSelector: #stop).
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	controlPanel addMorphBack: (bb label: 'play';	actionSelector: #play).

]

{ #category : #'as yet unclassified' }
SoundSequencerMorph >> play [
	self submorphsDo: [:m | m == controlPanel ifFalse: [m play]]
]

{ #category : #'as yet unclassified' }
SoundSequencerMorph >> reset [
	self submorphsDo: [:m | m == controlPanel ifFalse: [m reset]]
]

{ #category : #'stepping and presenter' }
SoundSequencerMorph >> stop [
	self submorphsDo: [:m | m == controlPanel ifFalse: [m stop]].
	SoundPlayer shutDown
]
