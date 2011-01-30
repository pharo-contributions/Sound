"
This is the normal sound system in Squeak and is registered in SoundService - an AppRegistry - so that a small highlevel protocol for playing sounds can be used in a pluggable fashion.

More information available in superclass.
"
Class {
	#name : #BaseSoundSystem,
	#superclass : #AbstractSoundSystem,
	#category : #'Sound-Synthesis'
}

{ #category : #initialization }
BaseSoundSystem class >> initialize [
	SoundService default: self
]

{ #category : #initialization }
BaseSoundSystem class >> unload [
	SoundService registeredClasses do: [:ss |
		(ss isKindOf: self) ifTrue: [SoundService unregister: ss]].
]

{ #category : #playing }
BaseSoundSystem >> beep [
	"There is sound support, so we use the default
	sampled sound for a beep."

	self class soundEnabled ifTrue: [
		SampledSound beep]
]

{ #category : #playing }
BaseSoundSystem >> playSampledSound: samples rate: rate [

	self class soundsEnabled ifTrue: [
		(SampledSound samples: samples samplingRate: rate) play]
]

{ #category : #playing }
BaseSoundSystem >> playSoundNamed: soundName [
	"There is sound support, so we play the given sound."

	self class soundsEnabled ifTrue: [
		SampledSound playSoundNamed: soundName asString]
]

{ #category : #playing }
BaseSoundSystem >> playSoundNamed: soundName ifAbsentReadFrom: aifFileName [

	self class soundsEnabled ifTrue: [
		(SampledSound soundNames includes: soundName) ifFalse: [
			(FileDirectory default fileExists: aifFileName) ifTrue: [
				SampledSound
					addLibrarySoundNamed: soundName
					fromAIFFfileNamed: aifFileName]].
		(SampledSound soundNames includes: soundName) ifTrue: [
			SampledSound playSoundNamed: soundName]]
]

{ #category : #playing }
BaseSoundSystem >> playSoundNamedOrBeep: soundName [
	"There is sound support, so we play the given sound
	instead of beeping."

	self class soundsEnabled ifTrue: [
		^self playSoundNamed: soundName]
]

{ #category : #misc }
BaseSoundSystem >> randomBitsFromSoundInput: bitCount [
	"Answer a positive integer with the given number of random bits of 'noise' from a sound input source. Typically, one would use a microphone or line input as the sound source, although many sound cards have enough thermal noise that you get random low-order sample bits even with no microphone connected. Only the least signficant bit of the samples is used. Since not all sound cards support 16-bits of sample resolution, we use the lowest bit that changes."
	"(1 to: 10) collect: [:i | BaseSoundSystem new randomBitsFromSoundInput: 512]"

	| recorder buf mid samples bitMask randomBits bit |
	"collect some sound data"
	recorder := SoundRecorder new clearRecordedSound.
	recorder resumeRecording.
	(Delay forSeconds: 1) wait.
	recorder stopRecording.
	buf := recorder condensedSamples.

	"grab bitCount samples from the middle"
	mid := buf monoSampleCount // 2.
	samples := buf copyFrom: mid to: mid + bitCount - 1.

	"find the least significant bit that varies"
	bitMask := 1.
	[bitMask < 16r10000 and:
	 [(samples collect: [:s | s bitAnd: bitMask]) asSet size < 2]]
		whileTrue: [bitMask := bitMask bitShift: 1].
	bitMask = 16r10000 ifTrue: [^ self error: 'sound samples do not vary'].

	"pack the random bits into a positive integer"
	randomBits := 0.
	1 to: samples size do: [:i |
		bit := ((samples at: i) bitAnd: bitMask) = 0 ifTrue: [0] ifFalse: [1].
		randomBits := (randomBits bitShift: 1) + bit].

	^ randomBits	

]

{ #category : #misc }
BaseSoundSystem >> sampledSoundChoices [
	^ SampledSound soundNames
]

{ #category : #misc }
BaseSoundSystem >> shutDown [
	SoundPlayer shutDown

]

{ #category : #misc }
BaseSoundSystem >> soundNamed: soundName [
	^ SampledSound soundNamed: soundName
]
