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

	| snd |
	snd := FMSound new modulation: 0 ratio: 0.
	snd addEnvelope: (VolumeEnvelope exponentialDecay: 0.95).
	^ snd setPitch: 220 dur: 1.0 loudness: 0.3

]

{ #category : #instruments }
FMSound class >> bassoon1 [
	"FMSound bassoon1 play"
	"(FMSound lowMajorScaleOn: FMSound bassoon1) play"

	| snd p env |
	snd := FMBassoonSound new ratio: 1.

	p := OrderedCollection new.
	p add: 0@0.0; add: 40@0.45; add: 90@1.0; add: 180@0.9; add: 270@1.0; add: 320@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 3 loopEnd: 5).

	p := OrderedCollection new.
	p add: 0@0.2; add: 40@0.9; add: 90@0.6; add: 270@0.6; add: 320@0.5.
	env := Envelope points: p loopStart: 3 loopEnd: 4.
	env updateSelector: #modulation:; scale: 5.05.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> brass1 [
	"FMSound brass1 play"
	"(FMSound lowMajorScaleOn: FMSound brass1) play"

	| snd p env |
	snd := FMSound new modulation: 0 ratio: 1.
	p := OrderedCollection new.
	p add: 0@0.0; add: 30@0.8; add: 90@1.0; add: 120@0.9; add: 220@0.7; add: 320@0.9; add: 360@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 4 loopEnd: 6).

	p := OrderedCollection new.
	p add: 0@0.5; add: 60@1.0; add: 120@0.8; add: 220@0.65; add: 320@0.8; add: 360@0.0.
	env := Envelope points: p loopStart: 3 loopEnd: 5.
	env target: snd; updateSelector: #modulation:; scale: 5.0.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> brass2 [
	"FMSound brass2 play"
	"(FMSound lowMajorScaleOn: FMSound brass2) play"

	| snd p env |
	snd := FMSound new modulation: 1 ratio: 1.

	p := OrderedCollection new.
	p add: 0@0.0; add: 20@1.0; add: 40@0.9; add: 100@0.7; add: 160@0.9; add: 200@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 3 loopEnd: 5).

	p := OrderedCollection new.
	p add: 0@0.5; add: 30@1.0; add: 40@0.8; add: 100@0.7; add: 160@0.8; add: 200@0.0.
	env := Envelope points: p loopStart: 3 loopEnd: 5.
	env updateSelector: #modulation:; scale: 5.0.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> clarinet [
	"FMSound clarinet play"
	"(FMSound lowMajorScaleOn: FMSound clarinet) play"

	| snd p env |
	snd := FMSound new modulation: 0 ratio: 2.

	p := OrderedCollection new.
	p add: 0@0.0; add: 60@1.0; add: 310@1.0; add: 350@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3).

	p := OrderedCollection new.
	p add: 0@0.0167; add: 60@0.106; add: 310@0.106; add: 350@0.0.
	env := Envelope points: p loopStart: 2 loopEnd: 3.
	env updateSelector: #modulation:; scale: 10.0.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> clarinet2 [
	"FMSound clarinet2 play"
	"(FMSound lowMajorScaleOn: FMSound clarinet2) play"

	| snd p env |
	snd := FMClarinetSound new modulation: 0 ratio: 2.

	p := OrderedCollection new.
	p add: 0@0.0; add: 60@1.0; add: 310@1.0; add: 350@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3).

	p := OrderedCollection new.
	p add: 0@0.0167; add: 60@0.106; add: 310@0.106; add: 350@0.0.
	env := Envelope points: p loopStart: 2 loopEnd: 3.
	env updateSelector: #modulation:; scale: 10.0.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5


]

{ #category : #instruments }
FMSound class >> default [

	^ self oboe1

]

{ #category : #instruments }
FMSound class >> flute1 [
	"FMSound flute1 play"
	"(FMSound majorScaleOn: FMSound flute1) play"

	| snd p |
	snd := FMSound new.
	p := OrderedCollection new.
	p add: 0@0; add: 20@1.0; add: 100@1.0; add: 120@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3).
	^ snd setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> flute2 [
	"FMSound flute2 play"
	"(FMSound majorScaleOn: FMSound flute2) play"

	| snd p |
	snd := FMSound new.
	p := OrderedCollection new.
	p add: 0@0; add: 20@1.0; add: 100@1.0; add: 120@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3).
	snd addEnvelope: (RandomEnvelope for: #pitch:).
	^ snd setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #initialization }
FMSound class >> initialize [
	"Build a sine wave table."
	"FMSound initialize"

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

	| snd p env |
	snd := FMSound new modulation: 1 ratio: 0.98.

	p := OrderedCollection new.
	p add: 0@1.0; add: 10@0.3; add: 40@0.1; add: 80@0.02; add: 120@0.1; add: 160@0.02; add: 220@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 4 loopEnd: 6).

	p := OrderedCollection new.
	p add: 0@1.2; add: 80@0.85; add: 120@1.0; add: 160@0.85; add: 220@0.0.
	env := Envelope points: p loopStart: 2 loopEnd: 4.
	env updateSelector: #modulation:.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> mellowBrass [
	"FMSound mellowBrass play"
	"(FMSound lowMajorScaleOn: FMSound mellowBrass) play"

	| snd p env |
	snd := FMSound new modulation: 0 ratio: 1.

	p := OrderedCollection new.
	p add: 0@0.0; add: 70@0.325; add: 120@0.194; add: 200@0.194; add: 320@0.194; add: 380@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 3 loopEnd: 5).

	p := OrderedCollection new.
	p add: 0@0.1; add: 70@0.68; add: 120@0.528; add: 200@0.519; add: 320@0.528; add: 380@0.0.
	env := Envelope points: p loopStart: 3 loopEnd: 5.
	env updateSelector: #modulation:; scale: 5.0.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> oboe1 [
	"FMSound oboe1 play"
	"(FMSound majorScaleOn: FMSound oboe1) play"

	| snd p |
	snd := FMSound new modulation: 1 ratio: 1.
	p := OrderedCollection new.
	p add: 0@0.0; add: 10@1.0; add: 100@1.0; add: 120@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3).
	^ snd setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> oboe2 [
	"FMSound oboe2 play"
	"(FMSound majorScaleOn: FMSound oboe2) play"

	| snd p |
	snd := FMSound new modulation: 1 ratio: 1.
	p := OrderedCollection new.
	p add: 0@0; add: 20@1.0; add: 100@1.0; add: 120@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3).
	snd addEnvelope: (RandomEnvelope for: #pitch:).
	^ snd setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> organ1 [
	"FMSound organ1 play"
	"(FMSound majorScaleOn: FMSound organ1) play"

	| snd p |
	snd := FMSound new.
	p := OrderedCollection new.
	p add: 0@0; add: 60@1.0; add: 110@0.8; add: 200@1.0; add: 250@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 4).
	^ snd setPitch: 440.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> pluckedElecBass [
	"FMSound pluckedElecBass play"
	"(FMSound lowMajorScaleOn: FMSound pluckedElecBass) play"

	| snd p env |
	snd := FMSound new modulation: 1 ratio: 3.0.

	p := OrderedCollection new.
	p add: 0@0.4; add: 20@1.0; add: 30@0.6; add: 100@0.6; add: 130@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 3 loopEnd: 4).

	p := OrderedCollection new.
	p add: 0@1.0; add: 20@2.0; add: 30@4.5; add: 100@4.5; add: 130@0.0.
	env := Envelope points: p loopStart: 3 loopEnd: 4.
	env updateSelector: #modulation:.
	snd addEnvelope: env.

	p := OrderedCollection new.
	p add: 0@6.0; add: 20@4.0; add: 30@3.0; add: 100@3.0; add: 130@3.0.
	env := Envelope points: p loopStart: 3 loopEnd: 4.
	env updateSelector: #ratio:.
	snd addEnvelope: env.

	^ snd setPitch: 220.0 dur: 1.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> randomWeird1 [
	"FMSound randomWeird1 play"

	| snd p |
	snd := FMSound new.
	snd addEnvelope: (VolumeEnvelope exponentialDecay: 0.96).
	p := Array with: 0@0 with: 100@1.0 with: 250@0.7 with: 400@1.0 with: 500@0.
	snd addEnvelope: (PitchEnvelope points: p loopStart: 2 loopEnd: 4).
	^ snd setPitch: (150 + 2000 atRandom) dur: 2.0 loudness: 0.5

]

{ #category : #instruments }
FMSound class >> randomWeird2 [
	"FMSound randomWeird2 play"

	| snd |
	snd := FMSound new.
	snd addEnvelope: (VolumeEnvelope exponentialDecay: 0.96).
	snd addEnvelope: (PitchEnvelope exponentialDecay: 0.98).
	^ snd setPitch: (150 + 2000 atRandom) dur: 2.0 loudness: 0.5

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

{ #category : #accessing }
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

	^ modulation

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

	^ multiplier

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
