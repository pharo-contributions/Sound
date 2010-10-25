Class {
	#name : #SoundRecorder,
	#superclass : #Object,
	#instVars : [
		'stereo',
		'samplingRate',
		'recordLevel',
		'recordedBuffers',
		'recordedSound',
		'recordProcess',
		'bufferAvailableSema',
		'paused',
		'meteringBuffer',
		'meterLevel',
		'soundPlaying',
		'currentBuffer',
		'nextIndex',
		'codec',
		'desiredSampleRate'
	],
	#classVars : [
		'CanRecordWhilePlaying',
		'RecorderActive'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #accessing }
SoundRecorder class >> anyActive [
	"Return true if any sound recorder is actively recording"
	^RecorderActive == true
]

{ #category : #accessing }
SoundRecorder class >> canRecordWhilePlaying [
	"Return true if this platform supports simultaneous sound recording and playback."

	^Preferences canRecordWhilePlaying.		"now in preferences"

]

{ #category : #initialization }
SoundRecorder class >> initialize [
	"SoundRecorder initialize"
	"Details: Some computers cannot record and playback sound at the same time. If CanRecordWhilePlaying is false, then the SoundRecorder alternates between recording and playing. If it is true, sounds can be playing during recording."

	CanRecordWhilePlaying := #ignoredNowInPreferences.

]

{ #category : #private }
SoundRecorder >> allocateBuffer [
	"Allocate a new buffer and reset nextIndex."

	| bufferTime |
	bufferTime := stereo  "Buffer time = 1/2 second"
		ifTrue: [self samplingRate asInteger]
		ifFalse: [self samplingRate asInteger // 2].
	currentBuffer := SoundBuffer newMonoSampleCount:
		"Multiple of samplesPerFrame that is approx. bufferTime long"
		(bufferTime truncateTo: self samplesPerFrame).
	nextIndex := 1.

]

{ #category : #'recording controls' }
SoundRecorder >> clearRecordedSound [
	"Clear the sound recorded thus far. Go into pause mode if currently recording."

	paused := true.
	recordedSound := SequentialSound new.
	self allocateBuffer.

]

{ #category : #accessing }
SoundRecorder >> codec: aSoundCodec [

	codec := aSoundCodec
]

{ #category : #results }
SoundRecorder >> condensedSamples [
	"Return a single SoundBuffer that is the contatenation of all my recorded buffers."

	| sz newBuf i |
	recordedBuffers := recordedSound sounds collect: [:snd | snd samples].
	recordedBuffers isEmpty ifTrue: [^ SoundBuffer new: 0].
	recordedBuffers size = 1 ifTrue: [^ recordedBuffers first copy].
	sz := recordedBuffers inject: 0 into: [:tot :buff | tot + buff size].
	newBuf := SoundBuffer newMonoSampleCount: sz.
	i := 1.
	recordedBuffers do: [:b |
		1 to: b size do: [:j |
			newBuf at: i put: (b at: j).
			i := i + 1]].
	recordedBuffers := nil.
	^ newBuf

]

{ #category : #results }
SoundRecorder >> condensedStereoSound [
	"Decompose my buffers into left and right channels and return a mixed sound consisting of the those two channels. This may be take a while, since the data must be copied into new buffers."

	| sz leftBuf rightBuf leftI rightI left |
	sz := recordedBuffers inject: 0 into: [:tot :buff | tot + buff size].
	leftBuf := SoundBuffer newMonoSampleCount: (sz + 1) // 2.
	rightBuf := SoundBuffer newMonoSampleCount: (sz + 1) // 2.
	leftI := rightI := 1.
	left := true.
	recordedBuffers do: [:b |
		1 to: b size do: [:j |
			left
				ifTrue: [leftBuf at: leftI put: (b at: j). leftI := leftI + 1. left := false]
				ifFalse: [rightBuf at: rightI put: (b at: j). rightI := rightI + 1. left := true]]].
	^ MixedSound new
		add: (SampledSound new setSamples: leftBuf samplingRate: samplingRate) pan: 0.0;
		add: (SampledSound new setSamples: rightBuf samplingRate: samplingRate) pan: 1.0

]

{ #category : #trimming }
SoundRecorder >> copyFrom: startPlace to: endPlace normalize: nFactor dcOffset: dcOffset [
	"Return a new SoundBuffer containing the samples in the given range."

	| startBufIndex startSampleIndex endBufIndex endSampleIndex
	 count resultBuf j buf firstInBuf n |
	startBufIndex := startPlace at: 1.
	startSampleIndex := startPlace at: 2.
	endBufIndex := endPlace at: 1.
	endSampleIndex := endPlace at: 2.

	startBufIndex = endBufIndex
		ifTrue: [count := endSampleIndex + 1 - startSampleIndex]
		ifFalse: [
			count := ((recordedBuffers at: startBufIndex) size + 1 - startSampleIndex).  "first buffer"
			count := count + endSampleIndex.  "last buffer"
			startBufIndex + 1 to: endBufIndex - 1 do:
				[:i | count := count + (recordedBuffers at: i) size]].  "middle buffers"
	resultBuf := SoundBuffer newMonoSampleCount: count.

	j := 1.  "next destination index in resultBuf"
	startBufIndex to: endBufIndex do: [:i |
		buf := recordedBuffers at: i.
		firstInBuf := 1.
	 	n := buf size.
		i = startBufIndex ifTrue: [
			n := (recordedBuffers at: startBufIndex) size + 1 - startSampleIndex.
			firstInBuf := startSampleIndex].
		i = endBufIndex ifTrue: [
			i = startBufIndex
				ifTrue: [n := endSampleIndex + 1 - startSampleIndex]
				ifFalse: [n := endSampleIndex]].
		self copyTo: resultBuf from: j to: (j + n - 1)
			from: buf startingAt: firstInBuf
			normalize: nFactor dcOffset: dcOffset.
		j := j + n].
	^ resultBuf

]

{ #category : #trimming }
SoundRecorder >> copyTo: resultBuf from: startIndex to: endIndex from: buf startingAt: firstInBuf normalize: nFactor dcOffset: dcOffset [
	"Copy samples from buf to resultBuf removing the DC offset and normalizing their volume in the process."

	| indexOffset |
	indexOffset := firstInBuf - startIndex.
	startIndex to: endIndex do: [:i |
		resultBuf at: i put: (((buf at: (i + indexOffset)) - dcOffset) * nFactor) // 1000].

]

{ #category : #accessing }
SoundRecorder >> desiredSampleRate: newRate [

	"use of this method indicates a strong desire for the specified rate, even if
	the OS/hardware are not cooperative"

	desiredSampleRate := samplingRate := newRate  "Best are 44100 22050 11025"

]

{ #category : #private }
SoundRecorder >> emitBuffer: buffer [

	| sound ratio resultBuf |

	"since some sound recording devices cannot (or will not) record below a certain sample rate,
	trim the samples down if the user really wanted fewer samples"

	(desiredSampleRate isNil or: [(ratio := samplingRate // desiredSampleRate) <= 1]) ifTrue: [
		sound := SampledSound new setSamples: buffer samplingRate: samplingRate.
	] ifFalse: [
		resultBuf := SoundBuffer 
			averageEvery: ratio 
			from: buffer 
			upTo: buffer monoSampleCount.
		sound := SampledSound new setSamples: resultBuf samplingRate: samplingRate / ratio.
	].

	recordedSound add: (codec ifNil: [sound] ifNotNil: [codec compressSound: sound])
]

{ #category : #private }
SoundRecorder >> emitPartialBuffer [
	| s |
	s := self samplesPerFrame.
	self emitBuffer: (currentBuffer copyFrom: 1 to: ((nextIndex-1) +( s-1) truncateTo: s))
]

{ #category : #trimming }
SoundRecorder >> endPlace [

	^ Array with: recordedBuffers size with: recordedBuffers last size
]

{ #category : #trimming }
SoundRecorder >> firstSampleOverThreshold: threshold dcOffset: dcOffset startingAt: startPlace [
	"Beginning at startPlace, this routine will return the first place at which a sample exceeds the given threshold."

	| buf s iStart jStart nThreshold |
	nThreshold := threshold negated.
	iStart := startPlace first.
	jStart := startPlace second.
	iStart to: recordedBuffers size do:
		[:i | buf := recordedBuffers at: i.
		jStart to: buf size do:
			[:j | s := (buf at: j) - dcOffset.
			(s < nThreshold or: [s > threshold]) ifTrue:
				["found a sample over threshold"
				^ Array with: i with: j]].
		jStart := 1].
	^ self endPlace
]

{ #category : #'recording controls' }
SoundRecorder >> hasRecordedSound [
 	"Answer whether the receiver currently has any recorded sound"
 
 	^ self recordedSound notNil
]

{ #category : #initialization }
SoundRecorder >> initialize [
	"SoundRecorder new"

	super initialize.
	stereo := false.
	samplingRate := 11025.
	recordLevel := 0.5.
	self initializeRecordingState.

]

{ #category : #initialization }
SoundRecorder >> initializeRecordingState [

	recordProcess := nil.
	bufferAvailableSema := nil.
	paused := true.
	meteringBuffer := nil.
	meterLevel := 0.
	soundPlaying := nil.
	currentBuffer := nil.
	nextIndex := 1.

]

{ #category : #accessing }
SoundRecorder >> isActive [
	"Return true if I have a recordProcess running."

	^ recordProcess ~~ nil

]

{ #category : #accessing }
SoundRecorder >> isPaused [
	"Return true if recording is paused."

	^ paused

]

{ #category : #private }
SoundRecorder >> meterFrom: start count: count in: buffer [
	"Update the meter level with the maximum signal level in the given range of the given buffer."

	| last max sample |
	count = 0 ifTrue: [^ self].  "no new samples"
	last := start + count - 1.
	max := 0.
	start to: last do: [:i |
		sample := buffer at: i.
		sample < 0 ifTrue: [sample := sample negated].
		sample > max ifTrue: [max := sample]].
	meterLevel := max.

]

{ #category : #accessing }
SoundRecorder >> meterLevel [
	"Return the meter level, an integer in the range [0..100] where zero is silence and 100 represents the maximum signal level possible without clipping."

	^ (100 * meterLevel) // 32768

]

{ #category : #trimming }
SoundRecorder >> normalizeFactorFor: percentOfMaxVolume min: min max: max dcOffset: dcOffset [
	"Return a normalization factor for the range of sample values and DC offset. A normalization factor is a fixed-point number that will be divided by 1000 after multiplication with each sample value."

	| peak factor |
	peak := (max - dcOffset) max: (min - dcOffset) negated.
	peak = 0 ifTrue: [^ 1000].
	factor := (32767.0 * percentOfMaxVolume) / (100.0 * peak).
	^ (factor * 1000.0) asInteger

]

{ #category : #'recording controls' }
SoundRecorder >> pause [
	"Go into pause mode. The record level continues to be updated, but no sound is recorded."

	paused := true.
	((currentBuffer ~~ nil) and: [nextIndex > 1])
		ifTrue: [self emitPartialBuffer.
				self allocateBuffer].

	soundPlaying ifNotNil: [
		soundPlaying pause.
		soundPlaying := nil].
	"Note: there can be problems if canRecordWhilePlaying is true. Recorders which only pause will inhibit other recorders from recording. I chose to make #stopPlaying unconditional in a subclass. The same might be appropriate here at the expense of making recorders resumable"

	Preferences canRecordWhilePlaying ifFalse: [self stopRecording].

]

{ #category : #trimming }
SoundRecorder >> place: startPlace plus: nSamples [
	"Return the place that is nSamples (may be negative) beyond thisPlace."

	| i j remaining buf |
	i := startPlace first.
	j := startPlace second.
	nSamples >= 0
	ifTrue: [remaining := nSamples.
			[buf := recordedBuffers at: i.
			(j + remaining) <= buf size ifTrue: [^ Array with: i with: j + remaining].
			i < recordedBuffers size]
				whileTrue: [remaining := remaining - (buf size - j + 1).
							i := i+1.  j := 1].
			^ self endPlace]
	ifFalse: [remaining := nSamples negated.
			[buf := recordedBuffers at: i.
			(j - remaining) >= 1 ifTrue: [^ Array with: i with: j - remaining].
			i > 1]
				whileTrue: [remaining := remaining - j.
							i := i-1.  j := (recordedBuffers at: i) size].
			^ #(1 1)]
]

{ #category : #'recording controls' }
SoundRecorder >> playback [
	"Playback the sound that has been recorded."

	self pause.
	soundPlaying := self recordedSound.
	soundPlaying play.

]

{ #category : #primitives }
SoundRecorder >> primGetActualRecordingSampleRate [
	"Return the actual sample rate being used for recording. This primitive fails unless sound recording is currently in progress."

	<primitive: 'primitiveSoundGetRecordingSampleRate' module: 'SoundPlugin'>
	self primitiveFailed

]

{ #category : #primitives }
SoundRecorder >> primRecordSamplesInto: aWordArray startingAt: index [
	"Record a sequence of 16-bit sound samples into the given array starting at the given sample index. Return the number of samples recorded, which may be zero if no samples are currently available."

	<primitive: 'primitiveSoundRecordSamples' module: 'SoundPlugin'>
	self primitiveFailed

]

{ #category : #primitives }
SoundRecorder >> primSetRecordLevel: anInteger [
	"Set the desired recording level to the given value in the range 0-1000, where 0 is the lowest recording level and 1000 is the maximum. Do nothing if the sound input hardware does not support changing the recording level."

	<primitive: 'primitiveSoundSetRecordLevel' module: 'SoundPlugin'>
	self primitiveFailed

]

{ #category : #primitives }
SoundRecorder >> primStartRecordingDesiredSampleRate: samplesPerSec stereo: stereoFlag semaIndex: anInteger [
	"Start sound recording with the given stereo setting. Use a sampling rate as close to the desired rate as the underlying platform will support. If the given semaphore index is > 0, it is taken to be the index of a Semaphore in the external objects array to be signalled every time a recording buffer is filled."

	<primitive: 'primitiveSoundStartRecording' module: 'SoundPlugin'>
	self primitiveFailed

]

{ #category : #primitives }
SoundRecorder >> primStopRecording [
	"Stop sound recording. Does nothing if recording is not currently in progress. Do not fail if plugin is not available"

	<primitive: 'primitiveSoundStopRecording' module: 'SoundPlugin'>
]

{ #category : #accessing }
SoundRecorder >> recordLevel [

	^ recordLevel

]

{ #category : #accessing }
SoundRecorder >> recordLevel: level [
	"Set the desired recording level to the given value in the range 0.0 to 1.0, where 0.0 is the lowest recording level and 1.0 is the maximum. Do nothing if the sound input hardware does not support changing the recording level."
	"Details: On the Macintosh, the lowest possible record level attenuates the input signal, but does not silence it entirely." 

	recordLevel := (level asFloat min: 1.0) max: 0.0.
	recordProcess ifNotNil: [
		self primSetRecordLevel: (1000.0 * recordLevel) asInteger].

]

{ #category : #private }
SoundRecorder >> recordLoop [
	"Record process loop that records samples."

	| n sampleCount |

	n := 0.
	[true] whileTrue: [
		n = 0 ifTrue: [bufferAvailableSema wait].
		paused
			ifTrue: [
				n := self primRecordSamplesInto: meteringBuffer startingAt: 1.
				self meterFrom: 1 count: n in: meteringBuffer]
			ifFalse: [
				n := self primRecordSamplesInto: currentBuffer startingAt: nextIndex.
				self meterFrom: nextIndex count: n in: currentBuffer.
				nextIndex := nextIndex + n.
				stereo
					ifTrue: [sampleCount := currentBuffer stereoSampleCount]
					ifFalse: [sampleCount := currentBuffer monoSampleCount].
				nextIndex > sampleCount
					ifTrue: [
						self emitBuffer: currentBuffer.
						self allocateBuffer]].

		"workaround for OSS emulation on top on ALSA (on Linux environments)"
		(Delay forMilliseconds: 20) wait.
	].

]

{ #category : #results }
SoundRecorder >> recordedSound [
	"Return the sound that was recorded."

	^ recordedSound

]

{ #category : #'recording controls' }
SoundRecorder >> resumeRecording [
	"Continue recording from the point at which it was last paused."

	self flag: #bob.
	"Note: If canRecordWhilePlaying is true, then recordings may never get started (at least by this method). One possibility, used in a subclass, is to make the #startPlaying unconditional. Another would be to use #startPlaying instead of #resumePlaying in appropriate cases"

	Preferences canRecordWhilePlaying ifFalse: [self startRecording].
	paused := false.

]

{ #category : #private }
SoundRecorder >> samplesPerFrame [
	"Can be overridden to quantize buffer size for, eg, fixed-frame codecs"

	codec == nil
		ifTrue: [^ 1]
		ifFalse: [^ codec samplesPerFrame]
]

{ #category : #accessing }
SoundRecorder >> samplingRate [

	^ samplingRate

]

{ #category : #accessing }
SoundRecorder >> samplingRate: newRate [

	samplingRate := newRate  "Best are 44100 22050 11025"

]

{ #category : #trimming }
SoundRecorder >> scanForEndThreshold: threshold dcOffset: dcOffset minLull: lull startingAt: startPlace [
	"Beginning at startPlace, this routine will find the last sound that exceeds threshold, such that if you look lull samples later you will not find another sound over threshold within the following block of lull samples.
	Return the place that is lull samples beyond to that last sound.
	If no end of sound is found, return endPlace."

	| buf s iStart jStart nThreshold n |
	nThreshold := threshold negated.
	iStart := startPlace first.
	jStart := startPlace second.
	n := 0.
	iStart to: recordedBuffers size do:
		[:i | buf := recordedBuffers at: i.
		jStart to: buf size do:
			[:j | s := (buf at: j) - dcOffset.
			(s < nThreshold or: [s > threshold])
				ifTrue: ["found a sample over threshold"
						n := 0]
				ifFalse: ["still not over threshold"
						n := n + 1.
						n >= lull ifTrue: [^ Array with: i with: j]]].
		jStart := 1].
	^ self endPlace
]

{ #category : #trimming }
SoundRecorder >> scanForStartThreshold: threshold dcOffset: dcOffset minDur: duration startingAt: startPlace [
	"Beginning at startPlace, this routine will find the first sound that exceeds threshold, such that if you look duration samples later you will find another sound over threshold within the following block of duration samples.
	Return the place that is duration samples prior to that first sound.
	If no sound is found, return endPlace."

	| soundPlace lookPlace nextSoundPlace thirdPlace |
	soundPlace := self firstSampleOverThreshold: threshold dcOffset: dcOffset
					startingAt: startPlace.
	[soundPlace = self endPlace ifTrue: [^ soundPlace].
	"Found a sound -- look duration later"
	lookPlace := self place: soundPlace plus: duration.
	nextSoundPlace := self firstSampleOverThreshold: threshold dcOffset: dcOffset
					startingAt: lookPlace.
	thirdPlace := self place: lookPlace plus: duration.
	nextSoundPlace first < thirdPlace first
		or: [nextSoundPlace first = thirdPlace first
			and: [nextSoundPlace second < thirdPlace second]]]
		whileFalse: [soundPlace := nextSoundPlace].

	"Yes, there is sound in the next interval as well"
	^ self place: soundPlace plus: 0-duration

]

{ #category : #trimming }
SoundRecorder >> segmentsAbove: threshold normalizedVolume: percentOfMaxVolume [
	"Break the current recording up into a sequence of sound segments separated by silences."

	| dcOffset firstPlace endPlace resultBuf nFactor lastPlace segments gapSize minDur minLull soundSize restSize max min sum totalSamples |
	stereo ifTrue: [self error: 'stereo trimming is not yet supported'].
	paused ifFalse: [self error: 'must stop recording before trimming'].
	(recordedSound == nil or: [recordedSound sounds isEmpty]) ifTrue:[^ self].
	"Reconstruct buffers so old trimming code will work"
	recordedBuffers := recordedSound sounds collect: [:snd | snd samples].
	soundSize := restSize := 0.

	max := min := sum := totalSamples := 0.
	recordedBuffers do: [:buf | | bufSize s |
		bufSize := buf size.
		totalSamples := totalSamples + buf size.
		1 to: bufSize do: [:i |
			s := buf at: i.
			s > max ifTrue: [max := s].
			s < min ifTrue: [min := s].
			sum := sum + s]].
	dcOffset := sum // totalSamples.

	minDur := (samplingRate/20.0) asInteger.  " 1/20 second "
	minLull := (samplingRate/4.0) asInteger.  " 1/2 second "
	segments := SequentialSound new.
	endPlace := self endPlace.
	lastPlace := #(1 1).
	[firstPlace := self scanForStartThreshold: threshold
						dcOffset: dcOffset
						minDur: minDur
						startingAt: lastPlace.
	firstPlace = endPlace]
		whileFalse:
		[firstPlace = lastPlace ifFalse:
			["Add a silence equal to the gap size"
			"Wasteful but simple way to get gap size..."
			gapSize := (self copyFrom: lastPlace to: firstPlace
						normalize: 1000 dcOffset: dcOffset) size - 2.
			"... -2 makes up for overlap of one sample on either end"
			segments add: (RestSound dur: gapSize asFloat / samplingRate).
			restSize := restSize + gapSize.
"Transcript cr; print: firstPlace; space; print: lastPlace; space; print: gapSize; space; show: 'gap'."
			].
		lastPlace := self scanForEndThreshold: threshold
						dcOffset: dcOffset
						minLull: minLull + minDur
						startingAt: firstPlace.
		"Allow room for lead time of next sound"
		lastPlace := self place: lastPlace plus: minDur negated.
		nFactor := self normalizeFactorFor: percentOfMaxVolume
						min: min max: max dcOffset: dcOffset.
		resultBuf := self copyFrom: firstPlace to: lastPlace
						normalize: nFactor dcOffset: dcOffset.
		soundSize := soundSize + resultBuf size.
"Transcript cr; print: firstPlace; space; print: lastPlace; space; print: resultBuf size; space; show: 'sound'."
		segments add: (codec == nil
			ifTrue: [SampledSound new setSamples: resultBuf samplingRate: samplingRate]
			ifFalse: [codec compressSound: (SampledSound new setSamples: resultBuf samplingRate: samplingRate)])].

	"Final gap for consistency"
	gapSize := (self copyFrom: lastPlace to: self endPlace
				normalize: 1000 dcOffset: dcOffset) size - 1.
	segments add: (RestSound dur: gapSize asFloat / samplingRate).
	restSize := restSize + gapSize.
	self inform: ((soundSize+restSize/samplingRate) roundTo: 0.1) printString , ' secs reduced to ' , ((soundSize/samplingRate) roundTo: 0.1) printString.
	recordedBuffers := nil.
	^ segments
]

{ #category : #results }
SoundRecorder >> soundSegments [

	^ self segmentsAbove: 1000 normalizedVolume: 80.0

]

{ #category : #'recording controls' }
SoundRecorder >> startRecording [
	"Turn of the sound input driver and start the recording process. Initially, recording is paused."

	| semaIndex |
	recordLevel ifNil: [recordLevel := 0.5].  "lazy initialization"
	Preferences canRecordWhilePlaying ifFalse: [SoundPlayer shutDown].
	recordProcess ifNotNil: [self stopRecording].
	paused := true.
	meteringBuffer := SoundBuffer newMonoSampleCount: 1024.
	meterLevel := 0.
	self allocateBuffer.
	bufferAvailableSema := Semaphore new.
	semaIndex := Smalltalk registerExternalObject: bufferAvailableSema.
	self primStartRecordingDesiredSampleRate: samplingRate asInteger
		stereo: stereo
		semaIndex: semaIndex.
	RecorderActive := true.
	samplingRate := self primGetActualRecordingSampleRate.
	self primSetRecordLevel: (1000.0 * recordLevel) asInteger.
	recordProcess := [self recordLoop] newProcess.
	recordProcess priority: Processor userInterruptPriority.
	recordProcess resume.

]

{ #category : #'recording controls' }
SoundRecorder >> stopRecording [
	"Stop the recording process and turn of the sound input driver."

	recordProcess ifNotNil: [recordProcess terminate].
	recordProcess := nil.
	self primStopRecording.
	RecorderActive := false.
	Smalltalk unregisterExternalObject: bufferAvailableSema.
	((currentBuffer ~~ nil) and: [nextIndex > 1])
		ifTrue: [self emitPartialBuffer].
	self initializeRecordingState.

]

{ #category : #trimming }
SoundRecorder >> suppressSilence [

	recordedSound := self soundSegments
]

{ #category : #trimming }
SoundRecorder >> trim: threshold normalizedVolume: percentOfMaxVolume [
	"Remove the leading and trailing parts of this recording that are below the given threshold. Remove any DC offset and scale the recording so that its peaks are the given percent of the maximum volume."

	| dcOffset startPlace endPlace resultBuf nFactor max min sum totalSamples |
	stereo ifTrue: [self error: 'stereo trimming is not yet supported'].
	paused ifFalse: [self error: 'must stop recording before trimming'].
	recordedBuffers := recordedSound sounds collect: [:snd | snd samples].
	recordedBuffers isEmpty ifTrue: [^ self].

	max := min := sum := totalSamples := 0.
	recordedBuffers do: [:buf | | bufSize s |
		bufSize := buf size.
		totalSamples := totalSamples + buf size.
		1 to: bufSize do: [:i |
			s := buf at: i.
			s > max ifTrue: [max := s].
			s < min ifTrue: [min := s].
			sum := sum + s]].
	dcOffset := sum // totalSamples.

	"a place is an array of <buffer index><index of sample in buffer>"
	startPlace := self scanForStartThreshold: threshold
					dcOffset: dcOffset
					minDur: (samplingRate/60.0) asInteger "at least 1/60th of a second"
					startingAt: #(1 1).
	startPlace = self endPlace ifTrue:
		["no samples above threshold"
		recordedBuffers := nil.  ^ self].

	endPlace := self scanForEndThreshold: threshold
					dcOffset: dcOffset
					minLull: (samplingRate/5) asInteger
					startingAt: startPlace.
	nFactor := self normalizeFactorFor: percentOfMaxVolume min: min max: max dcOffset: dcOffset.
	resultBuf := self copyFrom: startPlace to: endPlace normalize: nFactor dcOffset: dcOffset.
	recordedSound := SampledSound new setSamples: resultBuf samplingRate: samplingRate.
	recordedBuffers := nil

]

{ #category : #'recording controls' }
SoundRecorder >> verifyExistenceOfRecordedSound [
 	"If the receiver has a recorded sound, answer true; if not, put up an informer and answer false"
 
 	^ self recordedSound
 		ifNotNil:
 			[true]
 		ifNil:
 			[self inform: 'please record a sound first' translated.
 			false]
]
