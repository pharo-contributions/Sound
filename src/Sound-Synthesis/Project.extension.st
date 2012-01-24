Extension { #name : #Project }

{ #category : #'*sound' }
Project >> beep [
	(PluckedSound pitch: 261.625*4 dur: 1 loudness: 0.1) play
]
