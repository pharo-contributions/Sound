Extension { #name : #EventRecorderMorph }

{ #category : #'*sound-piano rolls' }
EventRecorderMorph >> addMorphsTo: morphList pianoRoll: pianoRoll eventTime: t betweenTime: leftTime and: rightTime [

	| startX myDurationInTicks endX |

	startX := pianoRoll xForTime: t.
	myDurationInTicks := pianoRoll scorePlayer ticksForMSecs: self myDurationInMS.
	t > rightTime ifTrue: [^ self].  
	(t + myDurationInTicks) < leftTime ifTrue: [^ self].
	endX := pianoRoll xForTime: t + myDurationInTicks.

	morphList add: 
		(self hResizing: #spaceFill; left: startX; width: endX - startX).


]

{ #category : #'*sound' }
EventRecorderMorph >> addVoiceControls [ 

	| levelSlider r meterBox |
	voiceRecorder := SoundRecorder new
		desiredSampleRate: 11025.0;		"<==try real hard to get the low rate"
		codec: (GSMCodec new).		"<--this should compress better than ADPCM.. is it too slow?"
		"codec: (ADPCMCodec new initializeForBitsPerSample: 4 samplesPerFrame: 0)."

	levelSlider := SimpleSliderMorph new
		color: color;
		extent: 100@2;
		target: voiceRecorder;
		actionSelector: #recordLevel:;
		adjustToValue: voiceRecorder recordLevel.
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

	meterBox := Morph new extent: 102@18; color: Color gray.
	recordMeter := Morph new extent: 1@16; color: Color yellow.
	recordMeter position: meterBox topLeft + (1@1).
	meterBox addMorph: recordMeter.

	r := AlignmentMorph newRow vResizing: #shrinkWrap.
	r addMorphBack: meterBox.
	self addMorphBack: r.

]

{ #category : #'*sound-piano rolls' }
EventRecorderMorph >> encounteredAtTime: ticks inScorePlayer: scorePlayer atIndex: index inEventTrack: track secsPerTick: secsPerTick [

	self play.
]

{ #category : #'*sound-piano rolls' }
EventRecorderMorph >> justDroppedIntoPianoRoll: newOwner event: evt [
	
	| startX lengthInTicks endX startTimeInScore endTimeInScore |

	super justDroppedIntoPianoRoll: newOwner event: evt.

	startTimeInScore := newOwner timeForX: self left.
	lengthInTicks := newOwner scorePlayer ticksForMSecs: self myDurationInMS.
	endTimeInScore := startTimeInScore + lengthInTicks.

	endTimeInScore > newOwner scorePlayer durationInTicks ifTrue:
		[newOwner scorePlayer updateDuration].

	startX := newOwner xForTime: startTimeInScore.
	endX := newOwner xForTime: endTimeInScore.
	self width: endX - startX.

]

{ #category : #'*sound-piano rolls' }
EventRecorderMorph >> myDurationInMS [

	^tape isEmptyOrNil ifTrue: [
		10
	] ifFalse: [
		tape last timeStamp - tape first timeStamp
	]

]
