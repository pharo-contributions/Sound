Class {
	#name : #SoundDemoMorph,
	#superclass : #AlignmentMorph,
	#instVars : [
		'soundColumn'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #initialization }
SoundDemoMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 2
]

{ #category : #initialization }
SoundDemoMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color lightGray
]

{ #category : #initialization }
SoundDemoMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	self listDirection: #topToBottom;
		 wrapCentering: #center;
		 cellPositioning: #topCenter;
		 hResizing: #spaceFill;
		 vResizing: #spaceFill;
		 layoutInset: 3;
		 addMorph: self makeControls;
	initializeSoundColumn.
	self extent: 118 @ 150
]

{ #category : #initialization }
SoundDemoMorph >> initializeSoundColumn [
"initialize the receiver's soundColumn"
	soundColumn := AlignmentMorph newColumn.
	soundColumn enableDragNDrop.
	self addMorphBack: soundColumn
]

{ #category : #'as yet unclassified' }
SoundDemoMorph >> makeControls [

	| bb r cc |
	cc := Color black.
	r := AlignmentMorph newRow.
	r color: cc; borderWidth: 0; layoutInset: 0.
	r hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	r addMorphBack: (bb label: 'V1';			actionSelector: #playV1).
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	r addMorphBack: (bb label: 'V2';			actionSelector: #playV2).
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	r addMorphBack: (bb label: 'V3';			actionSelector: #playV3).
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	r addMorphBack: (bb label: 'All';			actionSelector: #playAll).
	bb := SimpleButtonMorph new target: self; borderColor: cc.
	r addMorphBack: (bb label: 'Stop';		actionSelector: #stopSound).
	^ r

]

{ #category : #'as yet unclassified' }
SoundDemoMorph >> playAll [
	| snd |
	soundColumn submorphs isEmpty
		ifTrue: [^ self].
	self setTimbreFromTile: soundColumn submorphs first.
	snd := SampledSound bachFugueVoice1On: SampledSound new.
	soundColumn submorphs size >= 2
		ifTrue: [""self setTimbreFromTile: soundColumn submorphs second.
			snd := snd
						+ (AbstractSound bachFugueVoice2On: SampledSound new)].
	soundColumn submorphs size >= 3
		ifTrue: [""self setTimbreFromTile: soundColumn submorphs third.
			snd := snd
						+ (AbstractSound bachFugueVoice3On: SampledSound new)].
	snd play
]

{ #category : #'as yet unclassified' }
SoundDemoMorph >> playV1 [
	soundColumn submorphs isEmpty
		ifTrue: [^ self].
	self
		setTimbreFromTile: (soundColumn submorphs first).
	(SampledSound bachFugueVoice1On: SampledSound new) play
]

{ #category : #'as yet unclassified' }
SoundDemoMorph >> playV2 [
	soundColumn submorphs size < 2
		ifTrue: [^ self].
	self
		setTimbreFromTile: (soundColumn submorphs second).
	(SampledSound bachFugueVoice2On: SampledSound new) playSilentlyUntil: 4.8;
		 resumePlaying
]

{ #category : #'as yet unclassified' }
SoundDemoMorph >> playV3 [
	soundColumn submorphs size < 3
		ifTrue: [^ self].
	self
		setTimbreFromTile: (soundColumn submorphs third).
	(AbstractSound bachFugueVoice3On: SampledSound new) playSilentlyUntil: 14.4;
		 resumePlaying
]

{ #category : #'as yet unclassified' }
SoundDemoMorph >> setTimbreFromTile: aSoundTile [

	SampledSound defaultSampleTable: aSoundTile sound samples.
	SampledSound nominalSamplePitch: 400.

]

{ #category : #'as yet unclassified' }
SoundDemoMorph >> stopSound [

	SoundPlayer shutDown.

]
