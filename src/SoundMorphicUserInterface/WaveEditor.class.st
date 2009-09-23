"
This tool was created to aid in the preparation of LoopedSampledSound objects. It includes support for finding good loop points with a little help from the user.  Namely, the user must identify a good ending point for the loop (typically just before the decay phase begins) and identify one cycle of the waveform. After that, the  ""choose loop point"" menu command can be invoked to search backwards to find and rank all possible loop starting points. Some experimentation is usually required to find a loop that ""breaths"" in a natural way.

This tool can also be used as a general viewer of numerical sequences of any kind, such as time-varying functions, FFT data, etc.
"
Class {
	#name : #WaveEditor,
	#superclass : #AlignmentMorph,
	#instVars : [
		'graph',
		'samplingRate',
		'perceivedFrequency',
		'loopEnd',
		'loopLength',
		'loopCycles',
		'possibleLoopStarts',
		'keyboard'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #'parts bin' }
WaveEditor class >> descriptionForPartsBin [
	^ self partName:	'WaveEditor'
		categories:		#('Multimedia')
		documentation:	'A workbench for seing and editing wave forms'
]

{ #category : #'instance creation' }
WaveEditor class >> openOn: dataCollection [
	"Open a new WaveEditor on the given sequencable collection of data."

	^ (self new data: dataCollection) openInWorld

]

{ #category : #initialization }
WaveEditor >> addControls [

	| slider bb r m |
	r := AlignmentMorph newRow.
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r color: bb color; borderWidth: 0; layoutInset: 0.
	r hResizing: #shrinkWrap; vResizing: #shrinkWrap; extent: 5@5.
	r wrapCentering: #topLeft.
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'X';					actionSelector: #delete).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: '<>'; actWhen: #buttonDown;
															actionSelector: #invokeMenu).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Play' translated;				actionSelector: #play).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Play Before' translated;		actionSelector: #playBeforeCursor).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Play After' translated;			actionSelector: #playAfterCursor).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Play Loop' translated;			actionSelector: #playLoop).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Test' translated;				actionSelector: #playTestNote).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Save' translated;				actionSelector: #saveInstrument).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Set Loop End' translated;		actionSelector: #setLoopEnd).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'One Cycle' translated;			actionSelector: #setOneCycle).
	bb := SimpleButtonMorph new target: self; borderColor: Color black.
	r addMorphBack: (bb label: 'Set Loop Start' translated;		actionSelector: #setLoopStart).
	self addMorphBack: r.

	r := AlignmentMorph newRow.
	r color: self color; borderWidth: 0; layoutInset: 0.
	r hResizing: #spaceFill; vResizing: #rigid; extent: 5@20; wrapCentering: #center; cellPositioning: #leftCenter.

	m := StringMorph new contents: 'Index: ' translated.
	r addMorphBack: m.
	m := UpdatingStringMorph new
		target: graph; getSelector: #cursor; putSelector: #cursor:;
		growable: false; width: 71; step.
	r addMorphBack: m.

	m := StringMorph new contents: 'Value: ' translated.
	r addMorphBack: m.
	m := UpdatingStringMorph new
		target: graph; getSelector: #valueAtCursor; putSelector: #valueAtCursor:;
		growable: false; width: 50; step.
	r addMorphBack: m.

	slider := SimpleSliderMorph new
		color: color;
		extent: 200@2;
		target: self;
		actionSelector: #scrollTime:.
	r addMorphBack: slider.

	m := Morph new color: r color; extent: 10@5.  "spacer"
	r addMorphBack: m.
	m := UpdatingStringMorph new
		target: graph; getSelector: #startIndex; putSelector: #startIndex:;
		width: 40; step.
	r addMorphBack: m.

	self addMorphBack: r.


]

{ #category : #initialization }
WaveEditor >> addLoopPointControls [

	| r m |
	r := AlignmentMorph newRow.
	r color: self color; borderWidth: 0; layoutInset: 0.
	r hResizing: #spaceFill; vResizing: #rigid; extent: 5@20; wrapCentering: #center; cellPositioning: #leftCenter.

	m := StringMorph new contents: 'Loop end: ' translated.
	r addMorphBack: m.
	m := UpdatingStringMorph new
		target: self; getSelector: #loopEnd; putSelector: #loopEnd:;
		growable: false; width: 50; step.
	r addMorphBack: m.

	m := StringMorph new contents: 'Loop length: ' translated.
	r addMorphBack: m.
	m := UpdatingStringMorph new
		target: self; getSelector: #loopLength; putSelector: #loopLength:;
		floatPrecision: 0.001;
		growable: false; width: 50; step.
	r addMorphBack: m.

	m := StringMorph new contents: 'Loop cycles: ' translated.
	r addMorphBack: m.
	m := UpdatingStringMorph new
		target: self; getSelector: #loopCycles; putSelector: #loopCycles:;
		floatPrecision: 0.001;
		growable: false; width: 50; step.
	r addMorphBack: m.

	m := StringMorph new contents: 'Frequency: ' translated.
	r addMorphBack: m.
	m := UpdatingStringMorph new
		target: self; getSelector: #perceivedFrequency; putSelector: #perceivedFrequency:;
		floatPrecision: 0.001;
		growable: false; width: 50; step.
	r addMorphBack: m.

	self addMorphBack: r.

]

{ #category : #other }
WaveEditor >> autoCorrolationBetween: index1 and: index2 length: length [
	"Answer the cummulative error between the portions of my waveform starting at the given two indices and extending for the given length. The larger this error, the greater the difference between the two waveforms."

	| data error i1 e |
	data := graph data.
	error := 0.
	i1 := index1.
	index2 to: (index2 + length - 1) do: [:i2 |
		e := (data at: i1) - (data at: i2).
		e < 0 ifTrue: [e := 0 - e].
		error := error + e.
		i1 := i1 + 1].
	^ error

]

{ #category : #menu }
WaveEditor >> chooseLoopStart [ 

	| bestLoops menu secs choice start |
	possibleLoopStarts ifNil: [
		UIManager default
			informUser: 'Finding possible loop points...' translated
			during: [possibleLoopStarts := self findPossibleLoopStartsFrom: graph cursor]].
	bestLoops := possibleLoopStarts copyFrom: 1 to: (100 min: possibleLoopStarts size).
	menu := CustomMenu new.
	bestLoops do: [:entry |
		secs := ((loopEnd - entry first) asFloat / self samplingRate) roundTo: 0.01.
		menu add: ('{1} ', 'cycles' translated, '; {2} secs' translated format:{entry third. secs}) action: entry].
	choice := menu startUp.
	choice ifNil: [^ self].
	loopCycles := choice third.
	start := self fractionalLoopStartAt: choice first.
	self loopLength: (loopEnd asFloat - start) + 1.0.

]

{ #category : #accessing }
WaveEditor >> data: newData [

	graph data: newData.

]

{ #category : #initialization }
WaveEditor >> defaultBorderWidth [
"answer the default border width for the receiver"
	^ 2
]

{ #category : #initialization }
WaveEditor >> defaultColor [
"answer the default color/fill style for the receiver"
	^ Color lightGray
]

{ #category : #other }
WaveEditor >> errorBetween: sampleArray1 and: sampleArray2 [
	"Answer the cummulative error between the two sample arrays, which are assumed to be the same size."

	| error e |
	error := 0.
	1 to: sampleArray1 size do: [:i |
		e := (sampleArray1 at: i) - (sampleArray2 at: i).
		e < 0 ifTrue: [e := 0 - e].
		error := error + e].
	^ error

]

{ #category : #other }
WaveEditor >> findPossibleLoopStartsFrom: index [ 
	"Assume loopEnd is one sample before a zero-crossing."

	| r postLoopCycleStart i postLoopCycleLength cycleLength cycleCount err oldI |
	r := OrderedCollection new.

	"Record the start and length of the first cycle after the loop endpoint."
	postLoopCycleStart := loopEnd + 1.	"Assumed to be a zero-crossing."
	i := self zeroCrossingAfter: postLoopCycleStart 
						+ (0.9 * samplingRate / perceivedFrequency) asInteger.
	postLoopCycleLength := i - loopEnd - 1.

	"Step backwards one cycle at a time, using zero-crossings to find the
	 beginning of each cycle, and record the auto-corrolation error between
	 each cycle and the cycle following the loop endpoint. Assume pitch may shift gradually."
	i := self zeroCrossingAfter: postLoopCycleStart 
						- (1.1 * postLoopCycleLength) asInteger.
	cycleLength := postLoopCycleStart - i.
	cycleCount := 1.
	[cycleLength > 0] whileTrue: 
			[err := self 
						autoCorrolationBetween: i
						and: postLoopCycleStart
						length: postLoopCycleLength.
			r add: (Array 
						with: i
						with: err
						with: cycleCount
						with: ((loopEnd - i) asFloat / self samplingRate roundTo: 0.01)).
			oldI := i.
			i := self zeroCrossingAfter: oldI - (1.1 * cycleLength) asInteger.
			cycleLength := oldI - i.	"will be zero when start of data is encountered"
			cycleCount := cycleCount + 1].
	r := r asSortedCollection: [:e1 :e2 | (e1 second) < (e2 second)].
	^r asArray
]

{ #category : #other }
WaveEditor >> fractionalLoopStartAt: index [
	"Answer the fractional index starting point near the given integral index that results in the closest match with the cycle following the loop end."
	"Note: could do this more efficiently by sliding downhill on the error curve to find lowest error."

	| oneCycle w1 minErr w2 err bestIndex |
	oneCycle := (samplingRate / perceivedFrequency) rounded.
	w1 := self interpolatedWindowAt: loopEnd + 1 width: oneCycle.
	minErr := SmallInteger maxVal.
	((index - 2) max: 1) to: ((index + 2) min: graph data size) by: 0.01 do: [:i |
		w2 := self interpolatedWindowAt: i width: oneCycle.
		err := self errorBetween: w1 and: w2.
		err < minErr ifTrue: [
			bestIndex := i.
			minErr := err]].
	^ bestIndex

]

{ #category : #accessing }
WaveEditor >> graph [

	^ graph

]

{ #category : #initialization }
WaveEditor >> initialize [
	"initialize the state of the receiver"
	super initialize.
	""
	samplingRate := SoundPlayer samplingRate.
	loopEnd := loopLength := 0.
	loopCycles := 1.
	perceivedFrequency := 0.
	"zero means unknown"
	self extent: 5 @ 5;
		 listDirection: #topToBottom;
		 wrapCentering: #topLeft;
		 hResizing: #shrinkWrap;
		 vResizing: #shrinkWrap;
		 layoutInset: 3.
	graph := GraphMorph new extent: 450 @ 100.

	graph cursor: 0.
	graph cursorColorAtZeroCrossings: Color blue.
	self addControls.
	self addLoopPointControls.
	self addMorphBack: graph.
	self
		addMorphBack: (Morph
				newBounds: (0 @ 0 extent: 0 @ 3)
				color: Color transparent).
	self addMorphBack: (keyboard := PianoKeyboardMorph new).
	self sound: (SampledSound soundNamed: 'croak').

]

{ #category : #other }
WaveEditor >> interpolatedWindowAt: index width: nSamples [
	"Return an array of N samples starting at the given index in my data."

	| scale data baseIndex scaledFrac scaledOneMinusFrac prevSample nextSample v |
	scale := 10000.
	data := graph data.
	index isInteger
		ifTrue: [^ (index to: index + nSamples - 1) collect: [:i | data at: i]].
	baseIndex := index truncated.
	scaledFrac := ((index asFloat - baseIndex) * scale) truncated.
	scaledOneMinusFrac := scale - scaledFrac.
	prevSample := data at: baseIndex.
	^ (baseIndex + 1 to: baseIndex + nSamples) collect: [:i |
		nextSample := data at: i.
		v := ((nextSample * scaledFrac) + (prevSample * scaledOneMinusFrac)) // scale.
		prevSample := nextSample.
		v].

]

{ #category : #menu }
WaveEditor >> invokeMenu [
	"Invoke a menu of additonal functions for this WaveEditor."

	| aMenu |
	aMenu := CustomMenu new.
	aMenu addList:	{
		{'play straight through' translated.	#play}.
		{'play before cursor' translated.	#playBeforeCursor}.
		{'play after cursor' translated.		#playAfterCursor}.
		{'play test note' translated.			#playTestNote}.
		{'play loop' translated.				#playLoop}.
		{'trim before cursor' translated.	#trimBeforeCursor}.
		{'trim after cursor' translated.		#trimAfterCursor}.
		{'choose loop start' translated.		#chooseLoopStart}.
		{'jump to loop start' translated.		#jumpToLoopStart}.
		{'jump to loop end' translated.		#jumpToLoopEnd}.
		{'make unlooped' translated.		#setUnlooped}.
		{'make unpitched' translated.		#setUnpitched}.
		{'show envelope' translated.		#showEnvelope}.
		{'show FFT' translated.				#showFFTAtCursor}}.
	aMenu invokeOn: self defaultSelection: nil.

]

{ #category : #menu }
WaveEditor >> jumpToLoopEnd [

	graph cursor: loopEnd; centerCursor.

]

{ #category : #menu }
WaveEditor >> jumpToLoopStart [

	graph cursor: (loopEnd - loopLength) truncated; centerCursor.

]

{ #category : #accessing }
WaveEditor >> loopCycles [

	^ loopCycles

]

{ #category : #accessing }
WaveEditor >> loopCycles: aNumber [

	loopCycles := aNumber.
	self loopLength: loopLength.  "updates frequency"

]

{ #category : #accessing }
WaveEditor >> loopEnd [

	^ loopEnd

]

{ #category : #accessing }
WaveEditor >> loopEnd: aNumber [

	loopEnd := (aNumber asInteger max: 1) min: graph data size.
	possibleLoopStarts := nil.

]

{ #category : #accessing }
WaveEditor >> loopLength [

	^ loopLength

]

{ #category : #accessing }
WaveEditor >> loopLength: aNumber [

	loopLength := aNumber.
	((loopCycles > 0) and: [loopLength > 0]) ifTrue: [
		perceivedFrequency := samplingRate asFloat * loopCycles / loopLength].


]

{ #category : #accessing }
WaveEditor >> loopStart [

	^ (loopEnd - loopLength) truncated + 1

]

{ #category : #accessing }
WaveEditor >> loopStart: index [

	| start len |
	start := self fractionalLoopStartAt: index.
	len := (loopEnd asFloat - start) + 1.0.
	loopCycles := (len / (samplingRate / perceivedFrequency)) rounded.
	self loopLength: len.

]

{ #category : #menu }
WaveEditor >> makeLoopedSampledSound [
	| data end snd basePitch |
	data := graph data.
	snd := (loopEnd = 0 or: [loopLength = 0]) 
				ifTrue: 
					["save as unlooped"

					basePitch := perceivedFrequency = 0 
						ifTrue: [100.0]
						ifFalse: [perceivedFrequency].
					LoopedSampledSound new 
						unloopedSamples: data
						pitch: basePitch
						samplingRate: samplingRate]
				ifFalse: 
					[end := (loopEnd min: data size) max: 1.
					basePitch := samplingRate * loopCycles / loopLength.
					LoopedSampledSound new 
						samples: data
						loopEnd: end
						loopLength: end
						pitch: basePitch
						samplingRate: samplingRate].
	snd addReleaseEnvelope.
	^snd
]

{ #category : #other }
WaveEditor >> normalize: sampleArray [ 
	"Return a copy of the given sample array scaled to use the maximum 16-bit sample range. Remove any D.C. offset."

	| max scale out |
	max := 0.
	sampleArray do: 
			[:s | 
			max := max max: s abs].
	scale := ((1 << 15) - 1) asFloat / max.
	out := sampleArray species new: sampleArray size.
	1 to: sampleArray size
		do: [:i | out at: i put: (scale * (sampleArray at: i)) truncated].
	^out
]

{ #category : #accessing }
WaveEditor >> perceivedFrequency [

	^ perceivedFrequency


]

{ #category : #accessing }
WaveEditor >> perceivedFrequency: aNumber [

	perceivedFrequency := aNumber.
	(loopCycles > 0) ifTrue: [
		loopLength := samplingRate asFloat * loopCycles / perceivedFrequency].

]

{ #category : #menu }
WaveEditor >> play [

	graph data size < 2 ifTrue: [^ self].
	(SampledSound samples: graph data samplingRate: samplingRate) play.


]

{ #category : #menu }
WaveEditor >> playAfterCursor [

	self playFrom: graph cursor to: graph data size.

]

{ #category : #menu }
WaveEditor >> playBeforeCursor [

	self playFrom: 1 to: graph cursor.

]

{ #category : #menu }
WaveEditor >> playFrom: start to: end [

	| sz i1 i2 snd |
	sz := graph data size.
	i1 := ((start + 1) min: sz) max: 1.
	i2 := ((end + 1) min: sz) max: i1.
	(i1 + 2) >= i2 ifTrue: [^ self].
	snd := SampledSound
		samples: (graph data copyFrom: i1 to: i2)
		samplingRate: samplingRate.
	snd play.

]

{ #category : #menu }
WaveEditor >> playLoop [

	| sz i1 i2 snd len |
	sz := graph data size.
	i1 := ((loopEnd - loopLength) truncated min: sz) max: 1.
	i2 := (loopEnd min: sz) max: i1.
	len := (i2 - i1) + 1.
	len < 2 ifTrue: [^ self].

	snd := LoopedSampledSound new
		samples: (graph data copyFrom: i1 to: i2)
		loopEnd: len
		loopLength: loopLength
		pitch: 100.0
		samplingRate: samplingRate.

	"sustain for the longer of four loops or two seconds"
	snd setPitch: 100.0
		dur: (((4.0 * loopLength) / samplingRate) max: 2.0)
		loudness: 0.5.
	snd play.

]

{ #category : #menu }
WaveEditor >> playTestNote [

	| data end snd loopDur dur |
	(loopEnd = 0 or: [loopLength = 0]) ifTrue: [^ self].
	data := graph data.
	end := (loopEnd min: data size) max: 1.
	snd := LoopedSampledSound new
		samples: data loopEnd: end loopLength: loopLength
		pitch: 100.0 samplingRate: samplingRate.

	loopDur := (4.0 * loopLength / samplingRate) max: 2.0.  "longer of 4 loops or 2 seconds"
	dur := (data size / samplingRate) + loopDur.
	(snd
		addReleaseEnvelope;
		setPitch: 100.0 dur: dur loudness: 0.5) play.

]

{ #category : #accessing }
WaveEditor >> samplingRate [

	^ samplingRate


]

{ #category : #accessing }
WaveEditor >> samplingRate: samplesPerSecond [

	samplingRate := samplesPerSecond.

]

{ #category : #menu }
WaveEditor >> saveInstrument [

	| name |
	name := UIManager default request: 'Instrument name?' translated.
	name isEmptyOrNil ifTrue: [^ self].
	AbstractSound soundNamed: name put: self makeLoopedSampledSound.

]

{ #category : #other }
WaveEditor >> scrollTime: relativeValue [

	graph startIndex: relativeValue * (graph data size - (graph width // 2)).

]

{ #category : #menu }
WaveEditor >> setLoopEnd [

	graph cursor: (self zeroCrossingAfter: graph cursor) - 1.
	self loopEnd: graph cursor.


]

{ #category : #menu }
WaveEditor >> setLoopStart [
	"Assuming that the loop end and approximate frequency have been set, this method uses the current cursor position to determine the loop length and the number of cycles."

	| start len |
	start := graph cursor.
	((start >= loopEnd) or: [perceivedFrequency = 0]) ifTrue: [
		^ self inform:
'Please set the loop end and the approximate frequency
first, then position the cursor one or more cycles
before the loop end and try this again.' translated].
	len := (loopEnd - start) + 1.
	loopCycles := (len / (samplingRate / perceivedFrequency)) rounded.
	self loopLength: len.


]

{ #category : #menu }
WaveEditor >> setOneCycle [
	"Set the approximate frequency based on a single cycle specified by the user. To use this, first set the loop end, then place the cursor one full cycle before the loop end and invoke this method."

	| len |
	len := loopEnd - graph cursor.
	len > 0 ifTrue: [
		loopCycles := 1.
		self loopLength: len].

]

{ #category : #menu }
WaveEditor >> setUnlooped [
	"Make this sound play straight through without looping."

	loopLength := 0.
	loopCycles := 1.

]

{ #category : #menu }
WaveEditor >> setUnpitched [
	"Make this instrument be unpitched and unlooped. Suitable for percussive sounds that should not be pitch-shifted when played. By convention, such sounds are played at a pitch of 100.0 to obtain their original pitch."

	loopLength := 0.
	loopCycles := 0.
	perceivedFrequency := 100.0.

]

{ #category : #menu }
WaveEditor >> showEnvelope [
	"Show an envelope wave constructed by collecting the maximum absolute value of the samples in fixed-size time windows of mSecsPerQuantum."

	| data mSecsPerQuantum samplesPerQuantum result endOfQuantum maxThisQuantum s nSamples |
	data := graph data.
	mSecsPerQuantum := 10.
	samplesPerQuantum := (mSecsPerQuantum / 1000.0) * self samplingRate.
	result := WriteStream on: (Array new: data size // samplesPerQuantum).
	endOfQuantum := samplesPerQuantum.
	maxThisQuantum := 0.
	nSamples := (data isKindOf: SoundBuffer)
		ifTrue: [data monoSampleCount]
		ifFalse: [data size].
	1 to: nSamples do: [:i |
		i asFloat > endOfQuantum ifTrue: [
			result nextPut: maxThisQuantum.
			maxThisQuantum := 0.
			endOfQuantum := endOfQuantum + samplesPerQuantum].
		s := data at: i.
		s < 0 ifTrue: [s := 0 - s].
		s > maxThisQuantum ifTrue: [maxThisQuantum := s]].
	WaveEditor openOn: result contents.

]

{ #category : #menu }
WaveEditor >> showFFTAtCursor [

	| data start availableSamples nu n fft r |
	data := graph data.
	start := graph cursor max: 1.
	availableSamples := (data size - start) + 1.
	nu := 12.
	nu > (availableSamples highBit - 1) ifTrue:
		[^ self inform: 'Too few samples after the cursor to take an FFT.' translated].
	n := 2 raisedTo: nu.
	fft := FFT new nu: nu.
	fft realData: ((start to: start + n - 1) collect: [:i | data at: i]).
	fft transformForward: true.
	r := (1 to: n // 2) collect:
		[:i | ((fft realData at: i) squared + (fft imagData at: i) squared) sqrt].
	WaveEditor openOn: r.


]

{ #category : #accessing }
WaveEditor >> sound: aSound [
	| buffer |
	buffer := aSound samples mergeStereo.
	graph data: buffer.
	loopLength := loopEnd := buffer size.
	self samplingRate: aSound originalSamplingRate.
	loopCycles :=  buffer size / aSound originalSamplingRate * 400.
	perceivedFrequency := 400.

]

{ #category : #'stepping and presenter' }
WaveEditor >> step [

	keyboard soundPrototype: self makeLoopedSampledSound
]

{ #category : #other }
WaveEditor >> stretch: sampleArray by: stretchFactor [
	"Return an array consisting of the given samples \stretched in time by the given factor."

	| out end incr i frac index |
	out := OrderedCollection new: (stretchFactor * sampleArray size) asInteger + 1.
	end := (sampleArray size - 1) asFloat.
	incr := 1.0 / stretchFactor.
	i := 1.0.
	[i < end] whileTrue: [
		frac := i fractionPart.
		index := i truncated.
		i := i + incr.
		out addLast:
			(((1.0 - frac) * (sampleArray at: index)) + (frac * (sampleArray at: index + 1))) rounded].
	^ out asArray

]

{ #category : #menu }
WaveEditor >> trimAfterCursor [

	graph data: (graph data copyFrom: 1 to: graph cursor).

]

{ #category : #menu }
WaveEditor >> trimBeforeCursor [

	graph data: (graph data copyFrom: graph cursor to: graph data size).
	graph cursor: 1.


]

{ #category : #other }
WaveEditor >> zeroCrossingAfter: index [
	"Find the index of the next negative-to-non-negative transition at or after the current index. The result is the index, i, of a zero crossing such that the sample at i-1 is negative and the sample at i is zero or positive. Answer the index of the last sample if the end of the array is encountered before finding a zero crossing."

	| data end i |
	data := graph data.
	end := data size.
	index <= 1 ifTrue: [^ 1].
	i := index - 1.
	[(i <= end) and: [(data at: i) >= 0]] whileTrue: [i := i + 1].  "find next negative sample"
	i >= end ifTrue: [^ end].

	i := i + 1.
	[(i <= end) and: [(data at: i) < 0]] whileTrue: [i := i + 1].  "find next non-negative sample"
	^ i

]
