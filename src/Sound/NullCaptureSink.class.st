Class {
	#name : 'NullCaptureSink',
	#superclass : 'CaptureSink',
	#category : 'Sound-Driver',
	#package : 'Sound',
	#tag : 'Driver'
}

{ #category : 'capture' }
NullCaptureSink >> doDequeueBuffer [

	^ SoundBuffer new
]
