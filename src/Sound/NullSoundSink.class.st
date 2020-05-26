Class {
	#name : #NullSoundSink,
	#superclass : #SoundSink,
	#category : #'Sound-Driver'
}

{ #category : #'as yet unclassified' }
NullSoundSink >> startMixingProcess [
	"Do not start the mixing process with a null sound sink."
]
