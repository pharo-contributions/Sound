Extension { #name : #Player }

{ #category : #'*sound' }
Player >> getConePosition [
	"Note: Performance hacked to allow real-time sound. Assumes costume is a SpeakerMorph."

	^ costume renderedMorph conePosition

]

{ #category : #'*sound' }
Player >> setConePosition: aNumber [
	"Note: Performance hacked to allow real-time sound. Assumes costume is a SpeakerMorph."

	costume renderedMorph conePosition: aNumber.

]
