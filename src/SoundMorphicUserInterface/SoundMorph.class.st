"
Note: as of December 2000, this does not work. SoundMorph>>buildImage requires the sound to implement #volumeEnvelopeScaledTo: and as yet, no one does.
"
Class {
	#name : 'SoundMorph',
	#superclass : 'ImageMorph',
	#instVars : [
		'sound'
	],
	#category : 'SoundMorphicUserInterface',
	#package : 'SoundMorphicUserInterface'
}

{ #category : 'private' }
SoundMorph >> buildImage [
	| scale env h imageColor |
	owner ifNil: [scale := 128@128]  "Default is 128 pix/second, 128 pix fullscale"
		ifNotNil: [scale := owner soundScale].
	env := sound volumeEnvelopeScaledTo: scale.
	self image: (ColorForm extent: env size @ env max).
	1 to: image width do:
		[:x | h := env at: x.
		image fillBlack: ((x-1)@(image height-h//2) extent: 1@h)].
	imageColor := #(black red orange green blue) atPin:
						(sound pitch / 110.0) rounded highBit.
	image colors: (Array with: Color transparent with: (Color perform: imageColor)).

]

{ #category : 'initialization' }
SoundMorph >> initialize [

	super initialize.
	self sound: (FMSound pitch: 880.0 dur: 0.2 loudness: 0.8).

]

{ #category : 'dropping/grabbing' }
SoundMorph >> justDroppedInto: aMorph event: anEvent [
	| relPosition |
	relPosition := self position - aMorph innerBounds topLeft.
	relPosition := (relPosition x roundTo: 8) @ relPosition y.
	self position: aMorph innerBounds topLeft + relPosition.
	sound copy play.
	^super justDroppedInto: aMorph event: anEvent
]

{ #category : 'initialization' }
SoundMorph >> reset [
	sound reset
]

{ #category : 'accessing' }
SoundMorph >> sound [
	^ sound
]

{ #category : 'accessing' }
SoundMorph >> sound: aSound [
	sound := aSound copy.
	sound reset.
	self buildImage
]
