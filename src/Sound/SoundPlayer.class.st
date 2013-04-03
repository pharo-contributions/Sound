"
I contain setting builders for the Sound package

"
Class {
	#name : #SoundPlayer,
	#superclass : #Object,
	#classVars : [
		'ActiveSounds',
		'Buffer',
		'BufferIndex',
		'BufferMSecs',
		'LastBuffer',
		'PausedSounds',
		'PlayerProcess',
		'PlayerSemaphore',
		'ReadyForBuffer',
		'ReverbState',
		'SamplingRate',
		'SoundJustStarted',
		'SoundSupported',
		'SoundsShouldStartQuick',
		'SoundsStopWhenDone',
		'Stereo',
		'UseReadySemaphore',
		'UseReverb'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #'primitive test' }
SoundPlayer class >> boinkPitch: p dur: d loudness: l waveTable: waveTable pan: pan [
	"Play a decaying note on the given stream using the given wave table. Used for testing only."

	| decay tableSize amplitude increment cycles i |
	decay := 0.96.
	tableSize := waveTable size.
	amplitude := l asInteger min: 1000.
	increment := ((p asFloat * tableSize asFloat) / SamplingRate asFloat) asInteger.
	increment := (increment max: 1) min: (tableSize // 2).
	cycles := (d * SamplingRate asFloat) asInteger.

	i := 1.
	1 to: cycles do: [:cycle |
		(cycle \\ 100) = 0
			ifTrue: [amplitude := (decay * amplitude asFloat) asInteger].
		i := (((i - 1) + increment) \\ tableSize) + 1.
		self playTestSample: (amplitude * (waveTable at: i)) // 1000 pan: pan].

]

{ #category : #'primitive test' }
SoundPlayer class >> boinkScale [
	"Tests the sound output primitives by playing a scale."
	"SoundPlayer boinkScale"

	| sineTable pan |
	self shutDown.
	SamplingRate := 11025.
	Stereo := true.
	sineTable := self sineTable: 1000.
	Buffer := SoundBuffer newStereoSampleCount: 1000.
	BufferIndex := 1.
	self primSoundStartBufferSize: Buffer stereoSampleCount
		rate: SamplingRate
		stereo: Stereo.
	pan := 0.
	#(261.626 293.665 329.628 349.229 391.996 440.001 493.884 523.252) do: [:p |
		self boinkPitch: p dur: 0.3 loudness: 300 waveTable: sineTable pan: pan.
		pan := pan + 125].

	self boinkPitch: 261.626 dur: 1.0 loudness: 300 waveTable: sineTable pan: 500.
	self primSoundStop.
	self shutDown.
	SoundPlayer initialize.  "reset sampling rate, buffer size, and stereo flag"

]

{ #category : #accessing }
SoundPlayer class >> bufferMSecs [

	^ BufferMSecs

]

{ #category : #playing }
SoundPlayer class >> canStartPlayer [
	"Some platforms do no support simultaneous record and play. If this is one of those platforms, return false if there is a running SoundRecorder."

	^SoundRecorder canRecordWhilePlaying 
		or: [SoundRecorder anyActive not]
]

{ #category : #settings }
SoundPlayer class >> defaultQuickStartForPlatform [

	^ Smalltalk os platformName = 'Mac OS'.
]

{ #category : #settings }
SoundPlayer class >> defaultStopSoundForPlatform [

	^(Smalltalk os platformName = 'Mac OS') not
]

{ #category : #initialization }
SoundPlayer class >> initialize [
	"SoundPlayer initialize; shutDown; startUp"
	"Details: BufferMSecs represents a tradeoff between latency and quality. If BufferMSecs is too low, the sound will not play smoothly, especially during long-running primitives such as large BitBlts. If BufferMSecs is too high, there will be a long time lag between when a sound buffer is submitted to be played and when that sound is actually heard. BufferMSecs is typically in the range 50-200."
	self initializeForPlatform.
	SamplingRate := 22050.
	BufferMSecs := 120.
	Stereo := true.
	UseReverb ifNil: [UseReverb := true].

]

{ #category : #initialization }
SoundPlayer class >> initializeForPlatform [
	"Apparently, the VM could crash if these were not correct. 
		Change in future if platform support for the features change"
	self soundQuickStart: self defaultQuickStartForPlatform.
	self stopSoundWhenDone: self defaultStopSoundForPlatform.
]

{ #category : #private }
SoundPlayer class >> isAllSilence: buffer size: count [
	"return true if the buffer is all silence after reverb has ended"
	| value |
	value := buffer at: 1.
	2 to: count do:[:i| (buffer at: i) = value ifFalse:[^false]].
	^true
]

{ #category : #playing }
SoundPlayer class >> isPlaying: aSound [
	^ ActiveSounds includes: aSound
]

{ #category : #'player process' }
SoundPlayer class >> isReverbOn [

	^ ReverbState ~~ nil

]

{ #category : #'player process' }
SoundPlayer class >> lastPlayBuffer [
	^LastBuffer
]

{ #category : #'player process' }
SoundPlayer class >> oldStylePlayLoop [
	"This version of the play loop is used if the VM does not yet support sound primitives that signal a semaphore when a sound buffer becomes available."

	| bytesPerSlice count |
	bytesPerSlice := Stereo ifTrue: [4] ifFalse: [2].
	[true] whileTrue: [
		[(count := self primSoundAvailableBytes // bytesPerSlice) > 100]
			whileFalse: [(Delay forMilliseconds: 1) wait].

		count := count min: Buffer stereoSampleCount.
		PlayerSemaphore critical: [
			ActiveSounds := ActiveSounds select: [:snd | snd samplesRemaining > 0].
			ActiveSounds do: [:snd |
				snd ~~ SoundJustStarted ifTrue: [
					snd playSampleCount: count into: Buffer startingAt: 1]].
			ReverbState == nil ifFalse: [
				ReverbState applyReverbTo: Buffer startingAt: 1 count: count].
			self primSoundPlaySamples: count from: Buffer startingAt: 1.
			Buffer primFill: 0.
			SoundJustStarted := nil]].

]

{ #category : #playing }
SoundPlayer class >> pauseSound: aSound [
	"Stop playing the given sound. Playing can be resumed from this point later."

	PlayerSemaphore critical: [
		ActiveSounds remove: aSound ifAbsent: []].

]

{ #category : #'player process' }
SoundPlayer class >> playLoop [
	"The sound player process loop."

	| bytesPerSlice count willStop mayStop |
	mayStop := self stopSoundWhenDone.
	bytesPerSlice := Stereo ifTrue: [4] ifFalse: [2].
	[true] whileTrue: [
		[(count := self primSoundAvailableBytes // bytesPerSlice) > 100]
			whileFalse: [ReadyForBuffer wait].

		count := count min: Buffer stereoSampleCount.
		PlayerSemaphore critical: [
			ActiveSounds := ActiveSounds select: [:snd | snd samplesRemaining > 0].
			ActiveSounds do: [:snd |
				snd ~~ SoundJustStarted ifTrue: [
					snd playSampleCount: count into: Buffer startingAt: 1]].
			ReverbState == nil ifFalse: [
				ReverbState applyReverbTo: Buffer startingAt: 1 count: count].
			self primSoundPlaySamples: count from: Buffer startingAt: 1.
			willStop := mayStop and:[
						(ActiveSounds size = 0) and:[
							self isAllSilence: Buffer size: count]].
			LastBuffer ifNotNil:[
				LastBuffer replaceFrom: 1 to: LastBuffer size with: Buffer startingAt: 1.
			].
			willStop
				ifTrue:[self shutDown. PlayerProcess := nil]
				ifFalse:[Buffer primFill: 0].
			SoundJustStarted := nil].
		willStop ifTrue:[^self].
	].

]

{ #category : #playing }
SoundPlayer class >> playSound: aSound [
	"Reset and start playing the given sound from its beginning."

	aSound reset.
	aSound samplesRemaining = 0 ifTrue:[^self].
	self resumePlaying: aSound.

]

{ #category : #'primitive test' }
SoundPlayer class >> playTestSample: s pan: pan [
	"Append the given sample in the range [-32767..32767] to the output buffer, playing the output buffer when it is full. Used for testing only."

	| sample leftSample |
	BufferIndex >= Buffer size
		ifTrue: [
			"current buffer is full; play it"
			[self primSoundAvailableBytes > 0]
				whileFalse. "wait for space to be available"
			self primSoundPlaySamples: Buffer stereoSampleCount from: Buffer startingAt: 1.
			Buffer primFill: 0.
			BufferIndex := 1].

	sample := s.
	sample >  32767 ifTrue: [ sample :=  32767 ]. 
	sample < -32767 ifTrue: [ sample := -32767 ].

	Stereo
		ifTrue: [
			leftSample := (sample * pan) // 1000.
			Buffer at: BufferIndex		put: sample - leftSample.
			Buffer at: BufferIndex + 1	put: leftSample]
		ifFalse: [
			Buffer at: BufferIndex + 1 put: sample].
	BufferIndex := BufferIndex + 2.

]

{ #category : #'player process' }
SoundPlayer class >> playerProcess [
	^PlayerProcess
]

{ #category : #private }
SoundPlayer class >> primSoundAvailableBytes [
	"Return the number of bytes of available space in the sound output buffer."
	"Note: Squeak always uses buffers containing 4-bytes per sample (2 channels at 2 bytes per channel) regardless of the state of the Stereo flag."

	<primitive: 'primitiveSoundAvailableSpace' module: 'SoundPlugin'>
	^ self primitiveFailed

]

{ #category : #private }
SoundPlayer class >> primSoundGetVolume [
	"Return sound as array of doubles left then right channel, range is 0.0 to 1.0 but may be overdriven"
	<primitive: 'primitiveSoundGetVolume' module: 'SoundPlugin'>
	^Array with: 1.0 with: 1.0
]

{ #category : #private }
SoundPlayer class >> primSoundInsertSamples: count from: aSoundBuffer samplesOfLeadTime: anInteger [
	"Mix the given number of sample frames from the given sound buffer into the queue of samples that has already been submitted to the sound driver. This primitive is used to start a sound playing with minimum latency, even if large sound output buffers are being used to ensure smooth sound output. Returns the number of samples consumed, or zero if the primitive is not implemented or fails."

	<primitive: 'primitiveSoundInsertSamples' module: 'SoundPlugin'>
	^ 0

]

{ #category : #private }
SoundPlayer class >> primSoundPlaySamples: count from: aSampleBuffer startingAt: index [
	"Copy count bytes into the current sound output buffer from the given sample buffer starting at the given index."

	<primitive: 'primitiveSoundPlaySamples' module: 'SoundPlugin'>
	^ self primitiveFailed

]

{ #category : #private }
SoundPlayer class >> primSoundSetVolumeLeft: aLeftVolume volumeRight: aRightVolume [
	"Set sound pass in float 0.0-1.0 for left and right channel, with possible 2.0 or  higher to overdrive sound channel "
	<primitive: 'primitiveSoundSetLeftVolume' module: 'SoundPlugin'>

]

{ #category : #private }
SoundPlayer class >> primSoundStartBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag [
	"Start double-buffered sound output with the given buffer size and sampling rate. This version has been superceded by primitive 171 (primSoundStartBufferSize:rate:stereo:semaIndex:)."
	"ar 12/5/1998 Turn off the sound if not supported"
	<primitive: 'primitiveSoundStart' module: 'SoundPlugin'>
	SoundSupported := false.
]

{ #category : #private }
SoundPlayer class >> primSoundStartBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag semaIndex: anInteger [
	"Start double-buffered sound output with the given buffer size and sampling rate. If the given semaphore index is > 0, it is taken to be the index of a Semaphore in the external objects array to be signalled when the sound driver is ready to accept another buffer of samples."
	"Details: If this primitive fails, this method tries to use the older version instead."

	<primitive: 'primitiveSoundStartWithSemaphore' module: 'SoundPlugin'>
	UseReadySemaphore := false.
	self primSoundStartBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag.

]

{ #category : #private }
SoundPlayer class >> primSoundStop [
	"Stop double-buffered sound output. Must not raise an error because it is used inside error handling and at system shutdown"

	<primitive: 'primitiveSoundStop' module: 'SoundPlugin'>
]

{ #category : #playing }
SoundPlayer class >> resumePlaying: aSound [
	"Start playing the given sound without resetting it; it will resume playing from where it last stopped."
	"Implementation detail: On virtual machines that don't support the quickstart primitive, you may need to edit this method to pass false to resumePlaying:quickStart:."

	self resumePlaying: aSound quickStart: true.

]

{ #category : #playing }
SoundPlayer class >> resumePlaying: aSound quickStart: quickStart [
	"Start playing the given sound without resetting it; it will resume playing from where it last stopped. If quickStart is true, then try to start playing the given sound immediately."

	| doQuickStart |
	BaseSoundSystem soundEnabled ifFalse: [^ self].
	doQuickStart := quickStart.
	BaseSoundSystem soundQuickStart ifFalse: [doQuickStart := false].
	PlayerProcess == nil ifTrue: [
		self canStartPlayer ifFalse: [^ self].
		^self startUpWithSound: aSound].

	PlayerSemaphore critical: [
		(ActiveSounds includes: aSound)
			ifTrue: [doQuickStart := false]
			ifFalse: [
				doQuickStart ifFalse: [ActiveSounds add: aSound]]].

	"quick-start the given sound, unless the sound player has just started"
	doQuickStart ifTrue: [self startPlayingImmediately: aSound].

]

{ #category : #accessing }
SoundPlayer class >> reverbState [

	^ ReverbState
]

{ #category : #accessing }
SoundPlayer class >> samplingRate [

	^ SamplingRate ifNil: [ 22050 ]
]

{ #category : #accessing }
SoundPlayer class >> setVolumeLeft: aLeftVolume volumeRight: aRightVolume [
	"Set sound pass in float 0.0-1.0 for left and right channel, with possible 2.0 or  higher to overdrive sound channel "
	self primSoundSetVolumeLeft: aLeftVolume volumeRight: aRightVolume
]

{ #category : #snapshotting }
SoundPlayer class >> shutDown [
	"Stop player process, for example before snapshotting."

	self stopPlayerProcess.
	ReverbState := nil.

]

{ #category : #'primitive test' }
SoundPlayer class >> sineTable: size [
	"Compute a sine table of the given size. Used for testing only."

	| radiansPerStep table |
	table := Array new: size.
	radiansPerStep := (2.0 * Float pi) / table size asFloat.
	1 to: table size do: [:i |
		table at: i put:
			(32767.0 * (radiansPerStep * i) sin) asInteger].

	^ table

]

{ #category : #settings }
SoundPlayer class >> soundQuickStart [
	"Attempt to start sounds immediately. Should always be on unless it causes vm to crash"
	^SoundsShouldStartQuick ifNil: [self defaultQuickStartForPlatform]
]

{ #category : #settings }
SoundPlayer class >> soundQuickStart: aBoolean [
	"Attempt to start sounds immediately"
	SoundsShouldStartQuick := aBoolean
]

{ #category : #accessing }
SoundPlayer class >> soundVolume [
	"Return sound as array of doubles left then right channel, range is 0.0 to 1.0 but may be overdriven"
	^self primSoundGetVolume
]

{ #category : #'player process' }
SoundPlayer class >> startPlayerProcessBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag [
	"Start the sound player process. Terminate the old process, if any."
	"SoundPlayer startPlayerProcessBufferSize: 1000 rate: 11025 stereo: false"
	^self startPlayerProcessBufferSize: bufferSize 
			rate: samplesPerSecond 
			stereo: stereoFlag 
			sound: nil
]

{ #category : #'player process' }
SoundPlayer class >> startPlayerProcessBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag sound: aSound [
	"Start the sound player process. Terminate the old process, if any."
	"SoundPlayer startPlayerProcessBufferSize: 1000 rate: 11025 stereo: false"

	self stopPlayerProcess.
	aSound
		ifNil:[ActiveSounds := OrderedCollection new]
		ifNotNil:[ActiveSounds := OrderedCollection with: aSound].
	Buffer := SoundBuffer newStereoSampleCount: (bufferSize // 4) * 4.
	LastBuffer ifNotNil:[LastBuffer := SoundBuffer basicNew: Buffer basicSize].
	PlayerSemaphore := Semaphore forMutualExclusion.
	SamplingRate := samplesPerSecond.
	Stereo := stereoFlag.
	ReadyForBuffer := Semaphore new.
	SoundSupported := true. "Assume so"
	UseReadySemaphore := true.  "set to false if ready semaphore not supported by VM"
	self primSoundStartBufferSize: Buffer stereoSampleCount
		rate: samplesPerSecond
		stereo: Stereo
		semaIndex: (Smalltalk registerExternalObject: ReadyForBuffer).
	"Check if sound start prim was successful"
	SoundSupported ifFalse:[^self].
	UseReadySemaphore
		ifTrue: [PlayerProcess := [SoundPlayer playLoop] newProcess]
		ifFalse: [PlayerProcess := [SoundPlayer oldStylePlayLoop] newProcess].
	UseReverb ifTrue: [self startReverb].

	PlayerProcess priority: Processor userInterruptPriority.
	PlayerProcess resume.
]

{ #category : #private }
SoundPlayer class >> startPlayingImmediately: aSound [
	"Private! Start playing the given sound as soon as possible by mixing it into the sound output buffers of the underlying sound driver."

	| totalSamples buf |
	"first, fill a double-size buffer with samples"
	"Note: The code below assumes that totalSamples contains two
	 buffers worth of samples, and the insertSamples primitive is
	 expected to consume at least one buffer's worth of these
	 samples. The remaining samples are guaranteed to fit into
	 a single buffer."
	totalSamples := Buffer stereoSampleCount * 2.  "two buffer's worth"
	buf := SoundBuffer newStereoSampleCount: totalSamples.
	aSound playSampleCount: totalSamples into: buf startingAt: 1.
	ReverbState == nil ifFalse: [
		ReverbState applyReverbTo: buf startingAt: 1 count: totalSamples].

	PlayerSemaphore critical: [ | n src leftover rest |
		"insert as many samples as possible into the sound driver's buffers"
		n := self primSoundInsertSamples: totalSamples
			from: buf
			samplesOfLeadTime: 1024.
		n > 0 ifTrue:[
			leftover := totalSamples - n.

			"copy the remainder of buf into Buffer"
			"Note: the following loop iterates over 16-bit words, not two-word stereo slices"
			"assert: 0 < leftover <= Buffer stereoSampleCount"
			src := 2 * n.
			1 to: 2 * leftover do:
				[:dst | Buffer at: dst put: (buf at: (src := src + 1))].

			"generate enough additional samples to finish filling Buffer"
			rest := Buffer stereoSampleCount - leftover.
			aSound playSampleCount: rest into: Buffer startingAt: leftover + 1.
			ReverbState == nil ifFalse: [
				ReverbState applyReverbTo: Buffer startingAt: leftover + 1 count: rest].

			"record the fact that this sound has already been played into Buffer so that we don't process it again this time around"
			SoundJustStarted := aSound.
		] ifFalse:[
			"quick start failed; reset the sound so we start over"
			aSound reset.
		].
		ActiveSounds add: aSound].

]

{ #category : #'player process' }
SoundPlayer class >> startReverb [
	"Start a delay-line style reverb with the given tap delays and gains. Tap delays are given in samples and should be prime integers; the following comment gives an expression that generates primes."
	"Integer primesUpTo: 22050"

	UseReverb := true.
	ReverbState := ReverbSound new
		tapDelays: #(1601 7919) gains: #(0.12 0.07).

]

{ #category : #snapshotting }
SoundPlayer class >> startUp [
	"Start up the player process."

	SoundPlayer initialize.
	SoundPlayer
		startPlayerProcessBufferSize: (BufferMSecs * SamplingRate) // 1000
		rate: SamplingRate
		stereo: Stereo.

]

{ #category : #snapshotting }
SoundPlayer class >> startUpWithSound: aSound [
	"Start up the player process."

	SoundPlayer initialize.
	SoundPlayer
		startPlayerProcessBufferSize: (BufferMSecs * SamplingRate) // 1000
		rate: SamplingRate
		stereo: Stereo
		sound: aSound.

]

{ #category : #accessing }
SoundPlayer class >> stereo [

	^ Stereo

]

{ #category : #'player process' }
SoundPlayer class >> stopPlayerProcess [
	"Stop the sound player process."
	"SoundPlayer stopPlayerProcess"

	(PlayerProcess == nil or:[PlayerProcess == Processor activeProcess]) 
		ifFalse:[PlayerProcess terminate].
	PlayerProcess := nil.
	self primSoundStop.
	ActiveSounds := OrderedCollection new.
	Buffer := nil.
	PlayerSemaphore := Semaphore forMutualExclusion.
	ReadyForBuffer ifNotNil:
		[Smalltalk unregisterExternalObject: ReadyForBuffer].
	ReadyForBuffer := nil.

]

{ #category : #playing }
SoundPlayer class >> stopPlayingAll [
	"Stop playing all sounds."

	PlayerSemaphore critical: [
		ActiveSounds := ActiveSounds species new].

]

{ #category : #'player process' }
SoundPlayer class >> stopReverb [

	UseReverb := false.
	ReverbState := nil.

]

{ #category : #settings }
SoundPlayer class >> stopSoundWhenDone [
	"If true, the sound player is shut down after playing finished"
	^(SoundsStopWhenDone ifNil: [self defaultStopSoundForPlatform]) 
]

{ #category : #settings }
SoundPlayer class >> stopSoundWhenDone: aBoolean [
	"If true, the sound player is shut down after playing finished"
	SoundsStopWhenDone := aBoolean
]

{ #category : #initialization }
SoundPlayer class >> useLastBuffer [
	^LastBuffer notNil
]

{ #category : #initialization }
SoundPlayer class >> useLastBuffer: aBool [
	Buffer ifNil:[^self].
	aBool 
		ifTrue:[LastBuffer := SoundBuffer basicNew: Buffer basicSize]
		ifFalse:[LastBuffer := nil]	
]

{ #category : #initialization }
SoundPlayer class >> useShortBuffer [
	"Experimental support for real-time MIDI input. This only works on platforms whose hardware allows very short buffer sizes. It has been tested on a Macintosh Powerbook G3."
	"SoundPlayer useShortBuffer"

	self shutDown.
	BufferMSecs := 15.
	SoundPlayer
		startPlayerProcessBufferSize: (BufferMSecs * SamplingRate) // 1000
		rate: SamplingRate
		stereo: Stereo.

]

{ #category : #playing }
SoundPlayer class >> waitUntilDonePlaying: aSound [
	"Wait until the given sound is no longer playing."

	[PlayerSemaphore critical: [ActiveSounds includes: aSound]]
		whileTrue: [(Delay forMilliseconds: 100) wait].

]
