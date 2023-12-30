Class {
	#name : 'NullSoundSink',
	#superclass : 'SoundSink',
	#category : 'Sound-Driver',
	#package : 'Sound',
	#tag : 'Driver'
}

{ #category : 'mixing process' }
NullSoundSink >> startMixingProcess [
	"Do not start the mixing process with a null sound sink."
]
