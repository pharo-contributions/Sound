Class {
	#name : #ReverbSound,
	#superclass : #AbstractSound,
	#instVars : [
		'sound',
		'tapDelays',
		'tapGains',
		'tapCount',
		'bufferSize',
		'bufferIndex',
		'leftBuffer',
		'rightBuffer'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #private }
ReverbSound >> applyReverbTo: aSoundBuffer startingAt: startIndex count: n [

	| delayedLeft delayedRight i tapGain j out |
	<primitive: 'primitiveApplyReverb' module:'SoundGenerationPlugin'>
	self var: #aSoundBuffer declareC: 'short int *aSoundBuffer'.
	self var: #tapDelays declareC: 'int *tapDelays'.
	self var: #tapGains declareC: 'int *tapGains'.
	self var: #leftBuffer declareC: 'short int *leftBuffer'.
	self var: #rightBuffer declareC: 'short int *rightBuffer'.

	startIndex to: ((startIndex + n) - 1) do: [:sliceIndex |
		delayedLeft := delayedRight := 0.
		1 to: tapCount do: [:tapIndex |
			i := bufferIndex - (tapDelays at: tapIndex).
			i < 1 ifTrue: [i := i + bufferSize].  "wrap"
			tapGain := tapGains at: tapIndex.
			delayedLeft := delayedLeft + (tapGain * (leftBuffer at: i)).
			delayedRight := delayedRight + (tapGain * (rightBuffer at: i))].

		"left channel"
		j := (2 * sliceIndex) - 1.
		out := (aSoundBuffer at: j) + (delayedLeft // ScaleFactor).
		out >  32767 ifTrue: [out :=  32767].  "clipping!"
		out < -32767 ifTrue: [out := -32767].  "clipping!"
		aSoundBuffer at: j put: out.
		leftBuffer at: bufferIndex put: out.

		"right channel"
		j := j + 1.
		out := (aSoundBuffer at: j) + (delayedRight // ScaleFactor).
		out >  32767 ifTrue: [out :=  32767].  "clipping!"
		out < -32767 ifTrue: [out := -32767].  "clipping!"
		aSoundBuffer at: j put: out.
		rightBuffer at: bufferIndex put: out.

		bufferIndex := (bufferIndex \\ bufferSize) + 1].

]

{ #category : #copying }
ReverbSound >> copySound [
	"Private! Support for copying. Copy my component sound."

	sound := sound copy.
	leftBuffer := leftBuffer clone.
	rightBuffer := rightBuffer clone.

]

{ #category : #'sound generation' }
ReverbSound >> doControl [

	super doControl.
	sound doControl.

]

{ #category : #'sound generation' }
ReverbSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Play my sound with reverberation."

	sound mixSampleCount: n
		into: aSoundBuffer
		startingAt: startIndex
		leftVol: leftVol
		rightVol: rightVol.
	self applyReverbTo: aSoundBuffer startingAt: startIndex count: n.

]

{ #category : #copying }
ReverbSound >> postCopy [
	"Copy my component sound."

	super postCopy.
	self copySound

]

{ #category : #'sound generation' }
ReverbSound >> reset [

	super reset.
	sound reset.
	1 to: bufferSize do: [:i |
		leftBuffer at: i put: 0.
		rightBuffer at: i put: 0].

]

{ #category : #'sound generation' }
ReverbSound >> samplesRemaining [

	^ sound samplesRemaining

]

{ #category : #accessing }
ReverbSound >> sound [

	^ sound

]

{ #category : #accessing }
ReverbSound >> sound: aSound [

	sound := aSound.

]

{ #category : #accessing }
ReverbSound >> tapDelays: delayList gains: gainList [
	"ReverbSound new tapDelays: #(537 691 1191) gains: #(0.07 0.07 0.07)"

	| maxDelay gain d |
	delayList size = gainList size
		ifFalse: [self error: 'tap delay and gains lists must be the same size'].
	tapCount := delayList size.
	tapDelays := Bitmap new: tapCount.
	tapGains := Bitmap new: tapCount.

	maxDelay := 0.
	1 to: tapGains size do: [:i |
		tapDelays at: i put: (delayList at: i) asInteger.
		gain := gainList at: i.
		gain >= 1.0 ifTrue: [self error: 'reverb tap gains must be under 1.0'].
		tapGains at: i put: (gain * ScaleFactor) asInteger.
		d := tapDelays at: i.
		d > maxDelay ifTrue: [maxDelay := d]].
	bufferSize := maxDelay.
	leftBuffer := SoundBuffer newMonoSampleCount: maxDelay.
	rightBuffer := SoundBuffer newMonoSampleCount: maxDelay.
	bufferIndex := 1.

]
