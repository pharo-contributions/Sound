Extension { #name : #ZASMCameraMarkMorph }

{ #category : #'*sound-piano rolls' }
ZASMCameraMarkMorph >> addMorphsTo: morphList pianoRoll: pianoRoll eventTime: t betweenTime: leftTime and: rightTime [

	| startX pseudoEndTime |

	startX := pianoRoll xForTime: startTimeInScore.
	pseudoEndTime := pianoRoll timeForX: startX + self width.
	startTimeInScore > rightTime ifTrue: [^ self].  
	pseudoEndTime < leftTime ifTrue: [^ self].

	morphList add: 
		(self align: self bottomLeft
			with: startX @ self bottom).


]

{ #category : #'*sound-piano rolls' }
ZASMCameraMarkMorph >> encounteredAtTime: ticks inScorePlayer: scorePlayer atIndex: index inEventTrack: track secsPerTick: secsPerTick [

	| nextAmbient m nextDurationInMs program now finalMark thisPage nextPage |

	self gotoMark.
	nextAmbient := nil.
	index to: track size do: [ :i |
		(nextAmbient isNil and: [((m := track at: i) morph) isKindOf: self class]) ifTrue: [
			nextAmbient := m.
		].
	].
	nextAmbient ifNil: [^self].
	nextDurationInMs := (nextAmbient time - ticks * secsPerTick * 1000) rounded.
	finalMark := nextAmbient morph.
	thisPage := self valueOfProperty: #bookPage.
	nextPage := finalMark valueOfProperty: #bookPage.
	(thisPage = nextPage or: [thisPage isNil | nextPage isNil]) ifFalse: [^finalMark gotoMark].
	now := Time millisecondClockValue.
	program := Dictionary new.
	program
		at: #startTime put: now;
		at: #endTime put: now + nextDurationInMs;
		at: #startPoint put: (self valueOfProperty: #cameraPoint);
		at: #endPoint put: (finalMark valueOfProperty: #cameraPoint);
		at: #startZoom put: (self valueOfProperty: #cameraScale);
		at: #endZoom put: (finalMark valueOfProperty: #cameraScale).

	self cameraController setProgrammedMoves: {program}.


]

{ #category : #'*sound-piano rolls' }
ZASMCameraMarkMorph >> pauseFrom: scorePlayer [

	self cameraController pauseProgrammedMoves.
]

{ #category : #'*sound-piano rolls' }
ZASMCameraMarkMorph >> resumeFrom: scorePlayer [

	self cameraController resumeProgrammedMoves
]
