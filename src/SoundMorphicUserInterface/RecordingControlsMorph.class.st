Class {
	#name : 'RecordingControlsMorph',
	#superclass : 'AlignmentMorph',
	#instVars : [
		'recorder',
		'recordingStatusLight',
		'recordMeter'
	],
	#category : 'SoundMorphicUserInterface',
	#package : 'SoundMorphicUserInterface'
}

{ #category : 'parts bin' }
RecordingControlsMorph class >> descriptionForPartsBin [
	^ self partName:	'SoundRecorder'
		categories:		#('Multimedia')
		documentation:	'A device for making sound recordings.'
]

{ #category : 'initialization' }
RecordingControlsMorph class >> registerInFlapsRegistry [
	"Register the receiver in the system's flaps registry"
	self environment
		at: #Flaps
		ifPresent: [:cl | cl registerQuad: #(RecordingControlsMorph	authoringPrototype	'Sound' 	'A device for making sound recordings.')
						forFlapNamed: 'PlugIn Supplies'.
						cl registerQuad: #(RecordingControlsMorph	authoringPrototype	'Sound' 	'A device for making sound recordings.')
						forFlapNamed: 'Widgets'.]
]

{ #category : 'initialization' }
RecordingControlsMorph >> addButtonRows [

	| r |
	r := AlignmentMorph newRow vResizing: #shrinkWrap.
	r addMorphBack: (self buttonName: 'Morph' translated action: #makeSoundMorph).
	r addMorphBack: (Morph new extent: 4@1; color: Color transparent).
	r addMorphBack: (self buttonName: 'Trim' translated action: #trim).
	r addMorphBack: (Morph new extent: 4@1; color: Color transparent).
	r addMorphBack: (self buttonName: 'Show' translated action: #show).
	self addMorphBack: r.

	r := AlignmentMorph newRow vResizing: #shrinkWrap.
	r addMorphBack: (self buttonName: 'Record' translated action: #record).
	r addMorphBack: (Morph new extent: 4@1; color: Color transparent).
	r addMorphBack: (self buttonName: 'Stop' translated action: #stop).
	r addMorphBack: (Morph new extent: 4@1; color: Color transparent).
	r addMorphBack: (self buttonName: 'Play' translated action: #playback).
	r addMorphBack: self makeStatusLight.
	self addMorphBack: r.

]

{ #category : 'other' }
RecordingControlsMorph >> addRecordLevelSlider [

	| levelSlider r |
	levelSlider := PluggableSliderMorph new
		color: color;
		extent: 100@2;
		model: recorder;
		setValueSelector: #recordLevel:;
		setValue: recorder recordLevel.
	r := AlignmentMorph newRow
		color: color;
		layoutInset: 0;
		wrapCentering: #center; cellPositioning: #leftCenter;
		hResizing: #shrinkWrap;
		vResizing: #rigid;
		height: 24.
	r addMorphBack: (StringMorph contents: '0 ').
	r addMorphBack: levelSlider.
	r addMorphBack: (StringMorph contents: ' 10').
	self addMorphBack: r.

]

{ #category : 'other' }
RecordingControlsMorph >> buttonName: aString action: aSymbol [

	^ SimpleButtonMorph new
		target: self;
		label: aString;
		actionSelector: aSymbol

]

{ #category : 'button commands' }
RecordingControlsMorph >> done [

	recorder stopRecording.
	self delete.

]

{ #category : 'initialization' }
RecordingControlsMorph >> initialize [

	| r |
	super initialize.
	self hResizing: #shrinkWrap; vResizing: #shrinkWrap.
	borderWidth := 2.
	self listDirection: #topToBottom.
	recorder := SoundRecorder new startRecording.
	self addButtonRows.
	self addRecordLevelSlider.

	r := AlignmentMorph newRow vResizing: #shrinkWrap.
	r addMorphBack: self makeRecordMeter.
	self addMorphBack: r.
	self extent: 10@10.  "make minimum size"

]

{ #category : 'other' }
RecordingControlsMorph >> makeRecordMeter [

	| outerBox |
	outerBox := Morph new extent: 102@18; color: Color gray.
	recordMeter := Morph new extent: 1@16; color: Color yellow.
	recordMeter position: outerBox topLeft + (1@1).
	outerBox addMorph: recordMeter.
	^ outerBox

]

{ #category : 'button commands' }
RecordingControlsMorph >> makeSoundMorph [

	| m |
	recorder verifyExistenceOfRecordedSound ifFalse: [^ self].

	recorder pause.
	m := SoundEventMorph new sound: recorder recordedSound.
	self world firstHand attachMorph: m.

]

{ #category : 'other' }
RecordingControlsMorph >> makeStatusLight [

	recordingStatusLight := Morph new extent: 18@18.
	recordingStatusLight color: Color transparent.
	^ recordingStatusLight

]

{ #category : 'button commands' }
RecordingControlsMorph >> playback [
	"The user hit the playback button"

	recorder verifyExistenceOfRecordedSound ifFalse: [^ self].
	recorder pause.
	recorder playback.

]

{ #category : 'button commands' }
RecordingControlsMorph >> record [

	recorder clearRecordedSound.
	recorder resumeRecording.

]

{ #category : 'accessing' }
RecordingControlsMorph >> recorder [

	^ recorder

]

{ #category : 'button commands' }
RecordingControlsMorph >> show [
	"Show my samples in a WaveEditor."

	| ed w |
	recorder verifyExistenceOfRecordedSound ifFalse: [^ self].
	recorder pause.
	ed := WaveEditor new.
	ed data: recorder condensedSamples.
	ed samplingRate: recorder samplingRate.
	w := self world.
	w activeHand
		ifNil: [w addMorph: ed]
		ifNotNil: [w activeHand attachMorph: ed].


]

{ #category : 'stepping and presenter' }
RecordingControlsMorph >> startStepping [
	"Make the level meter active when dropped into the world. Do nothing if already recording. Note that this will cause other recorders to stop recording..."

	super startStepping.
	recorder isPaused ifTrue: [
		SoundRecorder allSubInstancesDo: [:r | r stopRecording].  "stop all other sound recorders"
		recorder pause].  "meter is updated while paused"

]

{ #category : 'stepping and presenter' }
RecordingControlsMorph >> step [

	recorder isPaused
		ifTrue: [recordingStatusLight color: Color transparent]
		ifFalse: [recordingStatusLight color: Color red].
	recordMeter extent: (recorder meterLevel + 1) @ recordMeter height.

]

{ #category : 'testing' }
RecordingControlsMorph >> stepTime [

	^ 50

]

{ #category : 'stepping and presenter' }
RecordingControlsMorph >> stop [

	recorder pause.

]

{ #category : 'stepping and presenter' }
RecordingControlsMorph >> stopStepping [
	"Turn off recording."

	super stopStepping.
	recorder stopRecording.

]

{ #category : 'button commands' }
RecordingControlsMorph >> trim [
	"Show my samples in a GraphMorph."
	
	recorder verifyExistenceOfRecordedSound ifFalse: [^ self].
	recorder pause.
	recorder trim: 1400 normalizedVolume: 80.0.

]
