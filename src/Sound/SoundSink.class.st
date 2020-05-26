"
I represent a place where sound is directed to. I am a sink for sound. I can be typically something like a speaker or headphone, but in the case of some sound drivers I may represent something more abstract.
"
Class {
	#name : #SoundSink,
	#superclass : #Object,
	#instVars : [
		'activeSounds',
		'activeSoundsMutex',
		'samplingRate',
		'buffer',
		'mixingProcess'
	],
	#category : #'Sound-Driver'
}

{ #category : #'as yet unclassified' }
SoundSink >> computeNextRequiredSampleCount [
	^ 0
]

{ #category : #'as yet unclassified' }
SoundSink >> doEnqueueAudioBuffer: aBuffer count: sampleCount [
	"This is the place for actually sending a buffer into the sound device sink."
	
]

{ #category : #'as yet unclassified' }
SoundSink >> isAllSilence: aBuffer size: count [
	"return true if the buffer is all silence after reverb has ended"
	| value |
	value := buffer at: 1.
	2 to: count do:[:i| (buffer at: i) = value ifFalse:[^false]].
	^true
]

{ #category : #playing }
SoundSink >> isPlaying: aSound [
	^ activeSoundsMutex critical: [
		activeSounds includes: aSound
	].
]

{ #category : #'as yet unclassified' }
SoundSink >> mixAndEnqueueNextAudioBuffer [
	| sampleCount |
	sampleCount := buffer stereoSampleCount.
	buffer primFill: 0.
	activeSoundsMutex critical: [
		activeSounds := activeSounds select: [ :snd | snd samplesRemaining > 0 ].
		activeSounds do: [ :each |
			each playSampleCount: sampleCount into: buffer startingAt: 1
		]
	].
	self doEnqueueAudioBuffer: buffer count: buffer stereoSampleCount.

]

{ #category : #'as yet unclassified' }
SoundSink >> mixAndEnqueueNextAudioBufferOfSize: sampleCount [
	buffer primFill: 0.
	activeSoundsMutex critical: [
		activeSounds := activeSounds select: [ :snd | snd samplesRemaining > 0 ].
		activeSounds do: [ :each |
			each playSampleCount: sampleCount into: buffer startingAt: 1
		]
	].
	self doEnqueueAudioBuffer: buffer count: sampleCount.

]

{ #category : #'as yet unclassified' }
SoundSink >> mixingProcessLoop [
	| bufferFlyingTime |
	
	bufferFlyingTime := buffer stereoSampleCount * 1000 // samplingRate // 3.

	buffer primFill: 0.
	[true] whileTrue: [
		| iterationStartTime iterationEndTime iterationDeltaTime delayTime nextRequiredSamples |
		iterationStartTime := Time microsecondClockValue.
		nextRequiredSamples := self computeNextRequiredSampleCount.
		nextRequiredSamples > 0 ifTrue: [
			self mixAndEnqueueNextAudioBufferOfSize: nextRequiredSamples.
		].

		iterationEndTime := Time microsecondClockValue.
		iterationDeltaTime := (iterationEndTime - iterationStartTime) // 1000.
		delayTime := bufferFlyingTime - iterationDeltaTime - 1.
		delayTime > 0 ifTrue: [ 
			(Delay forMilliseconds: bufferFlyingTime) wait
		].	
	]
]

{ #category : #hooks }
SoundSink >> pauseAudioDeviceSink [
	"This is the place for pausing the audio device"
]

{ #category : #playing }
SoundSink >> pauseSound: aSound [
	activeSoundsMutex critical: [
		activeSounds remove: aSound ifAbsent: []
	].
]

{ #category : #hooks }
SoundSink >> resumeAudioDeviceSink [
	"This is the place for resuming the audio device"
]

{ #category : #playing }
SoundSink >> resumePlaying: aSound quickStart: doQuickStart [
	activeSoundsMutex critical: [
		(activeSounds includes: aSound) ifFalse: [
			activeSounds add: aSound
		]
	].
]

{ #category : #accessing }
SoundSink >> samplingRate [
	^ samplingRate
]

{ #category : #'as yet unclassified' }
SoundSink >> startMixingProcess [
	mixingProcess := [ self mixingProcessLoop ] newProcess.
	mixingProcess priority: Processor userInterruptPriority.
	mixingProcess resume.
	self resumeAudioDeviceSink.

]

{ #category : #'as yet unclassified' }
SoundSink >> startMixingProcessWithBufferSize: theBufferSize samplingRate: theSamplingRate numchannels: numchannels [
	self assert: numchannels >= 1.
	self assert: numchannels <= 2. "Until we support more than two channels."
	
	activeSounds := OrderedCollection new.
	activeSoundsMutex := Semaphore forMutualExclusion.
	buffer := numchannels = 1
		ifTrue: [ SoundBuffer newMonoSampleCount: theBufferSize]
		ifFalse: [ SoundBuffer newStereoSampleCount: theBufferSize].
	samplingRate := theSamplingRate.
	self startMixingProcess
]

{ #category : #playing }
SoundSink >> stopMixingProcess [
	mixingProcess ifNil: [ ^ self ].
	mixingProcess terminate.
	mixingProcess := nil.
	self pauseAudioDeviceSink
]

{ #category : #playing }
SoundSink >> stopPlayingAll [
	activeSoundsMutex critical: [
		activeSounds removeAll
	].
]

{ #category : #playing }
SoundSink >> waitUntilDonePlaying: aSound [
	self flag: 'TODO: Use a monitor here'.
	[activeSoundsMutex critical: [activeSounds includes: aSound]]
		whileTrue: [(Delay forMilliseconds: 100) wait].

]
