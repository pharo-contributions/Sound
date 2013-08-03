Class {
	#name : #PianoKeyboardMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'whiteKeyColor',
		'blackKeyColor',
		'playingKeyColor',
		'nOctaves',
		'target',
		'noteOnSelector',
		'noteOffSelector',
		'soundPrototype',
		'soundPlaying'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #'parts bin' }
PianoKeyboardMorph class >> descriptionForPartsBin [
	^ self partName:	'PianoKeyboard'
		categories:		#('Multimedia')
		documentation:	'A piano keyboard'
]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> buildKeyboard [
	| wtWid bkWid keyRect octavePt nWhite nBlack |
	self removeAllMorphs.
	wtWid := 8. bkWid := 5.
	self extent: 10@10.
	1 to: nOctaves+1 do:
		[:i | i <= nOctaves ifTrue: [nWhite := 7.  nBlack := 5]
						ifFalse: [nWhite := 1.  nBlack := 0 "High C"].
		octavePt := self innerBounds topLeft + ((7*wtWid*(i-1)-1) @ -1).
		1 to: nWhite do:
			[:j | | val |
			keyRect := octavePt + (j-1*wtWid@0) extent: (wtWid+1)@36.
			val := i-1*12 + (#(1 3 5 6 8 10 12) at: j).
			self addMorph: ((BorderedMorph newBounds: keyRect color: whiteKeyColor)
								borderWidth: 1;
				on: #mouseDown send: #mouseDownPitch:event:noteMorph: to: self
								withValue: val;
				on: #mouseUp 
					send: #mouseUpPitch:event:noteMorph: 
					to: self 
					withValue: val;
				on: #mouseLeaveDragging 
					send: #mouseUpPitch:event:noteMorph: 
					to: self 
					withValue: val;
				on: #mouseMove 
					send: #mouseMovePitch:event:noteMorph: 
					to: self 
					withValue: val;
				on: #mouseEnterDragging send: #mouseDownPitch:event:noteMorph: to: self			
								withValue: val)				
								].
		1 to: nBlack do:
			[:j | |val|
			keyRect := octavePt + ((#(6 15 29 38 47) at: j)@1) extent: bkWid@21.
			val := i-1*12 + (#(2 4 7 9 11) at: j).
			self addMorph: ((Morph newBounds: keyRect color: blackKeyColor)
				on: #mouseDown send: #mouseDownPitch:event:noteMorph: to: self
								withValue: val;
				on: #mouseUp 
					send: #mouseUpPitch:event:noteMorph: 
					to: self 
					withValue: val	;
				on: #mouseLeaveDragging 
					send: #mouseUpPitch:event:noteMorph: 
					to: self 
					withValue: val;
				on: #mouseMove 
					send: #mouseMovePitch:event:noteMorph: 
					to: self 
					withValue: val;
				on: #mouseEnterDragging send: #mouseDownPitch:event:noteMorph: to: self			
								withValue: val
					)]].
	self extent: (self fullBounds extent + borderWidth - 1)
]

{ #category : #initialization }
PianoKeyboardMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color veryLightGray
]

{ #category : #initialization }
PianoKeyboardMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	
	whiteKeyColor := Color gray: 0.95.
	blackKeyColor := Color black.
	playingKeyColor := Color red.
	nOctaves := 6.
	self buildKeyboard.
	soundPrototype := FMSound brass1 duration: 9.9
]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> mouseDownEvent: arg1 noteMorph: arg2 pitch: arg3 [
	"Reorder the arguments for existing event handlers"
	(arg3 isMorph and:[arg3 eventHandler notNil]) ifTrue:[arg3 eventHandler fixReversedValueMessages].
	^self mouseDownPitch: arg1 event: arg2 noteMorph: arg3
]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> mouseDownPitch: midiKey event: event noteMorph: noteMorph [
	| pitch |
	event hand hasSubmorphs ifTrue: [^ self  "no response if drag something over me"].
	event hand mouseFocus ifNil:
		["If dragged into me, then establish focus so I'll see moves"
		event hand newMouseFocus: noteMorph event: event].
	noteMorph color: playingKeyColor.
	pitch := AbstractSound pitchForMIDIKey: midiKey + 23.
	soundPlaying ifNotNil: [soundPlaying stopGracefully].
	soundPlaying := soundPrototype soundForPitch: pitch dur: 100.0 loudness: 0.3.
	SoundPlayer resumePlaying: soundPlaying quickStart: true.

]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> mouseMoveEvent: arg1 noteMorph: arg2 pitch: arg3 [
	"Reorder the arguments for existing event handlers"
	(arg3 isMorph and:[arg3 eventHandler notNil]) ifTrue:[arg3 eventHandler fixReversedValueMessages].
	^self mouseMovePitch: arg1 event: arg2 noteMorph: arg3
]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> mouseMovePitch: pitch event: event noteMorph: noteMorph [

	(noteMorph containsPoint: event cursorPoint) ifFalse:
		["If drag out of me, zap focus so other morphs can see drag in."
		event hand releaseMouseFocus: noteMorph]

]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> mouseUpEvent: arg1 noteMorph: arg2 pitch: arg3 [
	"Reorder the arguments for existing event handlers"
	(arg3 isMorph and:[arg3 eventHandler notNil]) ifTrue:[arg3 eventHandler fixReversedValueMessages].
	^self mouseUpPitch: arg1 event: arg2 noteMorph: arg3
]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> mouseUpPitch: pitch event: event noteMorph: noteMorph [

	noteMorph color: ((#(0 1 3 5 6 8 10) includes: pitch\\12)
					ifTrue: [whiteKeyColor]
					ifFalse: [blackKeyColor]).
	soundPlaying ifNotNil: [soundPlaying stopGracefully].

]

{ #category : #'simple keyboard' }
PianoKeyboardMorph >> soundPrototype: aSound [
	soundPrototype := aSound
]
