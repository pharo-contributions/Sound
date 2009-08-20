Class {
	#name : #MIDIControllerMorph,
	#superclass : #AlignmentMorph,
	#instVars : [
		'channel',
		'controller',
		'midiPort',
		'lastValue'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #menu }
MIDIControllerMorph >> addCustomMenuItems: aCustomMenu hand: aHandMorph [

	super addCustomMenuItems: aCustomMenu hand: aHandMorph.
	aCustomMenu add: 'set channel' translated action: #setChannel:.
	aCustomMenu add: 'set controller' translated action: #setController:.

]

{ #category : #accessing }
MIDIControllerMorph >> channel [

	^ channel

]

{ #category : #accessing }
MIDIControllerMorph >> channel: anInteger [

	channel := anInteger.
	lastValue := nil.
	self updateLabel.

]

{ #category : #accessing }
MIDIControllerMorph >> controller [

	^ controller

]

{ #category : #accessing }
MIDIControllerMorph >> controller: anInteger [

	controller := anInteger.
	lastValue := nil.
	self updateLabel.

]

{ #category : #menu }
MIDIControllerMorph >> controllerList [
	"Answer a list of controller name, number pairs to be used in the menu."

	^ #((1 modulation)
		(2 'breath control')
		(7 volume)
		(10 pan)
		(11 expression)
		(92 'tremolo depth')
		(93 'chorus depth')
		(94 'celeste depth')
		(95 'phaser depth'))

]

{ #category : #menu }
MIDIControllerMorph >> controllerName: controllerNumber [
	"Answer a name for the given controller. If no name is available, use the form 'CC5' (CC is short for 'continuous controller')."

	self controllerList do: [:pair |
		pair first = controllerNumber ifTrue: [^ pair last]].
	^ 'CC', controllerNumber asString

]

{ #category : #initialization }
MIDIControllerMorph >> defaultBorderWidth [
"answer the default border width for the receiver"
	^ 1
]

{ #category : #initialization }
MIDIControllerMorph >> defaultColor [
"answer the default color/fill style for the receiver"
	^ Color
		r: 0.484
		g: 0.613
		b: 0.0
]

{ #category : #initialization }
MIDIControllerMorph >> initialize [
"initialize the state of the receiver"
	| slider |
	super initialize.
""
	self listDirection: #topToBottom.
	self wrapCentering: #center;
		 cellPositioning: #topCenter.
	self hResizing: #shrinkWrap.
	self vResizing: #shrinkWrap.
	channel := 0.
	controller := 7.
	"channel volume"
	slider := SimpleSliderMorph new target: self;
				 actionSelector: #newSliderValue:;
				 minVal: 0;
				 maxVal: 127;
				 extent: 128 @ 10.
	self addMorphBack: slider.
	self
		addMorphBack: (StringMorph contents: 'Midi Controller').
	self updateLabel
]

{ #category : #accessing }
MIDIControllerMorph >> midiPort [

	^ midiPort

]

{ #category : #accessing }
MIDIControllerMorph >> midiPort: anInteger [

	midiPort := anInteger.

]

{ #category : #other }
MIDIControllerMorph >> newSliderValue: newValue [
	"Send a control command out the MIDI port."

	| val |
	midiPort ifNil: [^ self].
	val := newValue asInteger.
	lastValue = val ifTrue: [^ self].
	lastValue := val.
	midiPort midiCmd: 16rB0 channel: channel byte: controller byte: val.

]

{ #category : #menu }
MIDIControllerMorph >> setChannel: evt [
	| menu |
	menu := MenuMorph new.
	1 to: 16 do: [:chan |
		menu add: chan printString
			target: self
			selector: #channel:
			argumentList: (Array with: chan - 1)].

	menu popUpEvent: evt in: self world
]

{ #category : #menu }
MIDIControllerMorph >> setController: evt [
	| menu |
	menu := MenuMorph new.
	self controllerList do: [:pair |
		menu add: (pair last)
			target: self
			selector: #controller:
			argumentList: (Array with: pair first)].

	menu popUpEvent: evt in: self world
]

{ #category : #other }
MIDIControllerMorph >> updateLabel [

	| label |
	(label := self findA: StringMorph) ifNil: [^ self].
	label contents: (self controllerName: controller), ', ch: ', (channel + 1) printString.

]
