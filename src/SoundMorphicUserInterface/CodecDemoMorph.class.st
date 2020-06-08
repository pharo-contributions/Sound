Class {
	#name : #CodecDemoMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'codecClassName'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #layout }
CodecDemoMorph >> acceptDroppingMorph: aMorph event: evt [

	| codecClass |
	'None' = codecClassName
		ifTrue: [aMorph sound play]
		ifFalse: [
			codecClass := Smalltalk at: codecClassName ifAbsent: [^ self].
			(codecClass new compressAndDecompress: aMorph sound) play].
	aMorph position: self topRight + (10@0).

]

{ #category : #menus }
CodecDemoMorph >> addCustomMenuItems: aCustomMenu hand: aHandMorph [

	super addCustomMenuItems: aCustomMenu hand: aHandMorph.
	aCustomMenu add: 'select codec' translated action: #selectCodec.

]

{ #category : #accessing }
CodecDemoMorph >> codecClassName: aStringOrSymbol [

	| label |
	codecClassName := aStringOrSymbol asSymbol.
	self removeAllMorphs.
	label := StringMorph contents: aStringOrSymbol.
	label position: self position + (5@5).
	self addMorph: label.
	label lock: true.
	self extent: label extent + (10@10).

]

{ #category : #initialization }
CodecDemoMorph >> defaultColor [
"answer the default color/fill style for the receiver"
	^ Color
		r: 1.0
		g: 0.806
		b: 0.677
]

{ #category : #initialization }
CodecDemoMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	
	self codecClassName: 'MuLawCodec'
]

{ #category : #private }
CodecDemoMorph >> selectCodec [

	| codecs newCodec |
	codecs := (SoundCodec allSubclasses collect: [:c | c name]) asSortedCollection.
	codecs add: 'None'.
	newCodec := UIManager default 
		chooseFrom: codecs values: codecs title: 'Codec:' translated.
	newCodec ifNil: [^ self].
	self codecClassName: newCodec.

]

{ #category : #'dropping/grabbing' }
CodecDemoMorph >> wantsDroppedMorph: aMorph event: evt [

	^ false

]
