"
I am the user interface for a simple software MIDI synthesizer that is driven by external MIDI input. I come with controls for a single MIDI channel (channel 1), but allow channel controls for additional MIDI channels to be added by the user. The volume, pan, and instrument of each channel can be controlled independently.

"
Class {
	#name : #MidiInputMorph,
	#superclass : #AlignmentMorph,
	#instVars : [
		'midiPortNumber',
		'midiSynth',
		'instrumentSelector'
	],
	#category : #'Sound-Scores'
}

{ #category : #'as yet unclassified' }
MidiInputMorph >> addChannel [
	"Add a set of controls for another channel. Prompt the user for the channel number."

	| menu existingChannels newChannel |
	menu := CustomMenu new.
	existingChannels := Set new.
	1 to: 16 do: [:ch | (instrumentSelector at: ch) ifNotNil: [existingChannels add: ch]].
	1 to: 16 do: [:ch |
		(existingChannels includes: ch) ifFalse: [
			menu add: ch printString action: ch]].
	newChannel := menu startUp.
	newChannel ifNotNil: [self addChannelControlsFor: newChannel].

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> addChannelControlsFor: channelIndex [

	| r divider col |
	r := self makeRow
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap.
	r addMorphBack: (self channelNumAndMuteButtonFor: channelIndex).
	r addMorphBack: (Morph new extent: 10@5; color: color).  "spacer"
	r addMorphBack: (self panAndVolControlsFor: channelIndex).

	divider := AlignmentMorph new
		extent: 10@1;
		borderWidth: 1;
		layoutInset: 0;
		borderColor: #raised;
		color: color;
		hResizing: #spaceFill;
		vResizing: #rigid.

	col := self lastSubmorph.
	col addMorphBack: divider.
	col addMorphBack: r.

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> atChannel: channelIndex from: aPopUpChoice selectInstrument: selection [ 
	| oldSnd name snd instSelector |
	oldSnd := midiSynth instrumentForChannel: channelIndex.
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
			(channelIndex ~= i and: 
					[(instSelector := instrumentSelector at: i) notNil 
						and: [selection = instSelector contents]]) 
				ifTrue: [snd := midiSynth instrumentForChannel: i]].	"use existing instrument prototype"
	snd ifNil: 
			[snd := (selection = 'clink' 
						ifTrue: 
							[(SampledSound samples: SampledSound coffeeCupClink samplingRate: 11025)]
						ifFalse: [(AbstractSound soundNamed: selection) ])copy ].
	midiSynth instrumentForChannel: channelIndex put: snd.
	(instrumentSelector at: channelIndex) contentsClipped: selection
]

{ #category : #'as yet unclassified' }
MidiInputMorph >> channelNumAndMuteButtonFor: channelIndex [

	| muteButton instSelector r |
	muteButton := SimpleSwitchMorph new
		onColor: (Color r: 1.0 g: 0.6 b: 0.6);
		offColor: color;
		color: color;
		label: 'Mute';
		target: midiSynth;
		actionSelector: #mutedForChannel:put:;
		arguments: (Array with: channelIndex).
	instSelector := PopUpChoiceMorph new
		extent: 95@14;
		contentsClipped: 'oboe1';
		target: self;
		actionSelector: #atChannel:from:selectInstrument:;
		getItemsSelector: #instrumentChoicesForChannel:;
		getItemsArgs: (Array with: channelIndex).
	instSelector arguments:
		(Array with: channelIndex with: instSelector).
	instrumentSelector at: channelIndex put: instSelector.

	r := self makeRow
		hResizing: #rigid;
		vResizing: #spaceFill;
		extent: 70@10.
	r addMorphBack:
		(StringMorph
			contents: channelIndex printString
			font: (TextStyle default fontOfSize: 24)).
	channelIndex < 10
		ifTrue: [r addMorphBack: (Morph new color: color; extent: 19@8)]  "spacer"
		ifFalse: [r addMorphBack: (Morph new color: color; extent: 8@8)].  "spacer"
	r addMorphBack: instSelector.
	r addMorphBack: (AlignmentMorph newRow color: color).  "spacer"
	r addMorphBack: muteButton.
	^ r

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> closeMIDIPort [

	midiSynth isOn ifTrue: [midiSynth stopMIDITracking].
	midiSynth closeMIDIPort.

]

{ #category : #initialization }
MidiInputMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 2
]

{ #category : #initialization }
MidiInputMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color veryLightGray
]

{ #category : #'as yet unclassified' }
MidiInputMorph >> disableReverb: aBoolean [

	aBoolean
		ifTrue: [SoundPlayer stopReverb]
		ifFalse: [SoundPlayer startReverb].

]

{ #category : #initialization }
MidiInputMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	self listDirection: #topToBottom;
	  wrapCentering: #center;
		 cellPositioning: #topCenter;
	  hResizing: #spaceFill;
	  vResizing: #spaceFill;
	  layoutInset: 3.
	midiPortNumber := nil.
	midiSynth := MIDISynth new.
	instrumentSelector := Array new: 16.
	self removeAllMorphs.
	self addMorphBack: self makeControls.
	self addMorphBack: (AlignmentMorph newColumn color: color;
			 layoutInset: 0).
	self addChannelControlsFor: 1.
	self extent: 20 @ 20
]

{ #category : #'as yet unclassified' }
MidiInputMorph >> instrumentChoicesForChannel: channelIndex [

	| names inst |
	names := AbstractSound soundNames asOrderedCollection.
	names := names collect: [:n |
		inst := AbstractSound soundNamed: n.
		(inst isKindOf: UnloadedSound)
			ifTrue: [n, '(out)']
			ifFalse: [n]].
	names add: 'clink'.
	names add: 'edit ', (instrumentSelector at: channelIndex) contents.
	^ names asArray

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> invokeMenu [
	"Invoke a menu of additonal commands."

	| aMenu |
	aMenu := CustomMenu new.
	aMenu add: 'add channel' translated action: #addChannel.
	aMenu add: 'reload instruments' translated target: AbstractSound selector: #updateScorePlayers.
	midiSynth isOn ifFalse: [
		aMenu add: 'set MIDI port' translated action: #setMIDIPort.
		midiSynth midiPort
			ifNotNil: [aMenu add: 'close MIDI port' translated action: #closeMIDIPort]].	
	aMenu invokeOn: self defaultSelection: nil.

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> makeControls [

	| bb r reverbSwitch onOffSwitch |
	bb := SimpleButtonMorph new
		target: self;
		borderColor: #raised;
		borderWidth: 2;
		color: color.
	r := AlignmentMorph newRow.
	r color: bb color; borderWidth: 0; layoutInset: 0.
	r hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	r addMorphBack: (
		bb label: '<>';
			actWhen: #buttonDown;
			actionSelector: #invokeMenu).
	onOffSwitch := SimpleSwitchMorph new
		offColor: color;
		onColor: (Color r: 1.0 g: 0.6 b: 0.6);
		borderWidth: 2;
		label: 'On';
		actionSelector: #toggleOnOff;
		target: self;
		setSwitchState: false.
	r addMorphBack: onOffSwitch.
	reverbSwitch := SimpleSwitchMorph new
		offColor: color;
		onColor: (Color r: 1.0 g: 0.6 b: 0.6);
		borderWidth: 2;
		label: 'Reverb Disable';
		actionSelector: #disableReverb:;
		target: self;
		setSwitchState: SoundPlayer isReverbOn not.
	r addMorphBack: reverbSwitch.
	^ r

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> makeRow [

	^ AlignmentMorph newRow
		color: color;
		layoutInset: 0;
		wrapCentering: #center; cellPositioning: #leftCenter;
		hResizing: #spaceFill;
		vResizing: #shrinkWrap

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> panAndVolControlsFor: channelIndex [

	| volSlider panSlider c r middleLine |
	volSlider := SimpleSliderMorph new
		color: color;
		extent: 101@2;
		target: midiSynth;
		arguments: (Array with: channelIndex);
		actionSelector: #volumeForChannel:put:;
		minVal: 0.0;
		maxVal: 1.0;
		adjustToValue: (midiSynth volumeForChannel: channelIndex).
	panSlider := SimpleSliderMorph new
		color: color;
		extent: 101@2;
		target: midiSynth;
		arguments: (Array with: channelIndex);
		actionSelector: #panForChannel:put:;
		minVal: 0.0;
		maxVal: 1.0;		
		adjustToValue: (midiSynth panForChannel: channelIndex).
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
	r addMorphBack: (StringMorph contents: 'L').
	r addMorphBack: panSlider.
	r addMorphBack: (StringMorph contents: 'R').
	c addMorphBack: r.
	^ c

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> setMIDIPort [

	| portNum |
	portNum := SimpleMIDIPort outputPortNumFromUser.
	portNum ifNil: [^ self].
	midiPortNumber := portNum.

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> toggleOnOff [

	midiSynth isOn
		ifTrue: [
			midiSynth stopMIDITracking]
		ifFalse: [
			midiPortNumber ifNil: [self setMIDIPort].
			midiPortNumber ifNil: [midiPortNumber := 0].
			midiSynth midiPort: (SimpleMIDIPort openOnPortNumber: midiPortNumber).
			midiSynth startMIDITracking].

]

{ #category : #'as yet unclassified' }
MidiInputMorph >> updateInstrumentsFromLibraryExcept: soundsBeingEdited [
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
		(soundsBeingEdited includes: (midiSynth instrumentForChannel: i)) ifFalse:
			["Do not update any instrument that is currently being edited"
			midiSynth instrumentForChannel: i put: (myInstruments at: name)].

		"update loaded/unloaded status in instrumentSelector if necessary"
		isUnloaded := (myInstruments at: name) isKindOf: UnloadedSound.
		(displaysAsUnloaded and: [isUnloaded not])
			ifTrue: [(instrumentSelector at: i) contentsClipped: name].
		(displaysAsUnloaded not and: [isUnloaded])
			ifTrue: [(instrumentSelector at: i) contentsClipped: name, unloadPostfix]].

]
