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

{ #category : 'as yet unclassified' }
SDL2CaptureSink >> dequeueCapturedCount [
	^ SDL2 getQueuedAudioSize: self audioDevice
]

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
SDL2CaptureSink >> startCapturing [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 0.
]

{ #category : 'as yet unclassified' }
SDL2CaptureSink >> stopCapture [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 1
]
