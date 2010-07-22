Class {
	#name : #MixedSound,
	#superclass : #AbstractSound,
	#instVars : [
		'sounds',
		'leftVols',
		'rightVols',
		'soundDone'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #composition }
MixedSound >> + aSound [
	"Return the mix of the receiver and the argument sound."

	^ self add: aSound

]

{ #category : #composition }
MixedSound >> add: aSound [
	"Add the given sound with a pan setting of centered and no attenuation."

	self add: aSound pan: 0.5 volume: 1.0.
	^ aSound
]

{ #category : #composition }
MixedSound >> add: aSound pan: leftRightPan [
	"Add the given sound with the given left-right panning and no attenuation."

	self add: aSound pan: leftRightPan volume: 1.0.

]

{ #category : #composition }
MixedSound >> add: aSound pan: leftRightPan volume: volume [
	"Add the given sound with the given left-right pan, where 0.0 is full left, 1.0 is full right, and 0.5 is centered. The loudness of the sound will be scaled by volume, which ranges from 0 to 1.0."

	| pan vol |
	pan := ((leftRightPan * ScaleFactor) asInteger max: 0) min: ScaleFactor.
	vol := ((volume * ScaleFactor) asInteger max: 0) min: ScaleFactor.
	sounds := sounds copyWith: aSound.
	leftVols := leftVols copyWith: ((ScaleFactor - pan) * vol) // ScaleFactor.
	rightVols := rightVols copyWith: (pan * vol) // ScaleFactor.

]

{ #category : #copying }
MixedSound >> copy [
	"Copy my component sounds."

	^ super copy copySounds

]

{ #category : #copying }
MixedSound >> copySounds [
	"Private! Support for copying. Copy my component sounds and settings array."

	sounds := sounds collect: [:s | s copy].
	leftVols := leftVols copy.
	rightVols := rightVols copy.

]

{ #category : #'sound generation' }
MixedSound >> doControl [

	super doControl.
	1 to: sounds size do: [:i | (sounds at: i) doControl].

]

{ #category : #accessing }
MixedSound >> duration [
	"Answer the duration of this sound in seconds."

	| dur |
	dur := 0.
	sounds do: [:snd | dur := dur max: snd duration].
	^ dur

]

{ #category : #initialization }
MixedSound >> initialize [

	super initialize.
	sounds := Array new.
	leftVols := Array new.
	rightVols := Array new.

]

{ #category : #accessing }
MixedSound >> isStereo [

	^ true

]

{ #category : #'sound generation' }
MixedSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Play a number of sounds concurrently. The level of each sound can be set independently for the left and right channels."

	| snd left right |
	1 to: sounds size do: [:i |
		(soundDone at: i) ifFalse: [
			snd := sounds at: i.
			left := (leftVol * (leftVols at: i)) // ScaleFactor.
			right := (rightVol * (rightVols at: i)) // ScaleFactor.
			snd samplesRemaining > 0
				ifTrue: [
					snd mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: left rightVol: right]
				ifFalse: [soundDone at: i put: true]]].

]

{ #category : #'sound generation' }
MixedSound >> reset [

	super reset.
	sounds do: [:snd | snd reset].
	soundDone := (Array new: sounds size) atAllPut: false.

]

{ #category : #'sound generation' }
MixedSound >> samplesRemaining [

	| remaining r |
	remaining := 0.
	1 to: sounds size do: [:i |
		r := (sounds at: i) samplesRemaining.
		r > remaining ifTrue: [remaining := r]].

	^ remaining

]

{ #category : #accessing }
MixedSound >> sounds [

	^ sounds

]

{ #category : #'sound generation' }
MixedSound >> stopGracefully [
	"End this note with a graceful decay. If the note has envelopes, determine the decay time from its envelopes."

	super stopGracefully.
	sounds do: [:s | s stopGracefully].

]
