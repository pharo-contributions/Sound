Class {
	#name : 'SpeakerMorph',
	#superclass : 'Morph',
	#instVars : [
		'bufferSize',
		'buffer',
		'lastConePosition',
		'sound'
	],
	#category : 'SoundMorphicUserInterface',
	#package : 'SoundMorphicUserInterface'
}

{ #category : 'initialization' }
SpeakerMorph >> addGraphic [

	| graphic |
	graphic := World drawingClass withForm: self speakerGraphic.
	graphic position: bounds center - (graphic extent // 2).
	self addMorph: graphic.

]

{ #category : 'nil' }
SpeakerMorph >> appendSample: aFloat [
	"Append the given sample, a number between -100.0 and 100.0, to my buffer. Flush the buffer if it is full."

	lastConePosition := aFloat.
	lastConePosition > 100.0 ifTrue: [lastConePosition := 100.0].
	lastConePosition < -100.0 ifTrue: [lastConePosition := -100.0].
	buffer nextPut: (327.67 * lastConePosition) truncated.
	buffer position >= bufferSize ifTrue: [self flushBuffer].

]

{ #category : 'speaker' }
SpeakerMorph >> conePosition [

	^ lastConePosition

]

{ #category : 'speaker' }
SpeakerMorph >> conePosition: aNumber [

	self appendSample: aNumber asFloat.  "sets lastConePosition"

]

{ #category : 'initialization' }
SpeakerMorph >> defaultColor [
"answer the default color/fill style for the receiver"
	^ Color
		r: 1.0
		g: 0.484
		b: 0.258
]

{ #category : 'speaker' }
SpeakerMorph >> flushBuffer [

	| buf |
	buf := buffer contents.
	buffer resetContents.
	sound isPlaying ifFalse: [sound := SequentialSound new].
	sound add: (SampledSound samples: buf samplingRate: 11025).
	sound isPlaying
		ifTrue: [sound pruneFinishedSounds]
		ifFalse: [sound play].

]

{ #category : 'initialization' }
SpeakerMorph >> initialize [
"initialize the state of the receiver"
	super initialize.
""
	self addGraphic.
	bufferSize := 5000.
	buffer := WriteStream
				on: (SoundBuffer newMonoSampleCount: bufferSize).
	lastConePosition := 0.
	sound := SequentialSound new
]

{ #category : 'initialization' }
SpeakerMorph >> speakerGraphic [

	^ Form
		extent: 19@18
		depth: 8
		fromArray: #(0 0 1493172224 2816 0 0 0 1493172224 11 0 0 138 1493172224 184549376 184549376 0 35509 2315255808 720896 720896 0 9090522 2315255808 2816 720896 0 2327173887 2315255819 2816 720896 138 3051028442 2315255819 2816 2816 1505080590 4294957786 2315255808 184549387 2816 3053453311 4292532917 1493172224 184549387 2816 1505080714 3048584629 1493172224 184549387 2816 9079434 3048584629 1493172224 184549387 2816 138 2327164341 1493172235 2816 2816 0 2324346293 1493172235 2816 720896 0 9079477 1493172224 2816 720896 0 35466 1493172224 720896 720896 0 138 0 184549376 184549376 0 0 0 11 0 0 0 0 2816 0)
		offset: 0@0

]

{ #category : 'speaker' }
SpeakerMorph >> stopSound [

	sound pause.
	buffer resetContents.

]
