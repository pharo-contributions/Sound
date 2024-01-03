Class {
	#name : 'CaptureSink',
	#superclass : 'Object',
	#category : 'Sound-Driver',
	#package : 'Sound',
	#tag : 'Driver'
}

{ #category : 'accessing' }
CaptureSink >> createNullCaptureSink [
	^ NullCaptureSink new
]

{ #category : 'as yet unclassified' }
CaptureSink >> doDequeueBuffer [
]

{ #category : 'as yet unclassified' }
CaptureSink >> startCapturing [
]

{ #category : 'as yet unclassified' }
CaptureSink >> stopCapture [
]
