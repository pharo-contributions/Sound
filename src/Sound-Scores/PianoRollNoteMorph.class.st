"
A PianoRollNoteMorph is drawn as a simple mroph, but it carries the necessary state to locate its source sound event via its owner (a PianorRollScoreMorph) and the score therein.  Simple editing of pitch and time placement is provided here.
"
Class {
	#name : #PianoRollNoteMorph,
	#superclass : #Morph,
	#instVars : [
		'trackIndex',
		'indexInTrack',
		'hitLoc',
		'editMode',
		'selected',
		'notePlaying'
	],
	#classVars : [
		'SoundPlaying'
	],
	#category : #'Sound-Scores'
}

{ #category : #selecting }
PianoRollNoteMorph >> deselect [

	selected ifFalse: [^ self].
	self changed.
	selected := false.

]

{ #category : #drawing }
PianoRollNoteMorph >> drawOn: aCanvas [

	selected
		ifTrue: [aCanvas frameAndFillRectangle: self fullBounds fillColor: color borderWidth: 1 borderColor: Color black]
		ifFalse: [aCanvas fillRectangle: self bounds color: color].

]

{ #category : #editing }
PianoRollNoteMorph >> editPitch: evt [

	| mk note |
	mk := owner midiKeyForY: evt cursorPoint y.
	note := (owner score tracks at: trackIndex) at: indexInTrack.
	note midiKey = mk ifTrue: [^ self].
	note midiKey: mk.
	self playSound: (self soundOfDuration: 999.0).
	self position: self position x @ ((owner yForMidiKey: mk) - 1)

]

{ #category : #layout }
PianoRollNoteMorph >> fullBounds [

	selected
		ifTrue: [^ bounds expandBy: 1]
		ifFalse: [^ bounds]
]

{ #category : #editing }
PianoRollNoteMorph >> gridToNextQuarter [

	owner score gridTrack: trackIndex toQuarter: 1 at: indexInTrack.
	owner rebuildFromScore
]

{ #category : #editing }
PianoRollNoteMorph >> gridToPrevQuarter [

	owner score gridTrack: trackIndex toQuarter: -1 at: indexInTrack.
	owner rebuildFromScore
]

{ #category : #'event handling' }
PianoRollNoteMorph >> handlesMouseDown: evt [

	^ owner scorePlayer isPlaying not
]

{ #category : #accessing }
PianoRollNoteMorph >> indexInTrack [

	^ indexInTrack
]

{ #category : #menu }
PianoRollNoteMorph >> invokeNoteMenu: evt [
	"Invoke the note's edit menu."

	| menu |
	menu := MenuMorph new defaultTarget: self.
	menu addList:
		#(('grid to next quarter'		gridToNextQuarter)
		('grid to prev quarter'		gridToPrevQuarter)).

	menu popUpEvent: evt in: self world.

]

{ #category : #'event handling' }
PianoRollNoteMorph >> mouseDown: evt [

	hitLoc := evt cursorPoint.
	editMode := nil.
	owner submorphsDo:
		[:m | (m isKindOf: PianoRollNoteMorph) ifTrue: [m deselect]].
	selected := true.
	self changed.
	owner selection: (Array with: trackIndex with: indexInTrack with: indexInTrack).
	self playSound
]

{ #category : #'event handling' }
PianoRollNoteMorph >> mouseMove: evt [ 
	| delta offsetEvt |
	editMode isNil 
		ifTrue: 
			["First movement determines edit mode"

			((delta := evt cursorPoint - hitLoc) dist: 0 @ 0) <= 2 
				ifTrue: [^self	"No significant movement yet."].
			delta x abs > delta y abs 
				ifTrue: 
					[delta x > 0 
						ifTrue: 
							["Horizontal drag"

							editMode := #selectNotes]
						ifFalse: 
							[self playSound: nil.
							offsetEvt := evt copy setCursorPoint: evt cursorPoint + (20 @ 0).
							self invokeNoteMenu: offsetEvt]]
				ifFalse: [editMode := #editPitch	"Vertical drag"]].
	editMode == #editPitch ifTrue: [self editPitch: evt].
	editMode == #selectNotes ifTrue: [self selectNotes: evt]
]

{ #category : #'event handling' }
PianoRollNoteMorph >> mouseUp: evt [

	self playSound: nil
]

{ #category : #'note playing' }
PianoRollNoteMorph >> noteInScore [

	^ (owner score tracks at: trackIndex) at: indexInTrack

]

{ #category : #'note playing' }
PianoRollNoteMorph >> noteOfDuration: duration [

	| note |
	note := self noteInScore.
	^ (owner scorePlayer instrumentForTrack: trackIndex)
			soundForMidiKey: note midiKey
			dur: duration
			loudness: (note velocity asFloat / 127.0)

]

{ #category : #'note playing' }
PianoRollNoteMorph >> playSound [
	"This STARTS a single long sound.  It must be stopped by playing another or nil."

	^ self playSound: (self soundOfDuration: 999.0)
]

{ #category : #'note playing' }
PianoRollNoteMorph >> playSound: aSoundOrNil [

	SoundPlaying ifNotNil: [SoundPlaying stopGracefully].
	SoundPlaying := aSoundOrNil.
	SoundPlaying ifNotNil: [SoundPlaying play].
]

{ #category : #selecting }
PianoRollNoteMorph >> select [

	selected ifTrue: [^ self].
	selected := true.
	self changed
]

{ #category : #selecting }
PianoRollNoteMorph >> selectFrom: selection [ 
	(trackIndex = selection first and: 
			[indexInTrack >= (selection second) and: [indexInTrack <= (selection third)]]) 
		ifTrue: [selected ifFalse: [self select]]
		ifFalse: [selected ifTrue: [self deselect]]
]

{ #category : #selecting }
PianoRollNoteMorph >> selectNotes: evt [

	| lastMorph oldEnd saveOwner |
	saveOwner := owner.
	(owner autoScrollForX: evt cursorPoint x) ifTrue:
		["If scroll talkes place I will be deleted and my x-pos will become invalid."
		owner := saveOwner.
		bounds := bounds withLeft: (owner xForTime: self noteInScore time)].
	oldEnd := owner selection last.
	(owner notesInRect: (evt cursorPoint x @ owner top corner: owner bottomRight))
		do: [:m | m trackIndex = trackIndex ifTrue: [m deselect]].
	self select.  lastMorph := self.
	(owner notesInRect: (self left @ owner top corner: evt cursorPoint x @ owner bottom))
		do: [:m | m trackIndex = trackIndex ifTrue: [m select.  lastMorph := m]].
	owner selection: (Array with: trackIndex with: indexInTrack with: lastMorph indexInTrack).
	lastMorph indexInTrack ~= oldEnd ifTrue:
		["Play last note as selection grows or shrinks"
		owner ifNotNil: [lastMorph playSound]]

]

{ #category : #selecting }
PianoRollNoteMorph >> selected [

	^ selected
]

{ #category : #'note playing' }
PianoRollNoteMorph >> soundOfDuration: duration [

	| sound |
	sound := MixedSound new.
	sound add: (self noteOfDuration: duration)
		pan: (owner scorePlayer panForTrack: trackIndex)
		volume: owner scorePlayer overallVolume *
				(owner scorePlayer volumeForTrack: trackIndex).
	^ sound reset

]

{ #category : #accessing }
PianoRollNoteMorph >> trackIndex [

	^ trackIndex
]

{ #category : #initialization }
PianoRollNoteMorph >> trackIndex: ti indexInTrack: i [

	trackIndex := ti.
	indexInTrack := i.
	selected := false
]
