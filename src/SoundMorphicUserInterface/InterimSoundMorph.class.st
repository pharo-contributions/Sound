"
I'm a little graphic associated with a sound.
"
Class {
	#name : #InterimSoundMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'graphic',
		'sound'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #'as yet unclassified' }
InterimSoundMorph >> addGraphic [

	graphic := self speakerGraphic asMorph.
	graphic position: bounds center - (graphic extent // 2).
	self addMorph: graphic.
]

{ #category : #initialization }
InterimSoundMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 1
]

{ #category : #initialization }
InterimSoundMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color
		r: 0
		g: 0.8
		b: 0.6
]

{ #category : #'event handling' }
InterimSoundMorph >> handlesMouseDown: evt [

	(graphic containsPoint: evt cursorPoint)
		ifTrue: [^ true]
		ifFalse: [^ super handlesMouseDown: evt].

]

{ #category : #initialization }
InterimSoundMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	
	self extent: 30 @ 30.
	self addGraphic.
	sound := PluckedSound
				pitch: 880.0
				dur: 2.0
				loudness: 0.5
]

{ #category : #'event handling' }
InterimSoundMorph >> mouseDown: evt [

	(graphic containsPoint: evt cursorPoint)
		ifTrue: [sound copy play]
		ifFalse: [super mouseDown: evt].

]

{ #category : #'as yet unclassified' }
InterimSoundMorph >> sound [

	^ sound

]

{ #category : #'as yet unclassified' }
InterimSoundMorph >> sound: aSound [

	sound := aSound.

]

{ #category : #'as yet unclassified' }
InterimSoundMorph >> speakerGraphic [

	^ Form
		extent: 19@18
		depth: 8
		fromArray: #(0 0 1493172224 2816 0 0 0 1493172224 11 0 0 138 1493172224 184549376 184549376 0 35509 2315255808 720896 720896 0 9090522 2315255808 2816 720896 0 2327173887 2315255819 2816 720896 138 3051028442 2315255819 2816 2816 1505080590 4294957786 2315255808 184549387 2816 3053453311 4292532917 1493172224 184549387 2816 1505080714 3048584629 1493172224 184549387 2816 9079434 3048584629 1493172224 184549387 2816 138 2327164341 1493172235 2816 2816 0 2324346293 1493172235 2816 720896 0 9079477 1493172224 2816 720896 0 35466 1493172224 720896 720896 0 138 0 184549376 184549376 0 0 0 11 0 0 0 0 2816 0)
		offset: 0@0

]
