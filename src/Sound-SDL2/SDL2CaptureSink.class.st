Class {
	#name : 'SDL2CaptureSink',
	#superclass : 'CaptureSink',
	#instVars : [
		'audioDevice'
	],
	#pools : [
		'SDL2Constants'
	],
	#category : 'Sound-SDL2',
	#package : 'Sound-SDL2'
}

{ #category : 'accessing' }
SDL2CaptureSink >> audioDevice [ 
	^ audioDevice 
]

{ #category : 'accessing' }
SDL2CaptureSink >> audioDevice: anObject [
	audioDevice := anObject 
]

{ #category : 'capture' }
SDL2CaptureSink >> dequeueCapturedCount [
	^ SDL2 getQueuedAudioSize: self audioDevice
]

{ #category : 'capture' }
SDL2CaptureSink >> doDequeueBuffer [
	| result sampleCount dequeueBuffer |
	sampleCount := self dequeueCapturedCount.
	dequeueBuffer := SoundBuffer newStereoSampleCount: sampleCount // 4.
	result := SDL2 dequeueAudio: audioDevice data: dequeueBuffer len: sampleCount.
	result < 0 ifTrue: [
		self error: SDL2 getErrorMessage
	].
	^ dequeueBuffer 
	
]

{ #category : 'capture' }
SDL2CaptureSink >> startCapturing [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 0.
]

{ #category : 'capture' }
SDL2CaptureSink >> stopCapture [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 1
]
