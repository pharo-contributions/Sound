Class {
	#name : #SoundPluginSink,
	#superclass : #Object,
	#category : #'Sound-Plugin'
}

{ #category : #'player process' }
SoundPluginSink >> oldStylePlayLoop [
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

{ #category : #'player process' }
SoundPluginSink >> playLoop [
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

{ #category : #private }
SoundPluginSink >> primSoundAvailableBytes [
	"Return the number of bytes of available space in the sound output buffer."
	"Note: Squeak always uses buffers containing 4-bytes per sample (2 channels at 2 bytes per channel) regardless of the state of the Stereo flag."

	<primitive: 'primitiveSoundAvailableSpace' module: 'SoundPlugin'>
	^ self primitiveFailed

]

{ #category : #private }
SoundPluginSink >> primSoundGetVolume [
	"Return sound as array of doubles left then right channel, range is 0.0 to 1.0 but may be overdriven"
	<primitive: 'primitiveSoundGetVolume' module: 'SoundPlugin'>
	^Array with: 1.0 with: 1.0
]

{ #category : #private }
SoundPluginSink >> primSoundInsertSamples: count from: aSoundBuffer samplesOfLeadTime: anInteger [
	"Mix the given number of sample frames from the given sound buffer into the queue of samples that has already been submitted to the sound driver. This primitive is used to start a sound playing with minimum latency, even if large sound output buffers are being used to ensure smooth sound output. Returns the number of samples consumed, or zero if the primitive is not implemented or fails."

	<primitive: 'primitiveSoundInsertSamples' module: 'SoundPlugin'>
	^ 0

]

{ #category : #private }
SoundPluginSink >> primSoundPlaySamples: count from: aSampleBuffer startingAt: index [
	"Copy count bytes into the current sound output buffer from the given sample buffer starting at the given index."

	<primitive: 'primitiveSoundPlaySamples' module: 'SoundPlugin'>
	^ self primitiveFailed

]

{ #category : #private }
SoundPluginSink >> primSoundSetVolumeLeft: aLeftVolume volumeRight: aRightVolume [
	"Set sound pass in float 0.0-1.0 for left and right channel, with possible 2.0 or  higher to overdrive sound channel "
	<primitive: 'primitiveSoundSetLeftVolume' module: 'SoundPlugin'>

]

{ #category : #private }
SoundPluginSink >> primSoundStartBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag [
	"Start double-buffered sound output with the given buffer size and sampling rate. This version has been superceded by primitive 171 (primSoundStartBufferSize:rate:stereo:semaIndex:)."
	"ar 12/5/1998 Turn off the sound if not supported"
	<primitive: 'primitiveSoundStart' module: 'SoundPlugin'>
	SoundSupported := false.
]

{ #category : #private }
SoundPluginSink >> primSoundStartBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag semaIndex: anInteger [
	"Start double-buffered sound output with the given buffer size and sampling rate. If the given semaphore index is > 0, it is taken to be the index of a Semaphore in the external objects array to be signalled when the sound driver is ready to accept another buffer of samples."
	"Details: If this primitive fails, this method tries to use the older version instead."

	<primitive: 'primitiveSoundStartWithSemaphore' module: 'SoundPlugin'>
	UseReadySemaphore := false.
	self primSoundStartBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag.

]

{ #category : #private }
SoundPluginSink >> primSoundStop [
	"Stop double-buffered sound output. Must not raise an error because it is used inside error handling and at system shutdown"

	<primitive: 'primitiveSoundStop' module: 'SoundPlugin'>
]

{ #category : #'player process' }
SoundPluginSink >> startPlayerProcessBufferSize: bufferSize rate: samplesPerSecond stereo: stereoFlag sound: aSound [
	"Start the sound player process. Terminate the old process, if any."
	"SoundPlayer startPlayerProcessBufferSize: 1000 rate: 11025 stereo: false"

	true ifTrue: [ ^ self ].
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
SoundPluginSink >> startPlayingImmediately: aSound [
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
SoundPluginSink >> stopPlayerProcess [
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
