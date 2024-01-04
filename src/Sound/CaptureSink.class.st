Class {
	#name : 'CaptureSink',
	#superclass : 'Object',
	#instVars : [
		'channels',
		'sampleRate',
		'capturingProcess',
		'dequeueCallbacks',
		'dequeueCallbacksMutex'
	],
	#category : 'Sound-Driver',
	#package : 'Sound',
	#tag : 'Driver'
}

{ #category : 'adding' }
CaptureSink >> addDequeueBufferCallback: aBlock [
	dequeueCallbacksMutex critical: [ dequeueCallbacks add: aBlock ].
	^ aBlock
]

{ #category : 'initialization' }
CaptureSink >> captureWithSampleRate: aSampleRate andChannels: numOfChannels [
	self assert: numOfChannels >= 1.
	self assert: numOfChannels <= 2. "Until we support more than two channels."
	
	sampleRate := aSampleRate.
	channels := numOfChannels.
	
	self startCapturing.
	self startCaptureProcess.
	
]

{ #category : 'process' }
CaptureSink >> capturingProcessLoop [
	[ true ] whileTrue: [
		| dequedBuffer |
		dequeueCallbacksMutex critical: [
			dequeueCallbacks ifNotEmpty: [
				dequedBuffer := self doDequeueBuffer.
				dequeueCallbacks do: [ :callback | callback value: dequedBuffer ] ] ].
		(Delay forMilliseconds: 20) wait ]
]

{ #category : 'accessing' }
CaptureSink >> channels [
	^ channels
]

{ #category : 'process' }
CaptureSink >> createCaptureWithCallback: aBlock [

	^ [
	  [ true ] whileTrue: [
		  | dequeuedBuffer |
		  dequeuedBuffer := self doDequeueBuffer.
		  aBlock value: dequeuedBuffer.

		  "workaround for OSS emulation on top on ALSA (on Linux environments)"
		  (Delay forMilliseconds: 20) wait ] ] newProcess
]

{ #category : 'initialization' }
CaptureSink >> createNullCaptureSink [
	^ NullCaptureSink new
]

{ #category : 'capture' }
CaptureSink >> doDequeueBuffer [

]

{ #category : 'initialization' }
CaptureSink >> initialize [ 
	dequeueCallbacksMutex := Semaphore forMutualExclusion.
	dequeueCallbacks := LinkedList new.
]

{ #category : 'adding' }
CaptureSink >> removeDequeueBufferCallback: aBlock [
	dequeueCallbacksMutex critical: [
		dequeueCallbacks remove: aBlock ifAbsent: nil ]
]

{ #category : 'accessing' }
CaptureSink >> sampleRate [
	^ sampleRate
]

{ #category : 'process' }
CaptureSink >> startCaptureProcess [
	capturingProcess := [ self capturingProcessLoop ] newProcess.
	capturingProcess priority: Processor userInterruptPriority.
	capturingProcess resume
]

{ #category : 'capture' }
CaptureSink >> startCapturing [
]

{ #category : 'capture' }
CaptureSink >> stopCapture [
]
