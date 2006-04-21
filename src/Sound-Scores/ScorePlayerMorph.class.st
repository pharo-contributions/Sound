"
A ScorePlayerMorph mediates between a score such as a MIDIScore, a PianoRollScoreMorph, and the actual SoundPlayer synthesizer.

It provides control over volume, tempo, instrumentation, and location in the score.
"
Class {
	#name : #ScorePlayerMorph,
	#superclass : #AlignmentMorph,
	#instVars : [
		'scorePlayer',
		'trackInstNames',
		'instrumentSelector',
		'scrollSlider'
	],
	#classVars : [
		'LastMIDIPort'
	],
	#category : #'Sound-Scores'
}

{ #category : #'parts bin' }
ScorePlayerMorph class >> descriptionForPartsBin [
	^ self partName: 	'ScorePlayer'
		categories:		#('Multimedia')
		documentation:	' Mediates between a score such as a MIDIScore, a PianoRollScoreMorph, and the actual SoundPlayer synthesizer'
]

{ #category : #'fileIn/Out' }
ScorePlayerMorph class >> fileReaderServicesForFile: fullName suffix: suffix [

	^(suffix = 'mid') | (suffix = '*') 
		ifTrue: [ self services]
		ifFalse: [#()]

]

{ #category : #'class initialization' }
ScorePlayerMorph class >> initialize [

	FileList registerFileReader: self
]

{ #category : #'system hookup' }
ScorePlayerMorph class >> onMIDIFileNamed: fileName [
	"Return a ScorePlayerMorph on the score from the MIDI file of the given name."

	| score player |
	score := MIDIFileReader scoreFromFileNamed: fileName	.
	player := ScorePlayer onScore: score.
	^ self new onScorePlayer: player title: fileName

]

{ #category : #'system hookup' }
ScorePlayerMorph class >> openOn: aScore title: aString [

	| player |
	player := ScorePlayer onScore: aScore.
	(self new onScorePlayer: player title: aString) openInWorld.

]

{ #category : #'class initialization' }
ScorePlayerMorph class >> playMidiFile: fullName [
	"Play a MIDI file."
 
	| f score |
	Smalltalk at: #MIDIFileReader ifPresent: [:midiReader |
			f := (FileStream oldFileNamed: fullName) binary.
			score := (midiReader new readMIDIFrom: f) asScore.
			f close.
			self openOn: score title: (FileDirectory localNameFor: fullName)]

]

{ #category : #'class initialization' }
ScorePlayerMorph class >> servicePlayMidiFile [
	"Answer a service for opening player on a midi file"

	^ SimpleServiceEntry 
		provider: self 
		label: 'open in midi player'
		selector: #playMidiFile:
		description: 'open the midi-player tool on this file'
		buttonLabel: 'open'
]

{ #category : #'fileIn/Out' }
ScorePlayerMorph class >> services [

	^ Array with: self servicePlayMidiFile

	
]

{ #category : #'initialize-release' }
ScorePlayerMorph class >> unload [

	FileList unregisterFileReader: self 
]

{ #category : #controls }
ScorePlayerMorph >> atTrack: trackIndex from: aPopUpChoice selectInstrument: selection [ 
	| oldSnd name snd |
	oldSnd := scorePlayer instrumentForTrack: trackIndex.
	(selection beginsWith: 'edit ') 
		ifTrue: 
			[name := selection copyFrom: 6 to: selection size.
			aPopUpChoice contentsClipped: name.
			(oldSnd isKindOf: FMSound) | (oldSnd isKindOf: LoopedSampledSound) 
				ifTrue: [EnvelopeEditorMorph openOn: oldSnd title: name].
			(oldSnd isKindOf: SampledInstrument) 
				ifTrue: [EnvelopeEditorMorph openOn: oldSnd allNotes first title: name].
			^self].
	snd := nil.
	1 to: instrumentSelector size
		do: 
			[:i | 
			(trackIndex ~= i and: [selection = (instrumentSelector at: i) contents]) 
				ifTrue: [snd := scorePlayer instrumentForTrack: i]].	"use existing instrument prototype"
	snd ifNil: 
			[snd := (selection = 'clink' 
				ifTrue: 
					[(SampledSound samples: SampledSound coffeeCupClink
								samplingRate: 11025) ]
				ifFalse: [(AbstractSound soundNamed: selection)]) copy].
	scorePlayer instrumentForTrack: trackIndex put: snd.
	(instrumentSelector at: trackIndex) contentsClipped: selection
]

{ #category : #initialization }
ScorePlayerMorph >> closeMIDIPort [

	scorePlayer closeMIDIPort.
	LastMIDIPort := nil.

]

{ #category : #initialization }
ScorePlayerMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 2
]

{ #category : #initialization }
ScorePlayerMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color veryLightGray
]

{ #category : #initialization }
ScorePlayerMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	self listDirection: #topToBottom;
		 wrapCentering: #center;
		 cellPositioning: #topCenter;
		 hResizing: #shrinkWrap;
		 vResizing: #shrinkWrap;
		 layoutInset: 3;
		 onScorePlayer: ScorePlayer new initialize title: ' ';
		 extent: 20 @ 20 
]

{ #category : #menu }
ScorePlayerMorph >> instrumentChoicesForTrack: trackIndex [
	| names inst |

	names := AbstractSound soundNames asOrderedCollection.
	names := names collect: [:n |
		inst := AbstractSound soundNamed: n.
		(inst isKindOf: UnloadedSound)
			ifTrue: [n, '(out)']
			ifFalse: [n]].
	names add: 'clink'.
	names add: 'edit ', (instrumentSelector at: trackIndex) contents.
	^ names asArray

]

{ #category : #menu }
ScorePlayerMorph >> invokeMenu [
	"Invoke a menu of additonal functions for this ScorePlayer."

	| aMenu |
	aMenu := MenuMorph new defaultTarget: self.
	aMenu add: 'open a MIDI file' translated action: #openMIDIFile.
	aMenu addList: {
		#-.
		{'save as AIFF file' translated.	#saveAsAIFF}.
		{'save as WAV file' translated.		#saveAsWAV}.
		{'save as Sun AU file' translated.	#saveAsSunAudio}.
		#-}.
	aMenu add: 'reload instruments' translated target: AbstractSound selector: #updateScorePlayers.
	aMenu addLine.
	scorePlayer midiPort
		ifNil: [
			aMenu add: 'play via MIDI' translated action: #openMIDIPort]
		ifNotNil: [
			aMenu add: 'play via built in synth' translated action: #closeMIDIPort.
			aMenu add: 'new MIDI controller' translated action: #makeMIDIController:].
	aMenu addLine.
	aMenu add: 'make a pause marker' translated action: #makeAPauseEvent:.

	aMenu popUpInWorld: self world.

]

{ #category : #menu }
ScorePlayerMorph >> makeAPauseEvent: evt [

	| newWidget |

	newWidget := AlignmentMorph newRow.
	newWidget 
		color: Color orange; 
		borderWidth: 0; 
		layoutInset: 0;
		hResizing: #shrinkWrap; 
		vResizing: #shrinkWrap; 
		extent: 5@5;
		addMorph: (StringMorph contents: '[pause]' translated) lock;
		addMouseUpActionWith: (
			MessageSend receiver: self selector: #showResumeButtonInTheWorld
		).

	evt hand attachMorph: newWidget.
]

{ #category : #layout }
ScorePlayerMorph >> makeControls [

	| bb r reverbSwitch repeatSwitch |
	r := AlignmentMorph newRow.
	r color: color; borderWidth: 0; layoutInset: 0.
	r hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	bb := SimpleButtonMorph new target: self; borderColor: #raised;
			borderWidth: 2; color: color.
	r addMorphBack: (bb label: '<>'; actWhen: #buttonDown;
												actionSelector: #invokeMenu).
	bb := SimpleButtonMorph new target: self; borderColor: #raised;
			borderWidth: 2; color: color.
	r addMorphBack: (bb label: 'Piano Roll' translated;		actionSelector: #makePianoRoll).
	bb := SimpleButtonMorph new target: self; borderColor: #raised;
			borderWidth: 2; color: color.
	r addMorphBack: (bb label: 'Rewind' translated;		actionSelector: #rewind).
	bb := SimpleButtonMorph new target: scorePlayer; borderColor: #raised;
			borderWidth: 2; color: color.
	r addMorphBack: (bb label: 'Play' translated;			actionSelector: #resumePlaying).
	bb := SimpleButtonMorph new target: scorePlayer; borderColor: #raised;
			borderWidth: 2; color: color.
	r addMorphBack: (bb label: 'Pause' translated;			actionSelector: #pause).
	reverbSwitch := SimpleSwitchMorph new
		offColor: color;
		onColor: (Color r: 1.0 g: 0.6 b: 0.6);
		borderWidth: 2;
		label: 'Reverb Disable' translated;
		actionSelector: #disableReverb:;
		target: scorePlayer;
		setSwitchState: SoundPlayer isReverbOn not.
	r addMorphBack: reverbSwitch.
	scorePlayer ifNotNil:
		[repeatSwitch := SimpleSwitchMorph new
			offColor: color;
			onColor: (Color r: 1.0 g: 0.6 b: 0.6);
			borderWidth: 2;
			label: 'Repeat' translated;
			actionSelector: #repeat:;
			target: scorePlayer;
			setSwitchState: scorePlayer repeat.
		r addMorphBack: repeatSwitch].
	^ r

]

{ #category : #layout }
ScorePlayerMorph >> makeMIDIController: evt [

	self world activeHand attachMorph:
		(MIDIControllerMorph new midiPort: scorePlayer midiPort).

]

{ #category : #layout }
ScorePlayerMorph >> makePianoRoll [
	"Create a piano roll viewer for this score player."

	| pianoRoll hand |
	pianoRoll := PianoRollScoreMorph new on: scorePlayer.
	hand := self world activeHand.
	hand ifNil: [self world addMorph: pianoRoll]
		ifNotNil: [hand attachMorph: pianoRoll.
				hand lastEvent shiftPressed ifTrue:
					["Special case for NOBM demo"
					pianoRoll contractTime; contractTime; enableDragNDrop]].
	pianoRoll startStepping.

]

{ #category : #layout }
ScorePlayerMorph >> makeRow [

	^ AlignmentMorph newRow
		color: color;
		layoutInset: 0;
		wrapCentering: #center; cellPositioning: #leftCenter;
		hResizing: #spaceFill;
		vResizing: #shrinkWrap

]

{ #category : #initialization }
ScorePlayerMorph >> onScorePlayer: aScorePlayer title: scoreName [
	| divider col r |
	scorePlayer := aScorePlayer.
	scorePlayer ifNotNil:
		[scorePlayer  reset.
		instrumentSelector := Array new: scorePlayer score tracks size].

	self removeAllMorphs.
	self addMorphBack: self makeControls.
	scorePlayer ifNil: [^ self].

	r := self makeRow
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap.
	r addMorphBack: self rateControl;
		addMorphBack: (Morph newBounds: (0@0 extent: 20@0) color: Color transparent);
		addMorphBack: self volumeControl.
	self addMorphBack: r.
	self addMorphBack: self scrollControl.

	col := AlignmentMorph newColumn color: color; layoutInset: 0.
	self addMorphBack: col.
	1 to: scorePlayer trackCount do: [:trackIndex |
		divider := AlignmentMorph new
			extent: 10@1;
			borderWidth: 1;
			layoutInset: 0;
			borderColor: #raised;
			color: color;
			hResizing: #spaceFill;
			vResizing: #rigid.
		col addMorphBack: divider.
		col addMorphBack: (self trackControlsFor: trackIndex)].

	LastMIDIPort ifNotNil: [
		"use the most recently set MIDI port"
		scorePlayer openMIDIPort: LastMIDIPort].

]

{ #category : #initialization }
ScorePlayerMorph >> openMIDIFile [
	"Open a MIDI score and re-init controls..."
	| score fileName f player |
	fileName := Utilities chooseFileWithSuffixFromList: #('.mid' '.midi')
					withCaption: 'Choose a MIDI file to open' translated.
	(fileName isNil or: [ fileName == #none ])
		ifTrue: [^ self inform: 'No .mid/.midi files found in the Squeak directory' translated].
	f := FileStream readOnlyFileNamed: fileName.
	score := (MIDIFileReader new readMIDIFrom: f binary) asScore.
	f close.
	player := ScorePlayer onScore: score.
	self onScorePlayer: player title: fileName
]

{ #category : #initialization }
ScorePlayerMorph >> openMIDIPort [

	| portNum |
	portNum := SimpleMIDIPort outputPortNumFromUser.
	portNum ifNil: [^ self].
	scorePlayer openMIDIPort: portNum.
	LastMIDIPort := portNum.

]

{ #category : #layout }
ScorePlayerMorph >> panAndVolControlsFor: trackIndex [

	| volSlider panSlider c r middleLine pianoRollColor |
	pianoRollColor := (Color wheel: scorePlayer score tracks size) at: trackIndex.
	volSlider := SimpleSliderMorph new
		color: color;
		sliderColor: pianoRollColor;
		extent: 101@2;
		target: scorePlayer;
		arguments: (Array with: trackIndex);
		actionSelector: #volumeForTrack:put:;
		minVal: 0.0;
		maxVal: 1.0;
		adjustToValue: (scorePlayer volumeForTrack: trackIndex).
	panSlider := SimpleSliderMorph new
		color: color;
		sliderColor: pianoRollColor;
		extent: 101@2;
		target: scorePlayer;
		arguments: (Array with: trackIndex);
		actionSelector: #panForTrack:put:;
		minVal: 0.0;
		maxVal: 1.0;		
		adjustToValue: (scorePlayer panForTrack: trackIndex).
	c := AlignmentMorph newColumn
		color: color;
		layoutInset: 0;
		wrapCentering: #center; cellPositioning: #topCenter;
		hResizing: #spaceFill;
		vResizing: #shrinkWrap.
	middleLine := Morph new  "center indicator for pan slider"
		color: (Color r: 0.4 g: 0.4 b: 0.4);
		extent: 1@(panSlider height - 4);
		position: panSlider center x@(panSlider top + 2).
	panSlider addMorphBack: middleLine.
	r := self makeRow.
	r addMorphBack: (StringMorph contents: '0').
	r addMorphBack: volSlider.
	r addMorphBack: (StringMorph contents: '10').
	c addMorphBack: r.
	r := self makeRow.
	r addMorphBack: (StringMorph contents: 'L' translated).
	r addMorphBack: panSlider.
	r addMorphBack: (StringMorph contents: 'R' translated).
	c addMorphBack: r.
	^ c

]

{ #category : #layout }
ScorePlayerMorph >> rateControl [

	| rateSlider middleLine r |
	rateSlider := SimpleSliderMorph new
		color: color;
		sliderColor: Color gray;
		extent: 180@2;
		target: self;
		actionSelector: #setLogRate:;
		minVal: -1.0;
		maxVal: 1.0;
		adjustToValue: 0.0.
	middleLine := Morph new  "center indicator for pan slider"
		color: (Color r: 0.4 g: 0.4 b: 0.4);
		extent: 1@(rateSlider height - 4);
		position: rateSlider center x@(rateSlider top + 2).
	rateSlider addMorphBack: middleLine.
	r := self makeRow
		hResizing: #shrinkWrap;
		vResizing: #rigid;
		height: 24.
	r addMorphBack: (StringMorph contents: 'slow ' translated).
	r addMorphBack: rateSlider.
	r addMorphBack: (StringMorph contents: ' fast' translated).
	^ r

]

{ #category : #controls }
ScorePlayerMorph >> rewind [

	scorePlayer pause; reset.

]

{ #category : #menu }
ScorePlayerMorph >> saveAsAIFF [
	"Create a stereo AIFF audio file with the result of performing my score."

	| fileName |
	fileName := FillInTheBlank request: 'New file name?' translated.
	fileName isEmpty ifTrue: [^ self].
	(fileName asLowercase endsWith: '.aif') ifFalse: [
		fileName := fileName, '.aif'].

	scorePlayer storeAIFFOnFileNamed: fileName.

]

{ #category : #menu }
ScorePlayerMorph >> saveAsSunAudio [
	"Create a stereo Sun audio file with the result of performing my score."

	| fileName |
	fileName := FillInTheBlank request: 'New file name?' translated.
	fileName isEmpty ifTrue: [^ self].
	(fileName asLowercase endsWith: '.au') ifFalse: [
		fileName := fileName, '.au'].

	scorePlayer storeSunAudioOnFileNamed: fileName.

]

{ #category : #menu }
ScorePlayerMorph >> saveAsWAV [
	"Create a stereo WAV audio file with the result of performing my score."

	| fileName |
	fileName := FillInTheBlank request: 'New file name?' translated.
	fileName isEmpty ifTrue: [^ self].
	(fileName asLowercase endsWith: '.wav') ifFalse: [
		fileName := fileName, '.wav'].

	scorePlayer storeWAVOnFileNamed: fileName.

]

{ #category : #accessing }
ScorePlayerMorph >> scorePlayer [

	^ scorePlayer

]

{ #category : #layout }
ScorePlayerMorph >> scrollControl [

	| r |
	scrollSlider := SimpleSliderMorph new
		color: color;
		sliderColor: Color gray;
		extent: 360@2;
		target: scorePlayer;
		actionSelector: #positionInScore:;
		adjustToValue: scorePlayer positionInScore.
	r := self makeRow
		hResizing: #shrinkWrap;
		vResizing: #rigid;
		height: 24.
	r addMorphBack: (StringMorph contents: 'start ' translated).
	r addMorphBack: scrollSlider.
	r addMorphBack: (StringMorph contents: ' end' translated).
	^ r

]

{ #category : #controls }
ScorePlayerMorph >> setLogRate: logOfRate [

	scorePlayer rate: (3.5 raisedTo: logOfRate).

]

{ #category : #layout }
ScorePlayerMorph >> showResumeButtonInTheWorld [

	| w |

	WorldState addDeferredUIMessage: [
		w := self world.
		w ifNotNil: [
			w addMorphFront:
				(self standaloneResumeButton position: (w right - 100) @ (w top + 10)).
			scorePlayer pause.
			].
	]

]

{ #category : #layout }
ScorePlayerMorph >> standaloneResumeButton [

	| r |

	r := AlignmentMorph newRow.
	r color: Color red; borderWidth: 0; layoutInset: 6; useRoundedCorners.
	r hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	r addMorphBack: (
		SimpleButtonMorph new
			target: [
				scorePlayer resumePlaying.
				r delete
			];
			borderColor: #raised;
			borderWidth: 2;
			color: Color green;
			label: 'Continue' translated;
			actionSelector: #value
	).
	r setBalloonText: 'Continue playing a paused presentation' translated.
	^r



]

{ #category : #'stepping and presenter' }
ScorePlayerMorph >> step [

	scrollSlider adjustToValue: scorePlayer positionInScore.


]

{ #category : #layout }
ScorePlayerMorph >> trackControlsFor: trackIndex [

	| r |
	r := self makeRow
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap.
	r addMorphBack: (self trackNumAndMuteButtonFor: trackIndex).
	r addMorphBack: (Morph new extent: 10@5; color: color).  "spacer"
	r addMorphBack: (self panAndVolControlsFor: trackIndex).
	^ r

]

{ #category : #layout }
ScorePlayerMorph >> trackNumAndMuteButtonFor: trackIndex [

	| muteButton instSelector pianoRollColor r |
	muteButton := SimpleSwitchMorph new
		onColor: (Color r: 1.0 g: 0.6 b: 0.6);
		offColor: color;
		color: color;
		label: 'Mute' translated;
		target: scorePlayer;
		actionSelector: #mutedForTrack:put:;
		arguments: (Array with: trackIndex).
	instSelector := PopUpChoiceMorph new
		extent: 95@14;
		contentsClipped: 'oboe1';
		target: self;
		actionSelector: #atTrack:from:selectInstrument:;
		getItemsSelector: #instrumentChoicesForTrack:;
		getItemsArgs: (Array with: trackIndex).
	instSelector arguments:
		(Array with: trackIndex with: instSelector).
	instrumentSelector at: trackIndex put: instSelector.

	"select track color using same color list as PianoRollScoreMorph"
	pianoRollColor := (Color wheel: scorePlayer score tracks size) at: trackIndex.

	r := self makeRow
		hResizing: #rigid;
		vResizing: #spaceFill;
		extent: 70@10.
	r addMorphBack:
		((StringMorph
			contents: trackIndex printString
			font: (TextStyle default fontOfSize: 24)) color: pianoRollColor).
	trackIndex < 10
		ifTrue: [r addMorphBack: (Morph new color: color; extent: 19@8)]  "spacer"
		ifFalse: [r addMorphBack: (Morph new color: color; extent: 8@8)].  "spacer"
	r addMorphBack:
		(StringMorph new
			extent: 140@14;
			contentsClipped: (scorePlayer infoForTrack: trackIndex)).
	r addMorphBack: (Morph new color: color; extent: 8@8).  "spacer"
	r addMorphBack: instSelector.
	r addMorphBack: (AlignmentMorph newRow color: color).  "spacer"
	r addMorphBack: muteButton.
	^ r

]

{ #category : #menu }
ScorePlayerMorph >> updateInstrumentsFromLibraryExcept: soundsBeingEdited [
	"The instrument library has been modified. Update my instruments with the new versions from the library. Use a single instrument prototype for all parts with the same name; this allows the envelope editor to edit all the parts by changing a single sound prototype."

	"soundsBeingEdited is a collection of sounds being edited (by an EnvelopeEditor).  If any of my instruments share one of these, then they will be left alone so as not to disturb that dynamic linkage."

	| unloadPostfix myInstruments name displaysAsUnloaded isUnloaded |
	unloadPostfix := '(out)'.
	myInstruments := Dictionary new.
	1 to: instrumentSelector size do: [:i |
		name := (instrumentSelector at: i) contents.
		displaysAsUnloaded := name endsWith: unloadPostfix.
		displaysAsUnloaded ifTrue: [
			name := name copyFrom: 1 to: name size - unloadPostfix size].
		(myInstruments includesKey: name) ifFalse: [
			myInstruments at: name put:
				(name = 'clink'
					ifTrue: [
						(SampledSound
							samples: SampledSound coffeeCupClink
							samplingRate: 11025) copy]
					ifFalse: [
						(AbstractSound
							soundNamed: name
							ifAbsent: [
								(instrumentSelector at: i) contentsClipped: 'default'.
								FMSound default]) copy])].
		(soundsBeingEdited includes: (scorePlayer instrumentForTrack: i)) ifFalse:
			["Do not update any instrument that is currently being edited"
			scorePlayer instrumentForTrack: i put: (myInstruments at: name)].

		"update loaded/unloaded status in instrumentSelector if necessary"
		isUnloaded := (myInstruments at: name) isKindOf: UnloadedSound.
		(displaysAsUnloaded and: [isUnloaded not])
			ifTrue: [(instrumentSelector at: i) contentsClipped: name].
		(displaysAsUnloaded not and: [isUnloaded])
			ifTrue: [(instrumentSelector at: i) contentsClipped: name, unloadPostfix]].

]

{ #category : #layout }
ScorePlayerMorph >> volumeControl [

	| volumeSlider r |
	volumeSlider := SimpleSliderMorph new
		color: color;
		sliderColor: Color gray;
		extent: 80@2;
		target: scorePlayer;
		actionSelector: #overallVolume:;
		adjustToValue: scorePlayer overallVolume.
	r := self makeRow
		hResizing: #shrinkWrap;
		vResizing: #rigid;
		height: 24.
	r addMorphBack: (StringMorph contents: 'soft  ' translated).
	r addMorphBack: volumeSlider.
	r addMorphBack: (StringMorph contents: ' loud' translated).
	^ r

]

{ #category : #rounding }
ScorePlayerMorph >> wantsRoundedCorners [
	^ Preferences roundedWindowCorners or: [super wantsRoundedCorners]
]
