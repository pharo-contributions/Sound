"
This subclass of SoundRecorder supports real-time processing of incoming sound data. The sound input process queues raw sound buffers, allowing them to be read and processed by the client as they become available. A semaphore is used to synchronize between the record process and the client process. Since sound data is buffered, the client process may lag behind the input process without losing data.

"
Class {
	#name : #SoundInputStream,
	#superclass : #SoundRecorder,
	#instVars : [
		'bufferSize',
		'mutex'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #private }
SoundInputStream >> allocateBuffer [
	"Allocate a new buffer and reset nextIndex. This message is sent by the sound input process."

	currentBuffer := SoundBuffer newMonoSampleCount: bufferSize.
	nextIndex := 1.

]

{ #category : #accessing }
SoundInputStream >> bufferCount [
	"Answer the number of sound buffers that have been queued."

	| n |
	mutex ifNil: [^ 0].  "not recording"
	mutex critical: [n := recordedBuffers size].
	^ n

]

{ #category : #accessing }
SoundInputStream >> bufferSize [

	^ bufferSize

]

{ #category : #accessing }
SoundInputStream >> bufferSize: aNumber [
	"Set the sound buffer size. Buffers of this size will be queued for the client to process."

	bufferSize := aNumber truncated.

]

{ #category : #private }
SoundInputStream >> emitBuffer: buffer [
	"Queue a buffer for later processing. This message is sent by the sound input process."

	mutex critical: [recordedBuffers addLast: buffer].

]

{ #category : #initialization }
SoundInputStream >> initialize [

	super initialize.
	bufferSize := 1024.
	mutex := nil.

]

{ #category : #accessing }
SoundInputStream >> isRecording [
	"Answer true if the sound input process is running."

	^ recordProcess ~~ nil

]

{ #category : #accessing }
SoundInputStream >> nextBufferOrNil [
	"Answer the next input buffer or nil if no buffer is available."

	| result |
	mutex ifNil: [^ nil].  "not recording"
	mutex critical: [
		recordedBuffers size > 0
			ifTrue: [result := recordedBuffers removeFirst]
			ifFalse: [result := nil]].
	^ result

]

{ #category : #'recording controls' }
SoundInputStream >> startRecording [
	"Start the sound input process."

	recordProcess ifNotNil: [self stopRecording].
	recordedBuffers := OrderedCollection new: 100.
	mutex := Semaphore forMutualExclusion.
	super startRecording.
	paused := false.

]

{ #category : #'recording controls' }
SoundInputStream >> stopRecording [
	"Turn off the sound input process and close the driver."

	super stopRecording.
	recordedBuffers := nil.
	mutex := nil.

]
