"
I contain setting builders for the Sound package

"
Class {
	#name : #SoundPlayer,
	#superclass : #Object,
	#classVars : [
		'Buffer',
		'BufferIndex',
		'BufferMSecs',
		'ReverbState',
		'SamplingRate',
		'SoundsShouldStartQuick',
		'SoundsStopWhenDone',
		'Stereo',
		'UseReadySemaphore',
		'UseReverb'
	],
	#category : #'Sound-Driver'
}

{ #category : #'primitive test' }
SoundPlayer class >> boinkPitch: p dur: d loudness: l waveTable: waveTable pan: pan [
	"Play a decaying note on the given stream using the given wave table. Used for testing only."

	| decay tableSize amplitude increment cycles i |
	decay := 0.96.
	tableSize := waveTable size.
	amplitude := l asInteger min: 1000.
	increment := ((p asFloat * tableSize asFloat) / self samplingRate asFloat) asInteger.
	increment := (increment max: 1) min: (tableSize // 2).
	cycles := (d * self samplingRate asFloat) asInteger.

	i := 1.
	1 to: cycles do: [:cycle |
		(cycle \\ 100) = 0
			ifTrue: [amplitude := (decay * amplitude asFloat) asInteger].
		i := (((i - 1) + increment) \\ tableSize) + 1.
		self playTestSample: (amplitude * (waveTable at: i)) // 1000 pan: pan].

]

{ #category : #'primitive test' }
SoundPlayer class >> boinkScale [
	<script>
	"Tests the sound output primitives by playing a scale."

	| sineTable pan |
	self flag: 'FIXME: Fix this to not use the primitive directly.'.
	true ifTrue: [ ^ self].
	
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

{ #category : #playing }
SoundPlayer class >> currentSoundSink [
	^ SoundDriver current mainSoundSink
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
	UseReverb ifNil: [UseReverb := true].

]

{ #category : #initialization }
SoundPlayer class >> initializeForPlatform [
	"Apparently, the VM could crash if these were not correct. 
		Change in future if platform support for the features change"
	self soundQuickStart: self defaultQuickStartForPlatform.
	self stopSoundWhenDone: self defaultStopSoundForPlatform.
]

{ #category : #playing }
SoundPlayer class >> isPlaying: aSound [
	^ self currentSoundSink isPlaying: aSound
]

{ #category : #'player process' }
SoundPlayer class >> isReverbOn [

	^ ReverbState ~~ nil

]

{ #category : #playing }
SoundPlayer class >> pauseSound: aSound [
	"Stop playing the given sound. Playing can be resumed from this point later."
	^ self currentSoundSink pauseSound: aSound

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

{ #category : #'as yet unclassified' }
SoundPlayer class >> playerProcess [
	^ nil
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
	self currentSoundSink resumePlaying: aSound quickStart: doQuickStart
]

{ #category : #accessing }
SoundPlayer class >> reverbState [

	^ ReverbState
]

{ #category : #accessing }
SoundPlayer class >> samplingRate [

	^ self currentSoundSink samplingRate
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

	"SoundPlayer initialize.
	SoundPlayer
		startPlayerProcessBufferSize: (BufferMSecs * SamplingRate) // 1000
		rate: SamplingRate
		stereo: Stereo."

]

{ #category : #snapshotting }
SoundPlayer class >> startUpWithSound: aSound [
	"Start up the player process."

	"SoundPlayer initialize.
	SoundPlayer
		startPlayerProcessBufferSize: (BufferMSecs * SamplingRate) // 1000
		rate: SamplingRate
		stereo: Stereo
		sound: aSound."

]

{ #category : #accessing }
SoundPlayer class >> stereo [

	^ Stereo

]

{ #category : #playing }
SoundPlayer class >> stopPlayingAll [
	"Stop playing all sounds."
	self currentSoundSink stopPlayingAll
]

{ #category : #'player process' }
SoundPlayer class >> stopReverb [

	UseReverb := false.
	ReverbState := nil.

]

{ #category : #settings }
SoundPlayer class >> stopSoundWhenDone [
	"If true, the sound player is shut down after playing finished"
	^ SoundsStopWhenDone ifNil: [self defaultStopSoundForPlatform]
]

{ #category : #settings }
SoundPlayer class >> stopSoundWhenDone: aBoolean [
	"If true, the sound player is shut down after playing finished"
	SoundsStopWhenDone := aBoolean
]

{ #category : #initialization }
SoundPlayer class >> useShortBuffer [
	"Experimental support for real-time MIDI input. This only works on platforms whose hardware allows very short buffer sizes. It has been tested on a Macintosh Powerbook G3."
	"SoundPlayer useShortBuffer"

	"self shutDown.
	BufferMSecs := 15.
	SoundPlayer
		startPlayerProcessBufferSize: (BufferMSecs * SamplingRate) // 1000
		rate: SamplingRate
		stereo: Stereo."

]

{ #category : #playing }
SoundPlayer class >> waitUntilDonePlaying: aSound [
	"Wait until the given sound is no longer playing."
	self currentSoundSink waitUntilDonePlaying: aSound.

]
