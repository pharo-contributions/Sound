Class {
	#name : #SDL2SoundSink,
	#superclass : #SoundSink,
	#instVars : [
		'audioDevice'
	],
	#category : #'Sound-SDL2'
}

{ #category : #accessing }
SDL2SoundSink >> audioDevice [
	^ audioDevice
]

{ #category : #accessing }
SDL2SoundSink >> audioDevice: anObject [
	audioDevice := anObject
]

{ #category : #'mixing process' }
SDL2SoundSink >> computeNextRequiredSampleCount [
	| samplesInAudioDevice totalBufferSize |
	samplesInAudioDevice := (SDL2 getQueuedAudioSize: audioDevice) // 4.
	totalBufferSize := buffer stereoSampleCount.
	
	^ totalBufferSize - samplesInAudioDevice max: 0
]

{ #category : #'driver interface' }
SDL2SoundSink >> doEnqueueAudioBuffer: aBuffer count: sampleCount [
	| result |
	"(self isAllSilence: aBuffer size: sampleCount) ifTrue: [ ^ self ]."
	"Transcript show: 'TODO: doEnqueueAudioBuffer: '; cr"
	"self halt."
	result := SDL2 queueAudio: audioDevice data: aBuffer len: sampleCount * 4.
	result < 0 ifTrue: [
		self error: SDL2 getErrorMessage
	]
]

{ #category : #hooks }
SDL2SoundSink >> pauseAudioDeviceSink [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 1.
]

{ #category : #hooks }
SDL2SoundSink >> resumeAudioDeviceSink [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 0.
]
