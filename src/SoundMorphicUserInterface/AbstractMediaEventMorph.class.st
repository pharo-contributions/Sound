"
An abstract representation of media events to be placed in a PianoRollScoreMorph (or others as they are developed)
"
Class {
	#name : #AbstractMediaEventMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'startTimeInScore',
		'endTimeInScore'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #initialization }
AbstractMediaEventMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 1
]

{ #category : #initialization }
AbstractMediaEventMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color paleYellow
]

{ #category : #'as yet unclassified' }
AbstractMediaEventMorph >> endTime [

	^endTimeInScore ifNil: [startTimeInScore + 100]
]

{ #category : #initialization }
AbstractMediaEventMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	self layoutPolicy: TableLayout new;
	  listDirection: #leftToRight;
	  wrapCentering: #topLeft;
	  hResizing: #shrinkWrap;
	  vResizing: #shrinkWrap;
	  layoutInset: 2;
	  rubberBandCells: true
]
