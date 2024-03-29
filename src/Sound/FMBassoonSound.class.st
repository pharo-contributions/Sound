Class {
	#name : 'FMBassoonSound',
	#superclass : 'FMSound',
	#category : 'Sound-Core',
	#package : 'Sound',
	#tag : 'Core'
}

{ #category : 'backward compatibility' }
FMBassoonSound >> setPitch: pitchNameOrNumber dur: d loudness: l [
	"Select a modulation ratio and modulation envelope scale based on my pitch."

	self setPitch: pitchNameOrNumber duration: d loudness: l
]

{ #category : 'initialization' }
FMBassoonSound >> setPitch: pitchNameOrNumber duration: d loudness: l [
	"Select a modulation ratio and modulation envelope scale based on my pitch."

	| p modScale |
	p := self nameOrNumberToPitch: pitchNameOrNumber.
	modScale := 9.4.
	p > 100.0 ifTrue: [modScale := 8.3].
	p > 150.0 ifTrue: [modScale := 6.4].
	p > 200.0 ifTrue: [modScale := 5.2].
	p > 300.0 ifTrue: [modScale := 3.9].
	p > 400.0 ifTrue: [modScale := 2.8].
	p > 600.0 ifTrue: [modScale := 1.7].

	envelopes size > 0 ifTrue: [
		envelopes do: [:e |
			(e updateSelector = #modulation:)
				ifTrue: [e scale: modScale]]].

	super setPitch: p duration: d loudness: l.

]
