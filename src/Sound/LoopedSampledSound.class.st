"
I respresent a sequence of sound samples, often used to record a single note played by a real instrument. I can be pitch-shifted up or down, and can include a looped portion to allow a sound to be sustained indefinitely.

"
Class {
	#name : #LoopedSampledSound,
	#superclass : #AbstractSound,
	#instVars : [
		'initialCount',
		'count',
		'releaseCount',
		'sampleCountForRelease',
		'leftSamples',
		'rightSamples',
		'originalSamplingRate',
		'perceivedPitch',
		'gain',
		'firstSample',
		'lastSample',
		'loopEnd',
		'scaledLoopLength',
		'scaledIndex',
		'scaledIndexIncr'
	],
	#classVars : [
		'FloatLoopIndexScaleFactor',
		'LoopIndexFractionMask',
		'LoopIndexScaleFactor'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #'instance creation' }
LoopedSampledSound class >> fromAIFFFileNamed: fileName mergeIfStereo: mergeFlag [
	"Initialize this sound from the data in the given AIFF file. If mergeFlag is true and the file is stereo, its left and right channels are mixed together to produce a mono sampled sound."

	| aiffFileReader |
	aiffFileReader := AIFFFileReader new.
	aiffFileReader readFromFile: fileName
		mergeIfStereo: mergeFlag
		skipDataChunk: false.
	self new fromAIFFFileReader: aiffFileReader mergeIfStereo: mergeFlag
]

{ #category : #initialization }
LoopedSampledSound class >> initialize [
	"LoopedSampledSound initialize"

	LoopIndexScaleFactor := 512.
	FloatLoopIndexScaleFactor := LoopIndexScaleFactor asFloat.
	LoopIndexFractionMask := LoopIndexScaleFactor - 1.

]

{ #category : #'instance creation' }
LoopedSampledSound class >> samples: aSoundBuffer loopEnd: loopEndIndex loopLength: loopSampleCount pitch: perceivedPitchInHz samplingRate: samplingRateInHz [
	"See the comment in the instance method of this name."

	^ self basicNew
		samples: aSoundBuffer
		loopEnd: loopEndIndex
		loopLength: loopSampleCount
		pitch: perceivedPitchInHz
		samplingRate: samplingRateInHz

]

{ #category : #'instance creation' }
LoopedSampledSound class >> unloopedSamples: aSoundBuffer pitch: perceivedPitchInHz samplingRate: samplingRateInHz [
	"See the comment in the instance method of this name."

	^ self basicNew
		unloopedSamples: aSoundBuffer
		pitch: perceivedPitchInHz
		samplingRate: samplingRateInHz

]

{ #category : #initialization }
LoopedSampledSound >> addReleaseEnvelope [
	"Add a simple release envelope to this sound."

	| p env |
	p := OrderedCollection new.
	p add: 0@1.0; add: 10@1.0; add: 100@1.0; add: 120@0.0.
	env := (VolumeEnvelope points: p loopStart: 2 loopEnd: 3) target: self.
	envelopes size > 0 ifTrue: [  "remove any existing volume envelopes"
		envelopes copy do: [:e |
			(e isKindOf: VolumeEnvelope) ifTrue: [self removeEnvelope: e]]].
	self addEnvelope: env.

]

{ #category : #accessing }
LoopedSampledSound >> beUnlooped [

	scaledLoopLength := 0.

]

{ #category : #'disk i/o' }
LoopedSampledSound >> comeFullyUpOnReload: smartRefStream [
	"Convert my sample buffers from ByteArrays into SampleBuffers after raw loading from a DataStream. Answer myself."

	leftSamples == rightSamples
		ifTrue: [
			leftSamples := SoundBuffer fromByteArray: self leftSamples.
			rightSamples := leftSamples]
		ifFalse: [
			leftSamples := SoundBuffer fromByteArray: self leftSamples.
			rightSamples := SoundBuffer fromByteArray: self rightSamples].


]

{ #category : #initialization }
LoopedSampledSound >> computeSampleCountForRelease [
	"Calculate the number of samples before the end of the note after which looping back will be be disabled. The units of this value, sampleCountForRelease, are samples at the original sampling rate. When playing a specific note, this value is converted to releaseCount, which is number of samples to be computed at the current pitch and sampling rate."
	"Details: For short loops, set the sampleCountForRelease to the loop length plus the number of samples between loopEnd and lastSample. Otherwise, set it to 1/10th of a second worth of samples plus the number of samples between loopEnd and lastSample. In this case, the trailing samples will be played only if the last loop-back occurs within 1/10th of a second of the total note duration, and the note may be shortened by up to 1/10th second. For long loops, this is the best we can do."

	(scaledLoopLength > 0 and: [lastSample > loopEnd])
		ifTrue: [
			sampleCountForRelease := (lastSample - loopEnd) +
				(self loopLength min: (originalSamplingRate / 10.0)) asInteger]
		ifFalse: [sampleCountForRelease := 0].

	releaseCount := sampleCountForRelease.

]

{ #category : #other }
LoopedSampledSound >> copyDownSampledLowPassFiltering: doFiltering [
	"Answer a copy of the receiver at half its sampling rate. The result consumes half the memory space, but has only half the frequency range of the original. If doFiltering is true, the original sound buffers are low-pass filtered before down-sampling. This is slower, but prevents aliasing of any high-frequency components of the original signal. (While it may be possible to avoid low-pass filtering when down-sampling from 44.1 kHz to 22.05 kHz, it is probably essential when going to lower sampling rates.)"

	^ self copy downSampleLowPassFiltering: doFiltering

]

{ #category : #private }
LoopedSampledSound >> downSampleLowPassFiltering: doFiltering [
	"Cut my sampling rate in half. Use low-pass filtering (slower) if doFiltering is true."
	"Note: This operation loses information, and modifies the receiver in place."

	| stereo newLoopLength |
	stereo := self isStereo.
	leftSamples := leftSamples downSampledLowPassFiltering: doFiltering.
	stereo
		ifTrue: [rightSamples := rightSamples downSampledLowPassFiltering: doFiltering]
		ifFalse: [rightSamples := leftSamples].
	originalSamplingRate := originalSamplingRate / 2.0.
	loopEnd odd
		ifTrue: [newLoopLength := (self loopLength / 2.0) + 0.5]
		ifFalse: [newLoopLength := self loopLength / 2.0].
	firstSample := (firstSample + 1) // 2.
	lastSample := (lastSample + 1) // 2.
	loopEnd := (loopEnd + 1) // 2.
	scaledLoopLength := (newLoopLength * LoopIndexScaleFactor) asInteger.
	scaledIndexIncr := scaledIndexIncr // 2.

]

{ #category : #accessing }
LoopedSampledSound >> duration [
	"Answer the duration of this sound in seconds."

	^ initialCount asFloat / self samplingRate asFloat

]

{ #category : #accessing }
LoopedSampledSound >> duration: seconds [

	super duration: seconds.
	count := initialCount := (seconds * self samplingRate) rounded.

]

{ #category : #other }
LoopedSampledSound >> fftAt: startIndex [
	"Answer the Fast Fourier Transform (FFT) of my samples (only the left channel, if stereo) starting at the given index."

	| availableSamples fftWinSize |
	availableSamples := (leftSamples size - startIndex) + 1.
	fftWinSize := 2 raisedTo: (((availableSamples - 1) log: 2) truncated + 1).
	fftWinSize := fftWinSize min: 4096.
	fftWinSize > availableSamples ifTrue: [fftWinSize := fftWinSize / 2].
	^ self fftWindowSize: fftWinSize startingAt: startIndex

]

{ #category : #private }
LoopedSampledSound >> fftWindowSize: windowSize startingAt: startIndex [
	"Answer a Fast Fourier Transform (FFT) of the given number of samples starting at the given index (the left channel only, if stereo). The window size will be rounded up to the nearest power of two greater than the requested size. There must be enough samples past the given starting index to accomodate this window size."

	| nu n fft |
	nu := ((windowSize - 1) log: 2) truncated + 1.
	n := 2 raisedTo: nu.
	fft := FFT new nu: nu.
	fft realData: ((startIndex to: startIndex + n - 1) collect: [:i | leftSamples at: i]).
	^ fft transformForward: true.

]

{ #category : #other }
LoopedSampledSound >> findStartPointAfter: index [
	"Answer the index of the last zero crossing sample before the given index."

	| i |
	i := index min: lastSample.

	"scan backwards to the last zero-crossing"
	(leftSamples at: i) > 0
		ifTrue: [
			[i > 1 and: [(leftSamples at: i) > 0]] whileTrue: [i := i - 1]]
		ifFalse: [
			[i > 1 and: [(leftSamples at: i) < 0]] whileTrue: [i := i - 1]].
	^ i

]

{ #category : #other }
LoopedSampledSound >> findStartPointForThreshold: threshold [
	"Answer the index of the last zero crossing sample before the first sample whose absolute value (in either the right or left channel) exceeds the given threshold."

	| i |
	i := self indexOfFirstPointOverThreshold: threshold.
	i >= lastSample ifTrue: [^ self error: 'no sample exceeds the given threshold'].

	"scan backwards to the last zero-crossing"
	(leftSamples at: i) > 0
		ifTrue: [
			[i > 1 and: [(leftSamples at: i) > 0]] whileTrue: [i := i - 1]]
		ifFalse: [
			[i > 1 and: [(leftSamples at: i) < 0]] whileTrue: [i := i - 1]].
	^ i

]

{ #category : #accessing }
LoopedSampledSound >> firstSample [

	^ firstSample

]

{ #category : #accessing }
LoopedSampledSound >> firstSample: aNumber [

	firstSample := (aNumber asInteger max: 1) min: lastSample.

]

{ #category : #initialization }
LoopedSampledSound >> fromAIFFFileNamed: fileName mergeIfStereo: mergeFlag [
	"Initialize this sound from the data in the given AIFF file. If mergeFlag is true and the file is stereo, its left and right channels are mixed together to produce a mono sampled sound."

	| aiffFileReader |
	aiffFileReader := AIFFFileReader new.
	aiffFileReader readFromFile: fileName
		mergeIfStereo: mergeFlag
		skipDataChunk: false.
	aiffFileReader isLooped
		ifTrue: [
			self samples: aiffFileReader leftSamples
				loopEnd: aiffFileReader loopEnd
				loopLength: aiffFileReader loopLength
				pitch: aiffFileReader pitch
				samplingRate: aiffFileReader samplingRate]
		ifFalse: [
			self unloopedSamples: aiffFileReader leftSamples
				pitch: aiffFileReader pitch
				samplingRate: aiffFileReader samplingRate].

	"the following must be done second, since the initialization above sets
	 leftSamples and rightSamples to the same sample data"
	aiffFileReader isStereo
		ifTrue: [rightSamples := aiffFileReader rightSamples].

	initialCount := (leftSamples size * self samplingRate) // originalSamplingRate.
	self loudness: 1.0.

	self addReleaseEnvelope.

]

{ #category : #initialization }
LoopedSampledSound >> fromAIFFFileReader: aiffFileReader mergeIfStereo: mergeFlag [
	"Initialize this sound from the data in the given AIFF file. If mergeFlag is true and the file is stereo, its left and right channels are mixed together to produce a mono sampled sound."

	aiffFileReader isLooped
		ifTrue: [
			self samples: aiffFileReader leftSamples
				loopEnd: aiffFileReader loopEnd
				loopLength: aiffFileReader loopLength
				pitch: aiffFileReader pitch
				samplingRate: aiffFileReader samplingRate]
		ifFalse: [
			self unloopedSamples: aiffFileReader leftSamples
				pitch: aiffFileReader pitch
				samplingRate: aiffFileReader samplingRate].

	"the following must be done second, since the initialization above sets
	 leftSamples and rightSamples to the same sample data"
	aiffFileReader isStereo
		ifTrue: [rightSamples := aiffFileReader rightSamples].

	initialCount := (leftSamples size * self samplingRate) // originalSamplingRate.
	self loudness: 1.0.

	self addReleaseEnvelope.

]

{ #category : #accessing }
LoopedSampledSound >> gain [

	^ gain

]

{ #category : #accessing }
LoopedSampledSound >> gain: aNumber [

	gain := aNumber asFloat.

]

{ #category : #other }
LoopedSampledSound >> highestSignificantFrequencyAt: startIndex [
	"Answer the highest significant frequency in the sample window starting at the given index. The a frequency is considered significant if it's power is at least 1/50th that of the maximum frequency component in the frequency spectrum."

	| fft powerArray threshold indices |
	fft := self fftAt: startIndex.
	powerArray := self normalizedResultsFromFFT: fft.
	threshold := powerArray max / 50.0.
	indices := (1 to: powerArray size) select: [:i | (powerArray at: i) > threshold].
	^ originalSamplingRate / (fft samplesPerCycleForIndex: indices last)

]

{ #category : #other }
LoopedSampledSound >> indexOfFirstPointOverThreshold: threshold [
	"Answer the index of the first sample whose absolute value exceeds the given threshold."

	| s |
	leftSamples == rightSamples
		ifTrue: [
			1 to: lastSample do: [:i |
				s := leftSamples at: i.
				s < 0 ifTrue: [s := 0 - s].
				s > threshold ifTrue: [^ i]]]
		ifFalse: [
			1 to: lastSample do: [:i |
				s := leftSamples at: i.
				s < 0 ifTrue: [s := 0 - s].
				s > threshold ifTrue: [^ i].
				s := rightSamples at: i.
				s < 0 ifTrue: [s := 0 - s].
				s > threshold ifTrue: [^ i]]].
	^ lastSample + 1

]

{ #category : #initialization }
LoopedSampledSound >> initialize [
	"This default initialization creates a loop consisting of a single cycle of a sine wave."
	"(LoopedSampledSound pitch: 440.0 dur: 1.0 loudness: 0.4) play"

	| samples |
	super initialize.
	samples := FMSound sineTable.
	self samples: samples
		loopEnd: samples size
		loopLength: samples size
		pitch: 1.0
		samplingRate: samples size.
	self addReleaseEnvelope.
	self setPitch: 440.0 dur: 1.0 loudness: 0.5.

]

{ #category : #accessing }
LoopedSampledSound >> isLooped [

	^ scaledLoopLength ~= 0.  "zero loop length means unlooped"

]

{ #category : #accessing }
LoopedSampledSound >> isStereo [

	^ leftSamples ~~ rightSamples

]

{ #category : #accessing }
LoopedSampledSound >> leftSamples [

	^ leftSamples

]

{ #category : #accessing }
LoopedSampledSound >> leftSamples: aSampleBuffer [

	leftSamples := aSampleBuffer.

]

{ #category : #accessing }
LoopedSampledSound >> loopEnd [

	^ loopEnd

]

{ #category : #accessing }
LoopedSampledSound >> loopLength [

	^ scaledLoopLength / FloatLoopIndexScaleFactor

]

{ #category : #'sound generation' }
LoopedSampledSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Play samples from a wave table by stepping a fixed amount through the table on every sample. The table index and increment are scaled to allow fractional increments for greater pitch accuracy.  If a loop length is specified, then the index is looped back when the loopEnd index is reached until count drops below releaseCount. This allows a short sampled sound to be sustained indefinitely."
	"(LoopedSampledSound pitch: 440.0 dur: 5.0 loudness: 0.5) play"

	| lastIndex sampleIndex i s compositeLeftVol compositeRightVol nextSampleIndex m isInStereo rightVal leftVal |
	<primitive:'primitiveMixLoopedSampledSound' module:'SoundGenerationPlugin'>
	<var: #aSoundBuffer declareC: 'short int *aSoundBuffer'>
	<var: #leftSamples declareC: 'short int *leftSamples'>
	<var: #rightSamples declareC: 'short int *rightSamples'>

	isInStereo := leftSamples ~~ rightSamples.
	compositeLeftVol := (leftVol * scaledVol) // ScaleFactor.
	compositeRightVol :=  (rightVol * scaledVol) // ScaleFactor.

	i := (2 * startIndex) - 1.
	lastIndex := (startIndex + n) - 1.
	startIndex to: lastIndex do: [:sliceIndex |
		sampleIndex := (scaledIndex := scaledIndex + scaledIndexIncr) // LoopIndexScaleFactor.
		((sampleIndex > loopEnd) and: [count > releaseCount]) ifTrue: [
			"loop back if not within releaseCount of the note end"
			"note: unlooped sounds will have loopEnd = lastSample"
			sampleIndex := (scaledIndex := scaledIndex - scaledLoopLength) // LoopIndexScaleFactor].
		(nextSampleIndex := sampleIndex + 1) > lastSample ifTrue: [
			sampleIndex > lastSample ifTrue: [count := 0. ^ nil].  "done!"
			scaledLoopLength = 0
				ifTrue: [nextSampleIndex := sampleIndex]
				ifFalse: [nextSampleIndex := ((scaledIndex - scaledLoopLength) // LoopIndexScaleFactor) + 1]].

		m := scaledIndex bitAnd: LoopIndexFractionMask.
		rightVal := leftVal :=
			(((leftSamples at: sampleIndex) * (LoopIndexScaleFactor - m)) +
			 ((leftSamples at: nextSampleIndex) * m)) // LoopIndexScaleFactor.
		isInStereo ifTrue: [
			rightVal :=
				(((rightSamples at: sampleIndex) * (LoopIndexScaleFactor - m)) +
				 ((rightSamples at: nextSampleIndex) * m)) // LoopIndexScaleFactor].

		leftVol > 0 ifTrue: [
			s := (aSoundBuffer at: i) + ((compositeLeftVol * leftVal) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].
		i := i + 1.
		rightVol > 0 ifTrue: [
			s := (aSoundBuffer at: i) + ((compositeRightVol * rightVal) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].
		i := i + 1.

		scaledVolIncr ~= 0 ifTrue: [  "update volume envelope if it is changing"
			scaledVol := scaledVol + scaledVolIncr.
			((scaledVolIncr > 0 and: [scaledVol >= scaledVolLimit]) or:
			 [scaledVolIncr < 0 and: [scaledVol <= scaledVolLimit]])
				ifTrue: [  "reached the limit; stop incrementing"
					scaledVol := scaledVolLimit.
					scaledVolIncr := 0].
			compositeLeftVol := (leftVol * scaledVol) // ScaleFactor.
			compositeRightVol :=  (rightVol * scaledVol) // ScaleFactor]].

	count := count - n.

]

{ #category : #private }
LoopedSampledSound >> normalizedResultsFromFFT: fft [
	"Answer an array whose size is half of the FFT window size containing power in each frequency band, normalized to the average power over the entire FFT. A value of 10.0 in this array thus means that the power at the corresponding frequences is ten times the average power across the entire FFT."

	| r avg |
	r := (1 to: fft realData size // 2) collect:
		[:i | ((fft realData at: i) squared + (fft imagData at: i) squared) sqrt].
	avg := r sum / r size.
	^ r collect: [:v | v / avg].

]

{ #category : #'disk i/o' }
LoopedSampledSound >> objectForDataStream: refStrm [
    "Answer an object to store on a data stream, a copy of myself whose SampleBuffers have been converted into ByteArrays."

	refStrm replace: leftSamples with: leftSamples asByteArray.
	refStrm replace: rightSamples with: rightSamples asByteArray.
	"substitution will be made in DataStream nextPut:"
	^ self

]

{ #category : #accessing }
LoopedSampledSound >> originalSamplingRate [

	^ originalSamplingRate

]

{ #category : #accessing }
LoopedSampledSound >> perceivedPitch [

	^ perceivedPitch

]

{ #category : #accessing }
LoopedSampledSound >> pitch [

	^ (scaledIndexIncr asFloat * perceivedPitch * self samplingRate asFloat) /
	  (originalSamplingRate * FloatLoopIndexScaleFactor)

]

{ #category : #accessing }
LoopedSampledSound >> pitch: p [

	scaledIndexIncr :=
		((p asFloat * originalSamplingRate * FloatLoopIndexScaleFactor) /
		 (perceivedPitch * self samplingRate asFloat)) asInteger.

	sampleCountForRelease > 0
		ifTrue: [releaseCount := (sampleCountForRelease * LoopIndexScaleFactor) // scaledIndexIncr]
		ifFalse: [releaseCount := 0].

]

{ #category : #'sound generation' }
LoopedSampledSound >> reset [

	super reset.
	count := initialCount.
	scaledIndex := firstSample * LoopIndexScaleFactor.

]

{ #category : #accessing }
LoopedSampledSound >> rightSamples [

	^ rightSamples

]

{ #category : #accessing }
LoopedSampledSound >> rightSamples: aSampleBuffer [

	rightSamples := aSampleBuffer.

]

{ #category : #accessing }
LoopedSampledSound >> samples [
	"For compatibility with SampledSound. Just return my left channel (which is the only channel if I am mono)."

	^ leftSamples

]

{ #category : #initialization }
LoopedSampledSound >> samples: aSoundBuffer loopEnd: loopEndIndex loopLength: loopSampleCount pitch: perceivedPitchInHz samplingRate: samplingRateInHz [
	"Make this sound use the given samples array with a loop of the given length starting at the given index. The loop length may have a fractional part; this is necessary to achieve pitch accuracy for short loops."

	| loopStartIndex |
	super initialize.
	loopStartIndex := (loopEndIndex - loopSampleCount) truncated + 1.
	((1 <= loopStartIndex) and:
	 [loopStartIndex < loopEndIndex and:
	 [loopEndIndex <= aSoundBuffer size]])
		ifFalse: [self error: 'bad loop parameters'].

	leftSamples := rightSamples := aSoundBuffer.
	originalSamplingRate := samplingRateInHz asFloat.
	perceivedPitch := perceivedPitchInHz asFloat.
	gain := 1.0.
	firstSample := 1.
	lastSample := leftSamples size.
	lastSample >= (SmallInteger maxVal // LoopIndexScaleFactor) ifTrue: [
		self error: 'cannot handle more than ',
			(SmallInteger maxVal // LoopIndexScaleFactor) printString, ' samples'].
	loopEnd := loopEndIndex.
	scaledLoopLength := (loopSampleCount * LoopIndexScaleFactor) asInteger.
	scaledIndexIncr := (samplingRateInHz * LoopIndexScaleFactor) // self samplingRate.
	self computeSampleCountForRelease.

]

{ #category : #'sound generation' }
LoopedSampledSound >> samplesRemaining [
	"Answer the number of samples remaining until the end of this sound."

	^ count

]

{ #category : #initialization }
LoopedSampledSound >> setPitch: pitchNameOrNumber dur: d loudness: vol [
	"(LoopedSampledSound pitch: 440.0 dur: 2.5 loudness: 0.4) play"

	super setPitch: pitchNameOrNumber dur: d loudness: vol.
	self pitch: (self nameOrNumberToPitch: pitchNameOrNumber).
	self reset.

]

{ #category : #'sound generation' }
LoopedSampledSound >> stopAfterMSecs: mSecs [
	"Terminate this sound this note after the given number of milliseconds."

	count := (mSecs * self samplingRate) // 1000.

]

{ #category : #'file i/o' }
LoopedSampledSound >> storeSampleCount: samplesToStore bigEndian: bigEndianFlag on: aBinaryStream [
	"Store my samples on the given stream at the current SoundPlayer sampling rate. If bigFlag is true, then each 16-bit sample is stored most-significant byte first (AIFF files), otherwise it is stored least-significant byte first (WAV files)."

	| reverseBytes |
	(self isStereo or: [self samplingRate ~= originalSamplingRate]) ifTrue: [
		^ super storeSampleCount: samplesToStore bigEndian: bigEndianFlag on: aBinaryStream].

	"optimization: if I'm not stereo and sampling rates match, just store my buffer"
	reverseBytes := bigEndianFlag ~= SmalltalkImage current  isBigEndian.
	reverseBytes ifTrue: [leftSamples reverseEndianness].
	(aBinaryStream isKindOf: StandardFileStream)
		ifTrue: [  "optimization for files: write sound buffer directly to file"
			aBinaryStream next: (leftSamples size // 2) putAll: leftSamples startingAt: 1]  "size in words"
		ifFalse: [  "for non-file streams:"
			1 to: leftSamples monoSampleCount do: [:i | aBinaryStream int16: (leftSamples at: i)]].
	reverseBytes ifTrue: [leftSamples reverseEndianness].  "restore to original endianness"

]

{ #category : #initialization }
LoopedSampledSound >> unloopedSamples: aSoundBuffer pitch: perceivedPitchInHz samplingRate: samplingRateInHz [
	"Make this sound play the given samples unlooped. The samples have the given perceived pitch when played at the given sampling rate. By convention, unpitched sounds such as percussion sounds should specify a pitch of nil or 100 Hz."

	super initialize.
	leftSamples := rightSamples := aSoundBuffer.
	originalSamplingRate := samplingRateInHz asFloat.
	perceivedPitchInHz
		ifNil: [perceivedPitch := 100.0]
		ifNotNil: [perceivedPitch := perceivedPitchInHz asFloat].
	gain := 1.0.
	firstSample := 1.
	lastSample := leftSamples size.
	lastSample >= (SmallInteger maxVal // LoopIndexScaleFactor) ifTrue: [
		self error: 'cannot handle more than ',
			(SmallInteger maxVal // LoopIndexScaleFactor) printString, ' samples'].
	loopEnd := leftSamples size.
	scaledLoopLength := 0.  "zero length means unlooped"
	scaledIndexIncr := (samplingRateInHz * LoopIndexScaleFactor) // self samplingRate.
	self computeSampleCountForRelease.

]
