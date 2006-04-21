Extension { #name : #ProjectViewMorph }

{ #category : #'*sound-piano rolls' }
ProjectViewMorph >> triggerActionFromPianoRoll [

	WorldState addDeferredUIMessage: [
		project world setProperty: #letTheMusicPlay toValue: true.
		self enter.
	]
]
