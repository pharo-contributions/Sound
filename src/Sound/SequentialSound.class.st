Class {
	#name : 'SequentialSound',
	#superclass : 'AbstractSound',
	#instVars : [
		'sounds',
		'currentIndex'
	],
	#category : 'Sound-Core',
	#package : 'Sound',
	#tag : 'Core'
}

{ #category : 'composition' }
SequentialSound >> , aSound [
	"Return the concatenation of the receiver and the argument sound."

	^ self add: aSound

]

{ #category : 'composition' }
SequentialSound >> add: aSound [

	sounds := sounds copyWith: aSound.
	^aSound

]

{ #category : 'composition' }
SequentialSound >> compressWith: codecClass [
	^ self copy transformSounds: [:s | s compressWith: codecClass]
]

{ #category : 'composition' }
SequentialSound >> compressWith: codecClass atRate: aSamplingRate [
	^ self copy transformSounds: [:s | s compressWith: codecClass atRate: aSamplingRate]
]

{ #category : 'copying' }
SequentialSound >> copySounds [
	"Private! Support for copying. Copy my component sounds."

	sounds := sounds collect: [:s | s copy].

]

{ #category : 'sound generation' }
SequentialSound >> doControl [

	super doControl.
	currentIndex > 0
		ifTrue: [(sounds at: currentIndex) doControl].

]

{ #category : 'accessing' }
SequentialSound >> duration [
	"Answer the duration of this sound in seconds."

	"7 dec 2000 - handle compressed sounds. better way??"

	^sounds inject: 0 into: [:totalDuration :snd | totalDuration + snd asSound duration]
]

{ #category : 'initialization' }
SequentialSound >> initialize [

	super initialize.
	sounds := Array new.
	currentIndex := 0.

]

{ #category : 'sound generation' }
SequentialSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Play a collection of sounds in sequence."
	"PluckedSound chromaticScale play"

	| finalIndex i snd remaining count |
	currentIndex = 0 ifTrue: [^ self].  "already done"
	finalIndex := (startIndex + n) - 1.
	i := startIndex.
	[i <= finalIndex] whileTrue: [
		snd := (sounds at: currentIndex).
		[(remaining := snd samplesRemaining) <= 0] whileTrue: [
			"find next undone sound"
			currentIndex < sounds size
				ifTrue: [
					currentIndex := currentIndex + 1.
					snd := (sounds at: currentIndex)]
				ifFalse: [
					currentIndex := 0.
					^ self]].  "no more sounds"
		count := (finalIndex - i) + 1.
		remaining < count ifTrue: [count := remaining].
		snd mixSampleCount: count into: aSoundBuffer startingAt: i leftVol: leftVol rightVol: rightVol.
		i := i + count].

]

{ #category : 'copying' }
SequentialSound >> postCopy [
	"Copy my component sounds."

	super postCopy.
	self copySounds

]

{ #category : 'composition' }
SequentialSound >> pruneFinishedSounds [
	"Remove any sounds that have been completely played."

	| newSnds |
	(currentIndex > 1 and: [currentIndex < sounds size]) ifFalse: [^ self].
	newSnds := sounds copyFrom: currentIndex to: sounds size.
	currentIndex := 1.
	sounds := newSnds.

]

{ #category : 'composition' }
SequentialSound >> removeFirstCompleteSoundOrNil [
	"Remove the first sound if it has been completely recorded."

	| firstSound |

	sounds size > 0 ifFalse: [^ nil].
	firstSound := sounds first.
	sounds := sounds copyFrom: 2 to: sounds size.
	^firstSound

]

{ #category : 'sound generation' }
SequentialSound >> reset [

	super reset.
	sounds do: [:snd | snd reset].
	sounds size > 0 ifTrue: [currentIndex := 1].

]

{ #category : 'sound generation' }
SequentialSound >> samplesRemaining [

	currentIndex = 0
		ifTrue: [^ 0]
		ifFalse: [^ 1000000].

]

{ #category : 'accessing' }
SequentialSound >> sounds [

	^ sounds

]

{ #category : 'copying' }
SequentialSound >> transformSounds: tfmBlock [
	"Private! Support for copying. Copy my component sounds."

	sounds := sounds collect: [:s | tfmBlock value: s].

]
