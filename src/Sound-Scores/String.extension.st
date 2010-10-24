Extension { #name : #String }

{ #category : #'*sound-synthesis' }
String >> asSound [
	"Return a sound. Either from the sound library via SampleSound or
	else the Beeper default"
	^ SampledSound
		soundNamed: self
		ifAbsent: [Beeper default]
]
