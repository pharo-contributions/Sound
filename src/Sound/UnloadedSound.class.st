"
Instances of me, which are really just FMSounds, are used placeholders for sounds that have been unloaded from this image but which may be re-loaded later.

"
Class {
	#name : #UnloadedSound,
	#superclass : #FMSound,
	#category : #'Sound-Synthesis'
}

{ #category : #'as yet unclassified' }
UnloadedSound class >> default [
	"UnloadedSound default play"

	| snd p |
	snd := super new modulation: 1 ratio: 1.
	p := OrderedCollection new.
	p add: 0@0.0; add: 10@1.0; add: 100@1.0; add: 120@0.0.
	snd addEnvelope: (VolumeEnvelope points: p loopStart: 2 loopEnd: 3).
	^ snd setPitch: 440.0 duration: 1.0 loudness: 0.5

]
