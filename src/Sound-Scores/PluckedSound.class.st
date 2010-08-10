"
The Karplus-Strong plucked string algorithm: start with a buffer full of random noise and repeatedly play the contents of that buffer while averaging adjacent samples. High harmonics damp out more quickly, transfering their energy to lower ones. The length of the buffer corresponds to the length of the string. Fractional indexing is used to allow precise tuning; without this, the pitch would be rounded to the pitch corresponding to the nearest buffer size.

"
Class {
	#name : #PluckedSound,
	#superclass : #AbstractSound,
	#instVars : [
		'initialCount',
		'count',
		'ring',
		'scaledIndex',
		'scaledIndexIncr',
		'scaledIndexLimit'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #instruments }
PluckedSound class >> default [
	"PluckedSound default play"
	"(AbstractSound majorScaleOn: PluckedSound default) play"

	| snd p env |
	snd := PluckedSound new.
	p := OrderedCollection new.
	p add: 0@1.0; add: 10@1.0; add: 20@0.0.
	env := VolumeEnvelope points: p loopStart: 2 loopEnd: 2.
	env target: snd; scale: 0.3.
	^ snd
		addEnvelope: env;
		setPitch: 220 dur: 3.0 loudness: 0.3

]

{ #category : #copying }
PluckedSound >> copy [

	^ super copy copyRing

]

{ #category : #copying }
PluckedSound >> copyRing [
	"Private! Support for copying"

	ring := ring copy.

]

{ #category : #accessing }
PluckedSound >> duration [
	"Answer the duration of this sound in seconds."

	^ initialCount asFloat / self samplingRate

]

{ #category : #accessing }
PluckedSound >> duration: seconds [

	super duration: seconds.
	count := initialCount := (seconds * self samplingRate) rounded.

]

{ #category : #'sound generation' }
PluckedSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"The Karplus-Strong plucked string algorithm: start with a buffer full of random noise and repeatedly play the contents of that buffer while averaging adjacent samples. High harmonics damp out more quickly, transfering their energy to lower ones. The length of the buffer corresponds to the length of the string."
	"(PluckedSound pitch: 220.0 dur: 6.0 loudness: 0.8) play"

	| lastIndex scaledThisIndex scaledNextIndex average sample i s |
	<primitive:'primitiveMixPluckedSound' module:'SoundGenerationPlugin'>
	self var: #aSoundBuffer declareC: 'short int *aSoundBuffer'.
	self var: #ring declareC: 'short int *ring'.

	lastIndex := (startIndex + n) - 1.
	scaledThisIndex := scaledNextIndex := scaledIndex.
	startIndex to: lastIndex do: [:sliceIndex |
		scaledNextIndex := scaledThisIndex + scaledIndexIncr.
		scaledNextIndex >= scaledIndexLimit
			ifTrue: [scaledNextIndex := ScaleFactor + (scaledNextIndex - scaledIndexLimit)].
		average :=
			((ring at: scaledThisIndex // ScaleFactor) +
			 (ring at: scaledNextIndex // ScaleFactor)) // 2.
		ring at: scaledThisIndex // ScaleFactor put: average.
		sample := (average * scaledVol) // ScaleFactor.  "scale by volume"
		scaledThisIndex := scaledNextIndex.

		leftVol > 0 ifTrue: [
			i := (2 * sliceIndex) - 1.
			s := (aSoundBuffer at: i) + ((sample * leftVol) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].
		rightVol > 0 ifTrue: [
			i := 2 * sliceIndex.
			s := (aSoundBuffer at: i) + ((sample * rightVol) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].

		scaledVolIncr ~= 0 ifTrue: [
			scaledVol := scaledVol + scaledVolIncr.
			((scaledVolIncr > 0 and: [scaledVol >= scaledVolLimit]) or:
			 [scaledVolIncr < 0 and: [scaledVol <= scaledVolLimit]])
				ifTrue: [  "reached the limit; stop incrementing"
					scaledVol := scaledVolLimit.
					scaledVolIncr := 0]]].

	scaledIndex := scaledNextIndex.
	count := count - n.

]

{ #category : #'sound generation' }
PluckedSound >> reset [
	"Fill the ring with random noise."

	| seed n |
	super reset.
	seed := 17.
	n := ring monoSampleCount.
	1 to: n do: [:i |
		seed := ((seed * 1309) + 13849) bitAnd: 65535.
		ring at: i put: seed - 32768].
	count := initialCount.
	scaledIndex := ScaleFactor.

]

{ #category : #'sound generation' }
PluckedSound >> samplesRemaining [

	^ count

]

{ #category : #initialization }
PluckedSound >> setPitch: pitchNameOrNumber dur: d loudness: vol [

	| p sz |
	super setPitch: pitchNameOrNumber dur: d loudness: vol.
	p := self nameOrNumberToPitch: pitchNameOrNumber.
	initialCount := (d * self samplingRate asFloat) asInteger.
	ring := SoundBuffer newMonoSampleCount:
		(((2.0 * self samplingRate) / p) asInteger max: 2).
	sz := ring monoSampleCount.
	scaledIndexLimit := (sz + 1) * ScaleFactor.
	scaledIndexIncr := (p * sz * ScaleFactor) // (2.0 * self samplingRate).
	self reset.

]

{ #category : #'sound generation' }
PluckedSound >> stopAfterMSecs: mSecs [
	"Terminate this sound this note after the given number of milliseconds."

	count := (mSecs * self samplingRate) // 1000.

]
