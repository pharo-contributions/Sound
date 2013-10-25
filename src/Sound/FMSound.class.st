Class {
	#name : #FMSound,
	#superclass : #AbstractSound,
	#instVars : [
		'initialCount',
		'count',
		'waveTable',
		'scaledWaveTableSize',
		'scaledIndex',
		'scaledIndexIncr',
		'modulation',
		'multiplier',
		'normalizedModulation',
		'scaledOffsetIndex',
		'scaledOffsetIndexIncr'
	],
	#classVars : [
		'SineTable'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #instruments }
FMSound class >> bass1 [
	"FMSound bass1 play"
	"(FMSound lowMajorScaleOn: FMSound bass1) play"

	| sound |
	sound := self new modulation: 0 ratio: 0.
	sound addEnvelope: (VolumeEnvelope exponentialDecay: 0.95).
	^ sound setPitch: 220 dur: 1.0 loudness: 0.3

]

{ #category : #instruments }
FMSound class >> bassoon1 [
	"FMSound bassoon1 play"
	"(FMSound lowMajorScaleOn: FMSound bassoon1) play"

	| sound  env |
	sound := FMBassoonSound new ratio: 1.
	
	sound addEnvelope: (VolumeEnvelope 
			points: { 0@0.0 . 40@0.45 . 90@1.0 . 180@0.9 .  270@1.0 . 320@0.0} loopStart: 3 loopEnd: 5).

	env := Envelope 
			points: {0@0.2 . 40@0.9 . 90@0.6 . 270@0.6.  320@0.5} loopStart: 3 loopEnd: 4.
	env updateSelector: #modulation:; scale: 5.05.
	sound addEnvelope: env.

	^ sound setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> brass1 [
	"FMSound brass1 play"
	"(FMSound lowMajorScaleOn: FMSound brass1) play"

	| sound  env |
	sound := FMSound new modulation: 0 ratio: 1.
	sound addEnvelope: (VolumeEnvelope 
								points: { 0@0.0 . 30@0.8 . 90@1.0  .  120@0.9. 220@0.7 . 320@0.9 . 360@0.0} 
								loopStart: 4 loopEnd: 6).

	env := Envelope 
				points: { 0@0.5 . 60@1.0 . 120@0.8 . 220@0.65 . 320@0.8 . 360@0.0} 
				loopStart: 3 loopEnd: 5.
	env target: sound; updateSelector: #modulation:; scale: 5.0.
	sound addEnvelope: env.

	^ sound setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> brass2 [
	"FMSound brass2 play"
	"(FMSound lowMajorScaleOn: FMSound brass2) play"

	| sound  env |
	sound := FMSound new modulation: 1 ratio: 1.

	sound addEnvelope: (VolumeEnvelope 
							points: {  0@0.0 . 20@1.0 . 40@0.9 . 100@0.7 . 160@0.9 . 200@0.0 } 
							loopStart: 3 loopEnd: 5).

	env := Envelope 
				points: {0@0.5 . 30@1.0 . 40@0.8 . 100@0.7 . 160@0.8 . 200@0.0} 
				loopStart: 3 loopEnd: 5.
	env updateSelector: #modulation:; scale: 5.0.
	sound addEnvelope: env.

	^ sound setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> clarinet [
	"FMSound clarinet play"
	"(FMSound lowMajorScaleOn: FMSound clarinet) play"

	| sound  env |
	sound := FMSound new modulation: 0 ratio: 2.	
	sound addEnvelope: (VolumeEnvelope points: { 0@0.0 . 60@1.0 . 310@1.0 . 350@0.0} loopStart: 2 loopEnd: 3).

	env := Envelope points: {0@0.0167 . 60@0.106 . 310@0.106 . 350@0.0 } loopStart: 2 loopEnd: 3.
	env updateSelector: #modulation:; scale: 10.0.
	sound addEnvelope: env.

	^ sound setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> clarinet2 [
	"FMSound clarinet2 play"
	"(FMSound lowMajorScaleOn: FMSound clarinet2) play"

	| sound  env |
	sound := FMClarinetSound new modulation: 0 ratio: 2.
	sound addEnvelope: (VolumeEnvelope 
								points: { 0@0.0 . 60@1.0 . 310@1.0 . 350@0.0} 
								loopStart: 2 loopEnd: 3).

	env := Envelope 
			points: { 0@0.0167 . 60@0.106 . 310@0.106 . 350@0.0 } 
			loopStart: 2 loopEnd: 3.
	env updateSelector: #modulation:; scale: 10.0.
	sound addEnvelope: env.

	^ sound setPitch: 220.0 dur: 1.0 loudness: 0.5


]

{ #category : #instruments }
FMSound class >> default [

	^ self oboe1

]

{ #category : #instruments }
FMSound class >> flute1 [
	"FMSound flute1 play"
	"(FMSound majorScaleOn: FMSound flute1) play"

	| sound  |
	sound := FMSound new.
	
	sound addEnvelope: (VolumeEnvelope points: {0@0 . 20@1.0 . 100@1.0 . 120@0.0} loopStart: 2 loopEnd: 3).
	^ sound setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> flute2 [
	"FMSound flute2 play"
	"(FMSound majorScaleOn: FMSound flute2) play"

	| sound  |
	sound := FMSound new.
	sound addEnvelope: (VolumeEnvelope points: {0@0 . 20@1.0 . 100@1.0 . 120@0.0} loopStart: 2 loopEnd: 3).
	sound addEnvelope: (RandomEnvelope for: #pitch:).
	^ sound setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #initialization }
FMSound class >> initialize [
	"Build a sine wave table."
	"self initialize"

	| tableSize radiansPerStep peak |
	tableSize := 4000.
	SineTable := SoundBuffer newMonoSampleCount: tableSize.
	radiansPerStep := (2.0 * Float pi) / tableSize asFloat.
	peak := ((1 bitShift: 15) - 1) asFloat.  "range is +/- (2^15 - 1)"
	1 to: tableSize do: [:i |
		SineTable at: i put: (peak * (radiansPerStep * (i - 1)) sin) rounded].

]

{ #category : #instruments }
FMSound class >> marimba [
	"FMSound marimba play"
	"(FMSound majorScaleOn: FMSound marimba) play"

	| sound  env |
	sound := FMSound new modulation: 1 ratio: 0.98.
	sound addEnvelope: (VolumeEnvelope points: 	{0@1.0 . 10@0.3 . 40@0.1 . 80@0.02 . 120@0.1 . 160@0.02 . 220@0.0} loopStart: 4 loopEnd: 6).
	env := Envelope points: { 0@1.2 . 80@0.85 . 120@1.0 . 160@0.85 . 220@0.0} loopStart: 2 loopEnd: 4.
	env updateSelector: #modulation:.
	sound addEnvelope: env.

	^ sound setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> mellowBrass [
	"FMSound mellowBrass play"
	"(FMSound lowMajorScaleOn: FMSound mellowBrass) play"

	| sound  env |
	sound := FMSound new modulation: 0 ratio: 1.


	sound addEnvelope: (VolumeEnvelope points: 	{ 0@0.0 . 70@0.325 . 120@0.194 . 200@0.194 . 320@0.194 . 380@0.0} loopStart: 3 loopEnd: 5).

	env := Envelope points: { 0@0.1 . 70@0.68 . 120@0.528 . 200@0.519 . 320@0.528 . 380@0.0} loopStart: 3 loopEnd: 5.
	env updateSelector: #modulation:; scale: 5.0.
	sound addEnvelope: env.

	^ sound setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> oboe1 [
	"FMSound oboe1 play"
	"(FMSound majorScaleOn: FMSound oboe1) play"

	| sound  |
	sound := FMSound new modulation: 1 ratio: 1.
	
	sound addEnvelope: (VolumeEnvelope points: {0@0.0 . 10@1.0 . 100@1.0 . 120@0.0} loopStart: 2 loopEnd: 3).
	^ sound setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> oboe2 [
	"FMSound oboe2 play"
	"(FMSound majorScaleOn: FMSound oboe2) play"

	| sound  |
	sound := FMSound new modulation: 1 ratio: 1.
	
	sound addEnvelope: (VolumeEnvelope points: {  0@0 . 20@1.0 . 100@1.0 . 120@0.0} loopStart: 2 loopEnd: 3).
	sound addEnvelope: (RandomEnvelope for: #pitch:).
	^ sound setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> organ1 [
	"FMSound organ1 play"
	"(FMSound majorScaleOn: FMSound organ1) play"

	| sound |
	sound := self new.
	sound addEnvelope: 
			(VolumeEnvelope 
				points: {0@0 . 60@1.0 . 110@0.8 . 200@1.0 . 250@0.0} 
				loopStart: 2 
				loopEnd: 4).
	sound setPitch: 440.0 dur: 1.0 loudness: 0.5.
	^ sound

]

{ #category : #instruments }
FMSound class >> pluckedElecBass [
	"FMSound pluckedElecBass play"
	"(FMSound lowMajorScaleOn: FMSound pluckedElecBass) play"

	| soound  env |
	soound := self new modulation: 1 ratio: 3.0.
	soound addEnvelope: (VolumeEnvelope 
								points: { 0@0.4 . 20@1.0 . 30@0.6 . 100@0.6 . 130@0.0} loopStart: 3 loopEnd: 4).
	env := Envelope points: { 0@1.0 . 20@2.0 . 30@4.5 . 100@4.5 . 130@0.0} loopStart: 3 loopEnd: 4.
	env updateSelector: #modulation:.
	soound addEnvelope: env.

	env := Envelope points: { 0@6.0 . 20@4.0 . 30@3.0 . 100@3.0 .  130@3.0} loopStart: 3 loopEnd: 4.
	env updateSelector: #ratio:.
	soound addEnvelope: env.

	^ soound setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> randomWeird1 [
	"FMSound randomWeird1 play"

	| sound  |
	sound := FMSound new.
	sound addEnvelope: (VolumeEnvelope exponentialDecay: 0.96).
	sound addEnvelope: (PitchEnvelope points: { 0@0 . 100@1.0 . 250@0.7 . 400@1.0 . 500@0} loopStart: 2 loopEnd: 4).
	^ sound setPitch: (150 + 2000 atRandom) dur: 2.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> randomWeird2 [
	"FMSound randomWeird2 play"

	| sound |
	sound := FMSound new.
	sound addEnvelope: (VolumeEnvelope exponentialDecay: 0.96).
	sound addEnvelope: (PitchEnvelope exponentialDecay: 0.98).
	^ sound setPitch: (150 + 2000 atRandom) dur: 2.0 loudness: 0.5

]

{ #category : #initialization }
FMSound class >> sineTable [
	"Answer a SoundBuffer containing one complete cycle of a sine wave."

	^ SineTable

]

{ #category : #accessing }
FMSound >> duration [

	^ initialCount asFloat / self samplingRate asFloat

]

{ #category : #accessing }
FMSound >> duration: seconds [

	super duration: seconds.
	count := initialCount := (seconds * self samplingRate) rounded.

]

{ #category : #initialization }
FMSound >> initialize [

	super initialize.
	waveTable := SineTable.
	scaledWaveTableSize := waveTable size * ScaleFactor.
	self setPitch: 440.0 dur: 1.0 loudness: 0.2.

]

{ #category : #operation }
FMSound >> internalizeModulationAndRatio [
	"Recompute the internal state for the modulation index and frequency ratio relative to the current pitch."

	modulation < 0.0 ifTrue: [modulation := modulation negated].
	multiplier < 0.0 ifTrue: [multiplier := multiplier negated].
	normalizedModulation :=
		((modulation * scaledIndexIncr)  / ScaleFactor) asInteger.
	scaledOffsetIndexIncr := (multiplier * scaledIndexIncr) asInteger.

	"clip to maximum values if necessary"
	normalizedModulation > MaxScaledValue ifTrue: [
		normalizedModulation := MaxScaledValue.
		modulation := (normalizedModulation * ScaleFactor) asFloat / scaledIndexIncr].
	scaledOffsetIndexIncr > (scaledWaveTableSize // 2) ifTrue: [
		scaledOffsetIndexIncr := scaledWaveTableSize // 2.
		multiplier := scaledOffsetIndexIncr asFloat / scaledIndexIncr].

]

{ #category : #'sound generation' }
FMSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Play samples from a wave table by stepping a fixed amount through the table on every sample. The table index and increment are scaled to allow fractional increments for greater pitch accuracy."
	"(FMSound pitch: 440.0 dur: 1.0 loudness: 0.5) play"

	| doingFM lastIndex sample offset i s |
	<primitive:'primitiveMixFMSound' module:'SoundGenerationPlugin'>
	
	<var: #aSoundBuffer declareC: 'short int *aSoundBuffer'>
	<var: #waveTable declareC: 'short int *waveTable'>

	doingFM := (normalizedModulation ~= 0) and: [scaledOffsetIndexIncr ~= 0].
	lastIndex := (startIndex + n) - 1.
	startIndex to: lastIndex do: [:sliceIndex |
		sample := (scaledVol * (waveTable at: (scaledIndex // ScaleFactor) + 1)) // ScaleFactor.
		doingFM
			ifTrue: [
				offset := normalizedModulation * (waveTable at: (scaledOffsetIndex // ScaleFactor) + 1).
				scaledOffsetIndex := (scaledOffsetIndex + scaledOffsetIndexIncr) \\ scaledWaveTableSize.
				scaledOffsetIndex < 0
					ifTrue: [scaledOffsetIndex := scaledOffsetIndex + scaledWaveTableSize].
				scaledIndex := (scaledIndex + scaledIndexIncr + offset) \\ scaledWaveTableSize.
				scaledIndex < 0
					ifTrue: [scaledIndex := scaledIndex + scaledWaveTableSize]]
			ifFalse: [
				scaledIndex := (scaledIndex + scaledIndexIncr) \\ scaledWaveTableSize].

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

	count := count - n.

]

{ #category : #accessing }
FMSound >> modulation [
	"Return the FM modulation index."

	^ modulation ifNil: [modulation := 0.0].


]

{ #category : #accessing }
FMSound >> modulation: mod [
	"Set the FM modulation index. Typical values range from 0 (no modulation) to 5, although values up to about 10 are sometimes useful."
	"Warning: This method is intended primarily for use by envelopes. For efficiency during envelope processing, this change will not take effect until internalizeModulationAndRatio is called."

	modulation := mod asFloat.

]

{ #category : #accessing }
FMSound >> modulation: mod multiplier: freqRatio [
	"For backward compatibility. Needed to read old .fmp files."

	self modulation: mod ratio: freqRatio.

]

{ #category : #accessing }
FMSound >> modulation: mod ratio: freqRatio [
	"Set the modulation index and carrier to modulation frequency ratio for this sound, and compute the internal state that depends on these parameters."

	modulation := mod asFloat.
	multiplier := freqRatio asFloat.
	self internalizeModulationAndRatio.

]

{ #category : #accessing }
FMSound >> multiplier [

	^ 	multiplier ifNil: [multiplier := 0.0].

]

{ #category : #accessing }
FMSound >> pitch [

	^ (self samplingRate asFloat * scaledIndexIncr / ScaleFactor) asFloat / waveTable size

]

{ #category : #accessing }
FMSound >> pitch: p [
	"Warning: Since the modulation and ratio are relative to the current pitch, some internal state must be recomputed when the pitch is changed. However, for efficiency during envelope processing, this compuation will not be done until internalizeModulationAndRatio is called."

	scaledIndexIncr :=
		((p asFloat * waveTable size asFloat * ScaleFactor asFloat) / self samplingRate asFloat) asInteger
			min: (waveTable size // 2) * ScaleFactor.

]

{ #category : #accessing }
FMSound >> ratio [
	"Return the FM modulation to carrier frequency ratio."

	^ multiplier

]

{ #category : #accessing }
FMSound >> ratio: freqRatio [
	"Set the FM modulation to carrier frequency ratio."
	"Warning: This method is intended primarily for use by envelopes. For efficiency during envelope processing, this change will not take effect until internalizeModulationAndRatio is called."

	multiplier := freqRatio asFloat.

]

{ #category : #'sound generation' }
FMSound >> reset [

	self internalizeModulationAndRatio.
	super reset.
	count := initialCount.
	scaledIndex := 0.
	scaledOffsetIndex := 0.

]

{ #category : #'sound generation' }
FMSound >> samplesRemaining [

	^ count

]

{ #category : #initialization }
FMSound >> setPitch: pitchNameOrNumber dur: d loudness: vol [
	"(FMSound pitch: 'a4' dur: 2.5 loudness: 0.4) play"

	super setPitch: pitchNameOrNumber dur: d loudness: vol.
	modulation ifNil: [modulation := 0.0].
	multiplier ifNil: [multiplier := 0.0].
		"ugly!"
	self pitch: (self nameOrNumberToPitch: pitchNameOrNumber).
	self reset.

]

{ #category : #initialization }
FMSound >> setWavetable: anArray [
	"(AbstractSound lowMajorScaleOn: (FMSound new setWavetable: AA)) play"

	| samples p dur vol |
	"copy the array into a SoundBuffer if necessary"
	anArray class isPointers
		ifTrue: [samples := SoundBuffer fromArray: anArray]
		ifFalse: [samples := anArray].

	p := self pitch.
	dur := self duration.
	vol := self loudness.
	waveTable := samples.
	scaledWaveTableSize := waveTable size * ScaleFactor.
	self setPitch: p dur: dur loudness: vol.

]

{ #category : #'sound generation' }
FMSound >> stopAfterMSecs: mSecs [
	"Terminate this sound this note after the given number of milliseconds."

	count := (mSecs * self samplingRate) // 1000.

]

{ #category : #storing }
FMSound >> storeOn: strm [
	| env |
	strm nextPutAll: '(((FMSound';
		nextPutAll: ' pitch: '; print: self pitch;
		nextPutAll: ' dur: '; print: self duration;
		nextPutAll: ' loudness: '; print: self loudness; nextPutAll: ')';
		nextPutAll: ' modulation: '; print: self modulation;
		nextPutAll: ' ratio: '; print: self ratio; nextPutAll: ')'.
	1 to: envelopes size do:
		[:i | env := envelopes at: i.
		strm cr; nextPutAll: '    addEnvelope: '. env storeOn: strm.
		i < envelopes size ifTrue: [strm nextPutAll: ';']].
	strm  nextPutAll: ')'.

]
