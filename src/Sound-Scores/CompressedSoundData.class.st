"
Instances of this class hold the data resulting from compressing a sound.  Each carries a reference to the codec class that created it, so that it can reconstruct a sound similar to the original in response to the message asSound.

In order to facilitate integration with existing sounds, a CompressedSoundData instance can masquerade as a sound by caching a copy of its original sound and delegating the essential sound-playing protocol to that cached copy.  It should probably be made a subclass of AbstractSound to complete the illusion.
"
Class {
	#name : #CompressedSoundData,
	#superclass : #Object,
	#instVars : [
		'channels',
		'soundClassName',
		'codecName',
		'loopEnd',
		'loopLength',
		'perceivedPitch',
		'samplingRate',
		'gain',
		'firstSample',
		'cachedSound'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #assound }
CompressedSoundData >> asSound [
	"Answer the result of decompressing the receiver."

	| codecClass |
	codecClass := Smalltalk at: codecName
		ifAbsent: [^ self error: 'The codec for decompressing this sound is not available'].
	^ (codecClass new decompressSound: self) reset

]

{ #category : #accessing }
CompressedSoundData >> channels [
	"Answer an array of ByteArrays containing the compressed sound data for each channel."

	^ channels

]

{ #category : #accessing }
CompressedSoundData >> channels: anArray [

	channels := anArray.

]

{ #category : #accessing }
CompressedSoundData >> codecName [
	"Answer the name of the sound codec used to compress this sound. Typically, this is the name of a class that can be used to decode the sound, but it is possible that the codec has not yet been implemented or is not filed into this image."

	^ codecName

]

{ #category : #accessing }
CompressedSoundData >> codecName: aStringOrSymbol [

	codecName := aStringOrSymbol asSymbol.

]

{ #category : #'as yet unclassified' }
CompressedSoundData >> compressWith: codecClass [

	codecName == codecClass name asSymbol ifTrue: [^self].
	^self asSound compressWith: codecClass
]

{ #category : #'as yet unclassified' }
CompressedSoundData >> compressWith: codecClass atRate: aSamplingRate [

	(codecName == codecClass name asSymbol and: [samplingRate = aSamplingRate]) ifTrue: [^self].
	^self asSound compressWith: codecClass atRate: aSamplingRate
]

{ #category : #assound }
CompressedSoundData >> doControl [

	cachedSound doControl

]

{ #category : #accessing }
CompressedSoundData >> firstSample [
	"Answer the firstSample of the original sound."

	^ firstSample

]

{ #category : #accessing }
CompressedSoundData >> firstSample: anInteger [

	firstSample := anInteger.

]

{ #category : #accessing }
CompressedSoundData >> gain [
	"Answer the gain of the original sound."

	^ gain

]

{ #category : #accessing }
CompressedSoundData >> gain: aNumber [

	gain := aNumber.

]

{ #category : #accessing }
CompressedSoundData >> loopEnd [
	"Answer index of the last sample of the loop, or nil if the original sound was not looped."

	^ loopEnd

]

{ #category : #accessing }
CompressedSoundData >> loopEnd: anInteger [

	loopEnd := anInteger.

]

{ #category : #accessing }
CompressedSoundData >> loopLength [
	"Answer length of the loop, or nil if the original sound was not looped."

	^ loopLength

]

{ #category : #accessing }
CompressedSoundData >> loopLength: anInteger [

	loopLength := anInteger.

]

{ #category : #assound }
CompressedSoundData >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [

	cachedSound mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol

]

{ #category : #accessing }
CompressedSoundData >> perceivedPitch [
	"Answer the perceived pitch of the original sound. By convention, unpitched sounds (like drum hits) are given an arbitrary pitch of 100.0."

	^ perceivedPitch

]

{ #category : #accessing }
CompressedSoundData >> perceivedPitch: aNumber [

	perceivedPitch := aNumber.

]

{ #category : #assound }
CompressedSoundData >> reset [
	"This message is the cue to start behaving like a real sound in order to be played.
	We do this by caching a decompressed version of this sound.
	See also samplesRemaining."

	cachedSound == nil ifTrue: [cachedSound := self asSound].
	cachedSound reset

]

{ #category : #assound }
CompressedSoundData >> samples [

	^ self asSound samples
]

{ #category : #assound }
CompressedSoundData >> samplesRemaining [
	"This message is the cue that the cached sound may no longer be needed.
	We know it is done playing when samplesRemaining=0."

	| samplesRemaining |
	samplesRemaining := cachedSound samplesRemaining.
	samplesRemaining <= 0 ifTrue: [cachedSound := nil].
	^ samplesRemaining
]

{ #category : #accessing }
CompressedSoundData >> samplingRate [
	"Answer the samplingRate of the original sound."

	^ samplingRate

]

{ #category : #accessing }
CompressedSoundData >> samplingRate: aNumber [

	samplingRate := aNumber.

]

{ #category : #accessing }
CompressedSoundData >> soundClassName [
	"Answer the class name of the uncompressed sound."

	^ soundClassName

]

{ #category : #accessing }
CompressedSoundData >> soundClassName: aStringOrSymbol [

	soundClassName := aStringOrSymbol asSymbol.

]
