"
This is a real-time player for MIDI scores (i.e., scores read from MIDI files). Score can be played using either the internal sound synthesis or an external MIDI synthesizer on platforms that support MIDI output.

"
Class {
	#name : #ScorePlayer,
	#superclass : #ProtoObject,
	#instVars : [
		'score',
		'instruments',
		'overallVolume',
		'leftVols',
		'rightVols',
		'muted',
		'rate',
		'tempo',
		'secsPerTick',
		'done',
		'repeat',
		'ticksSinceStart',
		'ticksClockIncr',
		'trackEventIndex',
		'tempoMapIndex',
		'activeSounds',
		'activeMIDINotes',
		'midiPort',
		'midiPlayerProcess',
		'durationInTicks'
	],
	#category : #SoundScores
}

{ #category : #'instance creation' }
ScorePlayer class >> onScore: aMIDIScore [

	^ self new onScore: aMIDIScore

]

{ #category : #volume }
ScorePlayer >> adjustVolumeTo: vol overMSecs: mSecs [
	| normalizedVolume incr block |
	normalizedVolume := (vol asFloat min: 1.0) max: 0.0.
	incr := (self overallVolume - normalizedVolume) / mSecs * 50.0.
	block := normalizedVolume > 0.0
		ifTrue: [
			[[(normalizedVolume - self overallVolume) abs > 0.01] whileTrue: [self overallVolume: self overallVolume - incr. (Delay forMilliseconds: 50) wait]]]
		ifFalse: [
			[[self overallVolume > 0.0] whileTrue: [self overallVolume: self overallVolume - incr. (Delay forMilliseconds: 50) wait]. self pause]].
	block fork

]

{ #category : #'midi output' }
ScorePlayer >> closeMIDIPort [
	"Stop using MIDI for output. Music will be played using the built-in sound synthesis."

	self pause.
	midiPort := nil.

]

{ #category : #copying }
ScorePlayer >> copySounds [
	"Private! Support for copying."

	instruments := instruments copy.
	leftVols := leftVols copy.
	rightVols := rightVols copy.
	muted := muted copy.
	self reset.

]

{ #category : #operating }
ScorePlayer >> disableReverb: aBoolean [

	aBoolean
		ifTrue: [SoundPlayer stopReverb]
		ifFalse: [SoundPlayer startReverb].

]

{ #category : #'sound generation' }
ScorePlayer >> doControl [

	super doControl.
	1 to: activeSounds size do: [:i | (activeSounds at: i) first doControl].
	ticksSinceStart := ticksSinceStart + ticksClockIncr.
	self processAllAtTick: ticksSinceStart asInteger.

]

{ #category : #accessing }
ScorePlayer >> duration [
	"Answer the duration in seconds of my MIDI score when played at the current rate. Take tempo changes into account."

	| totalSecs currentTempo lastTempoChangeTick |
	totalSecs := 0.0.
	currentTempo := 120.0.  "quarter notes per minute"
	lastTempoChangeTick := 0.
	score tempoMap ifNotNil: [
		score tempoMap do: [:tempoEvt |
			"accumulate time up to this tempo change event"
			secsPerTick := 60.0 / (currentTempo * rate * score ticksPerQuarterNote).
			totalSecs := totalSecs + (secsPerTick * (tempoEvt time - lastTempoChangeTick)).

			"set the new tempo"
			currentTempo := (120.0 * (500000.0 / tempoEvt tempo)) roundTo: 0.01.
			lastTempoChangeTick := tempoEvt time]].

	"add remaining time through end of score"
	secsPerTick := 60.0 / (currentTempo * rate * score ticksPerQuarterNote).
	totalSecs := totalSecs + (secsPerTick * (score durationInTicks - lastTempoChangeTick)).
	^ totalSecs

]

{ #category : #accessing }
ScorePlayer >> durationInTicks [

	durationInTicks == nil ifTrue: [^ 1000].
	^ durationInTicks
]

{ #category : #accessing }
ScorePlayer >> infoForTrack: i [
	"Return the info string for the given track."
	"Note: MIDI files follow varying conventions on their use of comment strings. Often, the first string in the track suggests the role of that track in the score, such as 'flute 1' or 'soprano'."

	^ score trackInfo at: i

]

{ #category : #initialization }
ScorePlayer >> initialize [

	super initialize.
	score := MIDIScore new initialize.
	instruments := Array new.
	overallVolume := 0.5.
	leftVols := Array new.
	rightVols := Array new.
	muted := Array new.
	rate := 1.0.
	repeat := false.
	durationInTicks := 100.
]

{ #category : #accessing }
ScorePlayer >> instrumentForTrack: trackIndex [

	^ instruments at: trackIndex

]

{ #category : #accessing }
ScorePlayer >> instrumentForTrack: trackIndex put: aSoundProto [

	trackIndex > instruments size ifTrue: [^ self].
	instruments at: trackIndex put: aSoundProto.

]

{ #category : #'sound generation' }
ScorePlayer >> isDone [

	| track |
	activeSounds size > 0 ifTrue: [^ false].
	activeMIDINotes size > 0 ifTrue: [^ false].
	1 to: score tracks size do: [:i |
		track := score tracks at: i.
		(trackEventIndex at: i) <= track size ifTrue: [^ false]].
	(trackEventIndex last) <= score ambientTrack size ifTrue: [^ false].
	^ true

]

{ #category : #'sound generation' }
ScorePlayer >> isPlaying [
	^ SoundPlayer isPlaying: self
]

{ #category : #accessing }
ScorePlayer >> isStereo [

	^ true

]

{ #category : #'sound generation' }
ScorePlayer >> jumpToTick: startTick [


	self reset.
	self processTempoMapAtTick: startTick.
	self skipNoteEventsThruTick: startTick.
	self skipAmbientEventsThruTick: startTick.
	ticksSinceStart := startTick.

]

{ #category : #'midi output' }
ScorePlayer >> midiPlayLoop [

	| mSecsPerStep tStart mSecs |
	mSecsPerStep := 5.
	[done] whileFalse: [
		tStart := Time millisecondClockValue.
		self processAllAtTick: ticksSinceStart asInteger.
		(Delay forMilliseconds: mSecsPerStep) wait.
		mSecs := Time millisecondClockValue - tStart.
		mSecs < 0 ifTrue: [mSecs := mSecsPerStep].  "clock wrap"
		ticksSinceStart := ticksSinceStart + (mSecs asFloat / (1000.0 * secsPerTick))].

]

{ #category : #accessing }
ScorePlayer >> midiPort [

	^ midiPort

]

{ #category : #accessing }
ScorePlayer >> millisecondsSinceStart [
	"Answer the approximate number of milliseconds of real time since the beginning of the score. Since this calculation uses the current tempo, which can change throughout the piece, it is safer to use ticksSinceStart for synchronization."

	^ (secsPerTick * ticksSinceStart * 1000) asInteger

]

{ #category : #'sound generation' }
ScorePlayer >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Play a number of sounds concurrently. The level of each sound can be set independently for the left and right channels."

	| myLeftVol myRightVol someSoundIsDone pair snd trk left right |
	myLeftVol := (leftVol * overallVolume) asInteger.
	myRightVol := (rightVol * overallVolume) asInteger.
	someSoundIsDone := false.
	1 to: activeSounds size do: [:i |
		pair := activeSounds at: i.
		snd := pair at: 1.
		trk := pair at: 2.
		left := (myLeftVol * (leftVols at: trk)).
		right := (myRightVol * (rightVols at: trk)).
		snd samplesRemaining > 0
			ifTrue: [
				snd mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: left rightVol: right]
			ifFalse: [someSoundIsDone := true]].

	someSoundIsDone ifTrue: [
		activeSounds := activeSounds select: [:p | p first samplesRemaining > 0]].

]

{ #category : #accessing }
ScorePlayer >> mutedForTrack: trackIndex [

	^ muted at: trackIndex

]

{ #category : #accessing }
ScorePlayer >> mutedForTrack: trackIndex put: aBoolean [

	trackIndex > muted size ifTrue: [^ self].
	muted at: trackIndex put: aBoolean.
	aBoolean ifFalse: [^ self].

	"silence any currently sounding notes for this track"
	activeSounds do: [:pair |
		pair last = trackIndex ifTrue: [activeSounds remove: pair ifAbsent: []]].
	midiPort ifNotNil: [
		activeMIDINotes do: [:pair |
			pair last = trackIndex ifTrue: [
				pair first endNoteOnMidiPort: midiPort.
				activeMIDINotes remove: pair ifAbsent: []]]].

]

{ #category : #accessing }
ScorePlayer >> mutedState [

	^ muted

]

{ #category : #initialization }
ScorePlayer >> onScore: aMIDIScore [

	| trackCount totalVol incr curr pan |
	score := aMIDIScore.
	trackCount := score tracks size.
	durationInTicks := score durationInTicks.
	instruments := (1 to: trackCount) collect: [:i | FMSound oboe1].
	leftVols := Array new: trackCount.
	rightVols := Array new: trackCount.
	muted  := Array new: trackCount withAll: false.
	rate := 1.0.
	repeat := false.
	tempo := 120.0.

	trackCount = 0 ifTrue: [^ self].
	1 to: trackCount do: [:i |
		leftVols at: i put: 1 // 4.
		rightVols at: i put: 1 // 4].

	"distribute inital panning of tracks left-to-right"
	totalVol := 1.0.
	incr := totalVol / (((trackCount // 2) + 1) * 2).
	curr := 0.
	1 to: trackCount do: [:t |
		t even
			ifTrue: [pan := curr]
			ifFalse: [
				curr := curr + incr.
				pan := totalVol - curr].
		self panForTrack: t put: pan].


]

{ #category : #'midi output' }
ScorePlayer >> openMIDIPort: portNum [
	"Open the given MIDI port. Music will be played as MIDI commands to the given MIDI port."

	midiPort := SimpleMIDIPort openOnPortNumber: portNum.

]

{ #category : #accessing }
ScorePlayer >> overallVolume [

	^ overallVolume

]

{ #category : #accessing }
ScorePlayer >> overallVolume: aNumber [
	"Set the overally playback volume to a value between 0.0 (off) and 1.0 (full blast)."

	overallVolume := (aNumber asFloat min: 1.0) max: 0.0.


]

{ #category : #accessing }
ScorePlayer >> panForTrack: i [

	| left right fullVol pan |
	left := leftVols at: i.
	right := rightVols at: i.
	left = right ifTrue: [^ 0.5].  "centered"
	fullVol := left max: right.
	left < fullVol
		ifTrue: [pan := left asFloat / (2.0 * fullVol)]
		ifFalse: [pan := 1.0 - (right asFloat / (2.0 * fullVol))].
	^ pan roundTo: 0.001


]

{ #category : #accessing }
ScorePlayer >> panForTrack: trackIndex put: aNumber [
	"Set the left-right pan for this track to a value in the range [0.0..1.0], where 0.0 means full-left."

	| fullVol pan left right |
	trackIndex > leftVols size ifTrue: [^ self].
	fullVol := (leftVols at: trackIndex) max: (rightVols at: trackIndex).
	pan := (aNumber asFloat min: 1.0) max: 0.0.
	pan <= 0.5
		ifTrue: [  "attenuate right channel"
			left := fullVol.
			right := 2.0 * pan * fullVol]
		ifFalse: [  "attenuate left channel"
			left := 2.0 * (1.0 - pan) * fullVol.
			right := fullVol].
	rightVols at: trackIndex put: right asInteger.
	leftVols at: trackIndex put: left asInteger.

]

{ #category : #operating }
ScorePlayer >> pause [
	"Pause this sound. It can be resumed from this point, or reset and resumed to start from the beginning."

	score pauseFrom: self.
	super pause.
	activeSounds := activeSounds species new.
	midiPort ifNotNil: [self stopMIDIPlaying].

]

{ #category : #accessing }
ScorePlayer >> positionInScore [

	^ self ticksSinceStart asFloat / (self durationInTicks max: 1)
]

{ #category : #accessing }
ScorePlayer >> positionInScore: pos [

	self isPlaying ifTrue: [^ self "ignore rude intrusion"].
	ticksSinceStart := pos * durationInTicks.
	done := false.


]

{ #category : #copying }
ScorePlayer >> postCopy [
	"Copy my component sounds."

	super postCopy.
	self copySounds

]

{ #category : #'sound generation' }
ScorePlayer >> processAllAtTick: scoreTick [

	self processTempoMapAtTick: scoreTick.
	midiPort
		ifNil: [self processNoteEventsAtTick: scoreTick]
		ifNotNil: [self processMIDIEventsAtTick: scoreTick].
	self processAmbientEventsAtTick: scoreTick.
	self isDone ifTrue: [
		repeat
			ifTrue: [self reset]
			ifFalse: [done := true]].

]

{ #category : #'sound generation' }
ScorePlayer >> processAmbientEventsAtTick: scoreTick [
	"Process ambient events through the given tick."

	| i evt |
	i := trackEventIndex at: trackEventIndex size.
	[evt := score ambientEventAfter: i ticks: scoreTick.
	 evt ~~ nil] whileTrue: [
		i := i + 1.
		evt occurAtTime: scoreTick inScorePlayer: self atIndex: i inEventTrack: score ambientTrack secsPerTick: secsPerTick].
	trackEventIndex at: trackEventIndex size put: i.

]

{ #category : #'midi output' }
ScorePlayer >> processMIDIEventsAtTick: scoreTick [
	"Process note events through the given score tick using MIDI."

	| j evt |
	1 to: score tracks size do: [:i |
		j := trackEventIndex at: i.
		[evt := score eventForTrack: i after: j ticks: scoreTick.
		 evt ~~ nil] whileTrue: [
			evt isNoteEvent
				ifTrue: [
					(muted at: i) ifFalse: [
						evt startNoteOnMidiPort: midiPort.
						activeMIDINotes add: (Array with: evt with: i)]]
				ifFalse: [evt outputOnMidiPort: midiPort].
			j := j + 1.
			trackEventIndex at: i put: j]].
	self turnOffActiveMIDINotesAt: scoreTick.

]

{ #category : #'sound generation' }
ScorePlayer >> processNoteEventsAtTick: scoreTick [
	"Process note events through the given score tick using internal Squeak sound synthesis."

	| instr j evt snd |
	1 to: score tracks size do: [:i |
		instr := instruments at: i.
		j := trackEventIndex at: i.
		[evt := score eventForTrack: i after: j ticks: scoreTick.
		 evt ~~ nil] whileTrue: [
			(evt isNoteEvent and: [(muted at: i) not]) ifTrue: [
				snd := instr
					soundForMidiKey: evt midiKey
					dur: secsPerTick * evt duration
					loudness: evt velocity asFloat / 127.0.
				activeSounds add: (Array with: snd with: i)].
			j := j + 1.
			trackEventIndex at: i put: j]].

]

{ #category : #'sound generation' }
ScorePlayer >> processTempoMapAtTick: scoreTick [
	"Process tempo changes through the given score tick."

	| map tempoChanged |
	map := score tempoMap.
	map ifNil: [^ self].
	tempoChanged := false.
	[(tempoMapIndex <= map size) and:
	 [(map at: tempoMapIndex) time <= scoreTick]] whileTrue: [
		tempoChanged := true.
		tempoMapIndex := tempoMapIndex + 1].

	tempoChanged ifTrue: [
		tempo := (120.0 * (500000.0 / (map at: tempoMapIndex - 1) tempo)) roundTo: 0.01.
		self tempoOrRateChanged].


]

{ #category : #accessing }
ScorePlayer >> rate [

	^ rate

]

{ #category : #accessing }
ScorePlayer >> rate: aNumber [
	"Set the playback rate. For example, a rate of 2.0 will playback at twice normal speed."

	rate := aNumber asFloat.
	self tempoOrRateChanged.

]

{ #category : #accessing }
ScorePlayer >> repeat [
	"Return true if this player will repeat when it gets to the end of the score, false otherwise."

	^ repeat

]

{ #category : #accessing }
ScorePlayer >> repeat: aBoolean [
	"Turn repeat mode on or off."

	repeat := aBoolean.

]

{ #category : #'sound generation' }
ScorePlayer >> reset [

	super reset.
	tempo := 120.0.
	self tempoOrRateChanged.
	done := false.
	ticksSinceStart := 0.
	"one index for each sound track, plus one for the ambient track..."
	trackEventIndex := Array new: score tracks size+1 withAll: 1.
	tempoMapIndex := 1.
	activeSounds := OrderedCollection new.
	activeMIDINotes := OrderedCollection new.
	score resetFrom: self.
	overallVolume ifNil: [overallVolume := 0.5].

]

{ #category : #operating }
ScorePlayer >> resumePlaying [
	"Resume playing. Start over if done."

	done ifTrue: [self reset].
	self jumpToTick: ticksSinceStart.  "Play up to here in case we got scrolled to new position."
	score resumeFrom: self.
	midiPort
		ifNil: [super resumePlaying]  "let the sound player drive sound generation" 
		ifNotNil: [self startMIDIPlaying].  "start a process to drive MIDI output"

]

{ #category : #'sound generation' }
ScorePlayer >> samplesRemaining [

	done
		ifTrue: [^ 0]
		ifFalse: [^ 1000000].

]

{ #category : #accessing }
ScorePlayer >> score [

	^ score

]

{ #category : #accessing }
ScorePlayer >> secsPerTick [

	^ secsPerTick
]

{ #category : #accessing }
ScorePlayer >> settingsString [

	| s |
	s := WriteStream on: (String new: 1000).
	s nextPutAll: 'player'; cr.
	s tab; nextPutAll: 'rate: ', self rate printString, ';'; cr.
	s tab; nextPutAll: 'overallVolume: ', self overallVolume printString, ';'; cr.
	1 to: self trackCount do: [:t |
		s tab; nextPutAll: 'instrumentForTrack: ', t printString,
			' put: (AbstractSound soundNamed: #default);'; cr.
		s tab; nextPutAll: 'mutedForTrack: ', t printString,
			' put: ', (self mutedForTrack: t) printString, ';'; cr.
		s tab; nextPutAll: 'volumeForTrack: ', t printString,
			' put: ', (self volumeForTrack: t) printString, ';'; cr.
		s tab; nextPutAll: 'panForTrack: ', t printString,
			' put: ', (self panForTrack: t) printString, ';'; cr].
	s tab; nextPutAll: 'repeat: ', self repeat printString, '.'; cr.
	^ s contents

]

{ #category : #'sound generation' }
ScorePlayer >> skipAmbientEventsThruTick: startTick [
	"Skip ambient events through the given score tick."

	score ambientTrack withIndexDo:
		[:evt :i | evt time > startTick ifTrue:
			[^ trackEventIndex at: trackEventIndex size put: i]].

]

{ #category : #'sound generation' }
ScorePlayer >> skipNoteEventsThruTick: startTick [
	"Skip note events through the given score tick using internal Squeak sound synthesis."

	| j evt |
	1 to: score tracks size do: [:i |
		j := trackEventIndex at: i.
		[evt := score eventForTrack: i after: j ticks: startTick.
		 evt == nil] whileFalse: [
			evt isNoteEvent
				ifTrue: [
					(((evt time + evt duration) > startTick) and: [(muted at: i) not]) ifTrue: [
						self startNote: evt forStartTick: startTick trackIndex: i]]
				ifFalse: [
					midiPort == nil ifFalse: [evt outputOnMidiPort: midiPort]].
			j := j + 1].
		trackEventIndex at: i put: j].

]

{ #category : #'midi output' }
ScorePlayer >> startMIDIPlaying [
	"Start up a process to play this score via MIDI."

	midiPort ensureOpen.
	midiPlayerProcess ifNotNil: [midiPlayerProcess terminate].
	midiPlayerProcess := [self midiPlayLoop] newProcess.
	midiPlayerProcess
		priority: Processor userInterruptPriority;
		resume.

]

{ #category : #'sound generation' }
ScorePlayer >> startNote: noteEvent forStartTick: startTick trackIndex: trackIndex [
	"Prepare a note to begin playing at the given tick. Used to start playing at an arbitrary point in the score. Handle both MIDI and built-in synthesis cases."

	| snd |
	midiPort
		ifNil: [
			snd := (instruments at: trackIndex)
				soundForMidiKey: noteEvent midiKey
				dur: secsPerTick * (noteEvent endTime - startTick)
				loudness: noteEvent velocity asFloat / 127.0.
			activeSounds add: (Array with: snd with: trackIndex)]
		ifNotNil: [
			noteEvent startNoteOnMidiPort: midiPort.
			activeMIDINotes add: (Array with: noteEvent with: trackIndex)].

]

{ #category : #'midi output' }
ScorePlayer >> stopMIDIPlaying [
	"Terminate the MIDI player process and turn off any active notes."

	midiPlayerProcess ifNotNil: [midiPlayerProcess terminate].
	midiPlayerProcess := nil.
	activeMIDINotes do: [:pair | pair first endNoteOnMidiPort: midiPort].
	activeMIDINotes := activeMIDINotes species new.

]

{ #category : #accessing }
ScorePlayer >> tempo [
	"Return the current tempo in beats (quarter notes) per minute. The tempo at any given moment is defined by the score and cannot be changed by the client. To change the playback speed, the client may change the rate parameter."

	^ tempo

]

{ #category : #operating }
ScorePlayer >> tempoOrRateChanged [
	"This method should be called after changing the tempo or rate."

	secsPerTick := 60.0 / (tempo * rate * score ticksPerQuarterNote).
	ticksClockIncr := (1.0 / self controlRate) / secsPerTick.

]

{ #category : #accessing }
ScorePlayer >> ticksForMSecs: mSecs [

	^ (mSecs asFloat / (1000.0 * secsPerTick)) rounded

]

{ #category : #accessing }
ScorePlayer >> ticksSinceStart [
	"Answer the number of score ticks that have elapsed since this piece started playing. The duration of a tick is determined by the MIDI score."

	^ ticksSinceStart

]

{ #category : #accessing }
ScorePlayer >> ticksSinceStart: newTicks [
	"Adjust ticks to folow, eg, piano roll autoscrolling"

	self isPlaying ifFalse: [ticksSinceStart := newTicks]

]

{ #category : #accessing }
ScorePlayer >> trackCount [

	^ score tracks size

]

{ #category : #'midi output' }
ScorePlayer >> turnOffActiveMIDINotesAt: scoreTick [
	"Turn off any active MIDI notes that should be turned off at the given score tick."

	| someNoteEnded |
	midiPort ifNil: [^ self].
	someNoteEnded := false. 
	activeMIDINotes do: [:pair | | evt |
		evt := pair first.
		evt endTime <= scoreTick ifTrue: [
			evt endNoteOnMidiPort: midiPort.
			someNoteEnded := true]].

	someNoteEnded ifTrue: [
		activeMIDINotes := activeMIDINotes select: [:p | p first endTime > scoreTick]].

]

{ #category : #initialization }
ScorePlayer >> updateDuration [

	durationInTicks := score durationInTicks.

]

{ #category : #accessing }
ScorePlayer >> volumeForTrack: i [

	| vol |
	vol := (leftVols at: i) max: (rightVols at: i).
	^ (vol asFloat) roundTo: 0.0001

]

{ #category : #accessing }
ScorePlayer >> volumeForTrack: trackIndex put: aNumber [

	| newVol oldLeft oldRight oldFullVol left right |
	trackIndex > leftVols size ifTrue: [^ self].
	newVol := ((aNumber asFloat max: 0.0) min: 1.0) *  32768 "ScaleFactor".
	oldLeft := leftVols at: trackIndex.
	oldRight := rightVols at: trackIndex.
	oldFullVol := oldLeft max: oldRight.
	oldFullVol = 0 ifTrue: [oldFullVol := 1.0].
	oldLeft < oldFullVol
		ifTrue: [
			left := newVol * oldLeft / oldFullVol.
			right := newVol]
		ifFalse: [
			left := newVol.
			right := newVol * oldRight / oldFullVol].
	leftVols at: trackIndex put: left asInteger.
	rightVols at: trackIndex put: right asInteger.

]
