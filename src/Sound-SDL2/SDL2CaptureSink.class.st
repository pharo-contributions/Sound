Class {
	#name : 'SDL2CaptureSink',
	#superclass : 'CaptureSink',
	#instVars : [
		'audioDevice',
		'sampleRate',
		'channels'
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

{ #category : 'accessing' }
SDL2CaptureSink >> channels [
	^ channels 
]

{ #category : 'accessing' }
SDL2CaptureSink >> channels: aInteger [
 	channels := aInteger 
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

{ #category : 'accessing' }
SDL2CaptureSink >> sampleRate [
	^ sampleRate 
]

{ #category : 'accessing' }
SDL2CaptureSink >> sampleRate: aInteger [
	sampleRate := aInteger
]

{ #category : 'as yet unclassified' }
SDL2CaptureSink >> startCapturing [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 0.
]

{ #category : 'as yet unclassified' }
SDL2CaptureSink >> stopCapture [
	SDL2 pauseAudioDevice: audioDevice pauseOn: 1
]
