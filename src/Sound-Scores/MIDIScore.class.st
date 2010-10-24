"
A MIDIScore is a container for a number of MIDI tracks as well as an ambient track for such things as sounds, book page triggers and other related events.
"
Class {
	#name : #MIDIScore,
	#superclass : #Object,
	#instVars : [
		'tracks',
		'trackInfo',
		'ambientTrack',
		'tempoMap',
		'ticksPerQuarterNote'
	],
	#category : #'Sound-Scores'
}

{ #category : #'ambient track' }
MIDIScore >> addAmbientEvent: evt [
	| i |
	i := ambientTrack findFirst: [:e | e time >= evt time].
	i = 0 ifTrue: [^ ambientTrack := ambientTrack , (Array with: evt)].
	ambientTrack := ambientTrack copyReplaceFrom: i to: i-1 with: (Array with: evt)
]

{ #category : #'ambient track' }
MIDIScore >> ambientEventAfter: eventIndex ticks: scoreTicks [
	| evt |
	(ambientTrack == nil or: [eventIndex > ambientTrack size]) ifTrue: [^ nil].
	evt := ambientTrack at: eventIndex.
	evt time <= scoreTicks ifTrue: [^ evt].
	^ nil
]

{ #category : #'ambient track' }
MIDIScore >> ambientTrack [
	^ ambientTrack ifNil: [ambientTrack := Array new]
]

{ #category : #editing }
MIDIScore >> appendEvent: noteEvent fullDuration: fullDuration at: selection [
	"It is assumed that the noteEvent already has the proper time"

	| track noteLoc |
	track := tracks at: selection first.
	noteLoc := selection third + 1.
	noteEvent midiKey = -1
		ifTrue: [noteLoc := noteLoc - 1]
		ifFalse: ["If not a rest..."
				track := track copyReplaceFrom: noteLoc to: noteLoc - 1
								with: (Array with: noteEvent)].
	track size >= (noteLoc + 1) ifTrue:
		["Adjust times of following events"
		noteLoc + 1 to: track size do:
			[:i | (track at: i) adjustTimeBy: fullDuration]].
	tracks at: selection first put: track
]

{ #category : #editing }
MIDIScore >> cutSelection: selection [

	| track selStartTime delta |
	track := tracks at: selection first.
	selStartTime := (track at: selection second) time.
	track := track copyReplaceFrom: selection second to: selection third with: Array new.
	track size >=  selection second ifTrue:
		["Adjust times of following events"
		delta := selStartTime - (track at: selection second) time.
		selection second to: track size do:
			[:i | (track at: i) adjustTimeBy: delta]].
	tracks at: selection first put: track
]

{ #category : #accessing }
MIDIScore >> durationInTicks [
	
	| t |
	t := 0.
	tracks, {self ambientTrack} do:
		[:track |
		track do:
			[:n | (n isNoteEvent)
				ifTrue: [t := t max: n endTime]
				ifFalse: [t := t max: n time]]].
	^ t

]

{ #category : #editing }
MIDIScore >> eventForTrack: trackIndex after: eventIndex ticks: scoreTick [

	| track evt |
	track := tracks at: trackIndex.
	eventIndex > track size ifTrue: [^ nil].
	evt := track at: eventIndex.
	evt time > scoreTick ifTrue: [^ nil].
	^ evt

]

{ #category : #'ambient track' }
MIDIScore >> eventMorphsDo: aBlock [
	"Evaluate aBlock for all morphs related to the ambient events."

	ambientTrack == nil ifTrue: [^ self].
	ambientTrack do: [:evt | evt morph ifNotNil: aBlock].

]

{ #category : #'ambient track' }
MIDIScore >> eventMorphsWithTimeDo: aBlock [
	"Evaluate aBlock for all morphs and times related to the ambient events."

	ambientTrack == nil ifTrue: [^ self].
	ambientTrack do: [:evt | evt morph ifNotNil: [aBlock value: evt morph value: evt time]].

]

{ #category : #editing }
MIDIScore >> gridToNextQuarterNote: tickTime [

	^ self gridToQuarterNote: tickTime + ticksPerQuarterNote
]

{ #category : #editing }
MIDIScore >> gridToQuarterNote: tickTime [

	^ tickTime truncateTo: ticksPerQuarterNote
]

{ #category : #editing }
MIDIScore >> gridTrack: trackIndex toQuarter: quarterDelta at: indexInTrack [

	| track selStartTime delta |
	track := tracks at: trackIndex.
	selStartTime := (track at: indexInTrack) time.
	delta := (self gridToQuarterNote: selStartTime + (quarterDelta*ticksPerQuarterNote))
				- selStartTime.
	indexInTrack to: track size do:
		[:i | (track at: i) adjustTimeBy: delta].

]

{ #category : #initialization }
MIDIScore >> initialize [

	super initialize.
	tracks := #().
	ambientTrack := Array new.
	tempoMap := #().
	ticksPerQuarterNote := 100.

]

{ #category : #editing }
MIDIScore >> insertEvents: events at: selection [

	| track selStartTime delta |
	track := tracks at: selection first.
	selection second = 0
		ifTrue: [selStartTime := 0.
				selection at: 2 put: 1]
		ifFalse: [selStartTime := (track at: selection second) time].
	track := track copyReplaceFrom: selection second to: selection second - 1
				with: (events collect: [:e | e copy]).
	track size >=  (selection second + events size) ifTrue:
		["Adjust times of following events"
		delta := selStartTime - (track at: selection second) time.
		selection second to: selection second + events size - 1 do:
			[:i | (track at: i) adjustTimeBy: delta].
		delta := (self gridToNextQuarterNote: (track at: selection second + events size - 1) endTime)
					- (track at: selection second + events size) time.
		selection second + events size to: track size do:
			[:i | (track at: i) adjustTimeBy: delta].
		].
	tracks at: selection first put: track
]

{ #category : #editing }
MIDIScore >> jitterStartAndEndTimesBy: mSecs [

	| r range halfRange |
	r := Random new.
	range := 2.0 * mSecs.
	halfRange := mSecs.
	tracks do: [:t |
		t do: [:e | | newEnd newStart oldEnd |
			e isNoteEvent ifTrue: [
				oldEnd := e time + e duration.
				newEnd := oldEnd + ((r next * range) asInteger - halfRange).
				newStart := e time + ((r next * range) asInteger - halfRange).
				e time: newStart.
				e duration: (newEnd - newStart)]]].

				
]

{ #category : #playing }
MIDIScore >> pauseFrom: scorePlayer [
	self eventMorphsDo: [:p | p pauseFrom: scorePlayer]
]

{ #category : #'ambient track' }
MIDIScore >> removeAmbientEventWithMorph: aMorph [
	| i |
	i := ambientTrack findFirst: [:e | e morph == aMorph].
	i = 0 ifTrue: [^ self].
	ambientTrack := ambientTrack copyReplaceFrom: i to: i with: Array new
]

{ #category : #playing }
MIDIScore >> resetFrom: scorePlayer [
	self eventMorphsDo: [:p | p resetFrom: scorePlayer]
]

{ #category : #playing }
MIDIScore >> resumeFrom: scorePlayer [
	self eventMorphsDo: [:p | p resumeFrom: scorePlayer]
]

{ #category : #accessing }
MIDIScore >> tempoMap [

	^ tempoMap

]

{ #category : #accessing }
MIDIScore >> tempoMap: tempoEventList [

	tempoEventList ifNil: [
		tempoMap := #().
		^ self].
	tempoMap := tempoEventList asArray.

]

{ #category : #accessing }
MIDIScore >> ticksPerQuarterNote [

	^ ticksPerQuarterNote

]

{ #category : #accessing }
MIDIScore >> ticksPerQuarterNote: anInteger [

	ticksPerQuarterNote := anInteger.

]

{ #category : #accessing }
MIDIScore >> trackInfo [

	^ trackInfo ifNil: [tracks collect: [:i | String new]]

]

{ #category : #accessing }
MIDIScore >> trackInfo: trackInfoList [

	trackInfo := trackInfoList asArray.

]

{ #category : #accessing }
MIDIScore >> tracks [

	^ tracks

]

{ #category : #accessing }
MIDIScore >> tracks: trackList [

	tracks := trackList asArray collect: [:trackEvents | trackEvents asArray].
	self ambientTrack.  "Assure it's not nil"
]
