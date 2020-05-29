Class {
	#name : #SoundLoopMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'samplesUntilNextControl',
		'seqSound',
		'cursor',
		'controlIndex'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #adding }
SoundLoopMorph >> addCursorMorph [
	self addMorph:
		(cursor := (BorderedMorph
				newBounds: (self innerBounds topLeft extent: 1@self innerBounds height)
				color: Color red)
						borderWidth: 0)
]

{ #category : #private }
SoundLoopMorph >> buildSound [
	"Build a compound sound for the next iteration of the loop."

	| mixer soundMorphs startTime pan |
	mixer := MixedSound new.
	mixer add: (RestSound dur: (self width - (2 * borderWidth)) / 128.0).
	soundMorphs := self submorphs select: [:m | m respondsTo: #sound].
	soundMorphs do: [:m |
		startTime := (m position x - (self left + borderWidth)) / 128.0.
		pan := (m position y - (self top + borderWidth)) asFloat / (self height - (2 * borderWidth) - m height).
		mixer add: ((RestSound dur: startTime), m sound copy) pan: pan].
	^ mixer

]

{ #category : #playing }
SoundLoopMorph >> controlRate [
	"Answer the number of control changes per second."

	^ 32

]

{ #category : #initialization }
SoundLoopMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 1
]

{ #category : #initialization }
SoundLoopMorph >> defaultBounds [
"answer the default bounds for the receiver"
	^ 0 @ 0 corner: 128 @ 128 + (self defaultBorderWidth * 2)
]

{ #category : #initialization }
SoundLoopMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color lightBlue
]

{ #category : #playing }
SoundLoopMorph >> doControl [

	seqSound doControl.
	controlIndex := controlIndex + 1.
	controlIndex >= (self controlRate * (self innerBounds width // 128))
		ifTrue: [controlIndex := 0].

]

{ #category : #geometry }
SoundLoopMorph >> extent: newExtent [
	super extent: (newExtent truncateTo: 128@128) + (self borderWidth*2)
]

{ #category : #initialization }
SoundLoopMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	
	controlIndex := 0.
	self addCursorMorph
]

{ #category : #playing }
SoundLoopMorph >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Repeatedly play my sounds."

	| i count samplesNeeded |
	i := startIndex.
	samplesNeeded := n.
	[samplesNeeded > 0] whileTrue: [
		count := seqSound samplesRemaining min: samplesNeeded.
		count = 0 ifTrue: [
			self reset.
			count := seqSound samplesRemaining min: samplesNeeded.
			count = 0 ifTrue: [^ self]].  "zero length sound"
		seqSound mixSampleCount: count into: aSoundBuffer startingAt: i leftVol: leftVol rightVol: rightVol.
		i := i + count.
		samplesNeeded := samplesNeeded - count].

]

{ #category : #playing }
SoundLoopMorph >> play [
	"Play this sound to the sound ouput port in real time."

	self reset.
	SoundPlayer playSound: self.

]

{ #category : #playing }
SoundLoopMorph >> playSampleCount: n into: aSoundBuffer startingAt: startIndex [
	"Mixes the next count samples of this sound into the given buffer starting at the given index, updating the receiver's control parameters at periodic intervals."

	| fullVol samplesBetweenControlUpdates pastEnd i remainingSamples count |
	fullVol := AbstractSound scaleFactor.
	samplesBetweenControlUpdates := self samplingRate // self controlRate.
	pastEnd := startIndex + n.  "index just index of after last sample"
	i := startIndex.
	[i < pastEnd] whileTrue: [
		remainingSamples := self samplesRemaining.
		remainingSamples <= 0 ifTrue: [^ self].
		count := pastEnd - i.
		samplesUntilNextControl < count ifTrue: [count := samplesUntilNextControl].
		remainingSamples < count ifTrue: [count := remainingSamples].
		self mixSampleCount: count into: aSoundBuffer startingAt: i leftVol: fullVol rightVol: fullVol.
		samplesUntilNextControl := samplesUntilNextControl - count.
		samplesUntilNextControl <= 0 ifTrue: [
			self doControl.
			samplesUntilNextControl := samplesBetweenControlUpdates].
		i := i + count].

]

{ #category : #playing }
SoundLoopMorph >> positionCursor [
	| x |
	x := controlIndex * 128 // self controlRate.
	cursor position: self innerBounds topLeft + (x@0)

]

{ #category : #playing }
SoundLoopMorph >> reset [
	"Reset my internal state for a replay."

	seqSound := self buildSound reset.
	samplesUntilNextControl := (self samplingRate // self controlRate).
	controlIndex := 0.
	self positionCursor
]

{ #category : #playing }
SoundLoopMorph >> samplesRemaining [

	^ 1000000

]

{ #category : #playing }
SoundLoopMorph >> samplingRate [
	"Answer the sampling rate in samples per second."

	^ SoundPlayer samplingRate
]

{ #category : #'stepping and presenter' }
SoundLoopMorph >> step [
	self positionCursor
]

{ #category : #testing }
SoundLoopMorph >> stepTime [

	^ 50

]

{ #category : #'stepping and presenter' }
SoundLoopMorph >> stop [
	"Stop playing this sound."

	SoundPlayer pauseSound: self.

]

{ #category : #'dropping/grabbing' }
SoundLoopMorph >> wantsDroppedMorph: aMorph event: evt [

	^ aMorph respondsTo: #sound

]
