"
I display a graph of numbers, normalized so the full range of values just fits my height. I support a movable cursor that can be dragged with the mouse.

Implementation notes: Some operations on me may be done at sound sampling rates (e.g. 11-44 thousand times/second). To allow such high bandwidth application, certain operations that change my appearance do not immediately report a damage rectangle. Instead, a flag is set indicating that my display needs to refreshed and a step method reports the damage rectangle if that flag is set. Also, I cache a bitmap of my graph to allow the cursor to be moved without redrawing the graph.

"
Class {
	#name : 'GraphMorph',
	#superclass : 'BorderedMorph',
	#instVars : [
		'data',
		'dataColor',
		'cursor',
		'cursorColor',
		'cursorColorAtZeroCrossings',
		'startIndex',
		'minVal',
		'maxVal',
		'cachedForm',
		'hasChanged'
	],
	#category : 'SoundMorphicUserInterface',
	#package : 'SoundMorphicUserInterface'
}

{ #category : 'commands' }
GraphMorph >> appendValue: aPointOrNumber [

	| newVal |
	data := data asOrderedCollection.
	newVal := self newValueFrom: aPointOrNumber.
	data addLast: newVal.
	newVal < minVal ifTrue: [minVal := newVal].
	newVal > maxVal ifTrue: [maxVal := newVal].
	self cursor: data size.
	self flushCachedForm.

]

{ #category : 'commands' }
GraphMorph >> centerCursor [
	"Scroll so that the cursor is as close as possible to the center of my window."

	| w |
	w := self width - (2 * borderWidth).
	self startIndex: ((cursor - (w // 2)) max: 1).

]

{ #category : 'commands' }
GraphMorph >> clear [

	self startIndex: 1.
	self cursor: 1.
	self data: OrderedCollection new.

]

{ #category : 'accessing' }
GraphMorph >> color: aColor [

	super color: aColor.
	self flushCachedForm.

]

{ #category : 'objects from disk' }
GraphMorph >> convertToCurrentVersion: varDict refStream: smartRefStrm [
	
	hasChanged ifNil: [hasChanged := false].
	^super convertToCurrentVersion: varDict refStream: smartRefStrm.


]

{ #category : 'e-toy support' }
GraphMorph >> cursor [

	^ cursor

]

{ #category : 'e-toy support' }
GraphMorph >> cursor: aNumber [

	| truncP |
	cursor ~= aNumber ifTrue:  [
		cursor := aNumber.
		truncP := aNumber truncated.
		truncP > data size ifTrue: [cursor := data size].
		truncP < 0 ifTrue: [cursor := 1].
		self keepIndexInView: truncP.
		hasChanged := true].

]

{ #category : 'accessing' }
GraphMorph >> cursorAtEnd [

	^ cursor truncated >= data size

]

{ #category : 'accessing' }
GraphMorph >> cursorColor [

	^ cursorColor

]

{ #category : 'accessing' }
GraphMorph >> cursorColor: aColor [

	cursorColor := aColor.
	self flushCachedForm.

]

{ #category : 'accessing' }
GraphMorph >> cursorColorAtZeroCrossing [

	^ cursorColorAtZeroCrossings

]

{ #category : 'accessing' }
GraphMorph >> cursorColorAtZeroCrossings: aColor [

	cursorColorAtZeroCrossings := aColor.
	self flushCachedForm.

]

{ #category : 'accessing' }
GraphMorph >> cursorWrapped: aNumber [

	| sz |
	cursor ~= aNumber ifTrue: [
		cursor := aNumber.
		sz := data size.
		sz = 0
			ifTrue: [cursor := 1]
			ifFalse: [
				((cursor >= (sz + 1)) or: [cursor < 0]) ifTrue: [
					cursor := cursor - ((cursor // sz) * sz)].
				cursor < 1 ifTrue: [cursor := sz + cursor]].
		"assert: 1 <= cursor < data size + 1"
		hasChanged := true].

]

{ #category : 'accessing' }
GraphMorph >> data [

	^ data

]

{ #category : 'accessing' }
GraphMorph >> data: aCollection [

	data := aCollection.
	maxVal := minVal := 0.
	data do: [:x |
		x < minVal ifTrue: [minVal := x].
		x > maxVal ifTrue: [maxVal := x]].

	self flushCachedForm.

]

{ #category : 'accessing' }
GraphMorph >> dataColor [

	^ dataColor

]

{ #category : 'accessing' }
GraphMorph >> dataColor: aColor [

	dataColor := aColor.
	self flushCachedForm.

]

{ #category : 'initialization' }
GraphMorph >> defaultColor [
"answer the default color/fill style for the receiver"
	^ Color
		r: 0.8
		g: 0.8
		b: 0.6
]

{ #category : 'private' }
GraphMorph >> drawCursorOn: aCanvas [

	| ptr x r c |
	ptr := (cursor asInteger max: 1) min: data size.
	c := cursorColor.
	((ptr > 1) and: [ptr < data size]) ifTrue: [
		(data at: ptr) sign ~= (data at: ptr + 1) sign
			ifTrue: [c := cursorColorAtZeroCrossings]].
	r := self innerBounds.
	x := r left + ptr - startIndex.
	((x >= r left) and: [x <= r right]) ifTrue: [
		aCanvas fillRectangle: (x@r top corner: x + 1@r bottom) color: c].

]

{ #category : 'private' }
GraphMorph >> drawDataOn: aCanvas [

	| yScale baseLine x start end value left top bottom right |
	super drawOn: aCanvas.

	data isEmpty ifTrue: [^ self].
	maxVal = minVal ifTrue: [
		yScale := 1.
	] ifFalse: [
		yScale := (bounds height - (2 * borderWidth)) asFloat / (maxVal - minVal)].
	baseLine := bounds bottom - borderWidth + (minVal * yScale) truncated.
	left := top := 0. right := 10. bottom := 0.
	x := bounds left + borderWidth.
	start := (startIndex asInteger max: 1) min: data size.
	end := (start + bounds width) min: data size.
	start to: end do: [:i |
		left := x truncated. right := x + 1.
		right > (bounds right - borderWidth) ifTrue: [^ self].
		value := (data at: i) asFloat.
		value >= 0.0 ifTrue: [
			top := baseLine - (yScale * value) truncated.
			bottom := baseLine.
		] ifFalse: [
			top := baseLine.
			bottom := baseLine - (yScale * value) truncated].
		aCanvas fillRectangle: (left@top corner: right@bottom) color: dataColor.
		x := x + 1].

]

{ #category : 'drawing' }
GraphMorph >> drawOn: aCanvas [ 
	| c |
	cachedForm isNil 
		ifTrue: 
			[c := Display defaultCanvasClass extent: bounds extent.
			c translateBy: bounds origin negated
				during: [:tempCanvas | self drawDataOn: tempCanvas].
			cachedForm := c form].
	aCanvas 
		cache: bounds
		using: cachedForm
		during: [:cachingCanvas | self drawDataOn: cachingCanvas].
	self drawCursorOn: aCanvas
]

{ #category : 'private' }
GraphMorph >> flushCachedForm [

	cachedForm := nil.
	hasChanged := true.

]

{ #category : 'event handling' }
GraphMorph >> handlesMouseDown: evt [

	evt shiftPressed
		ifTrue: [^ super handlesMouseDown: evt]
		ifFalse: [^ true].

]

{ #category : 'initialization' }
GraphMorph >> initialize [
	"initialize the state of the receiver"
	super initialize.
	self extent: 365 @ 80.
	dataColor := Color darkGray.
	cursor := 1.0.
	"may be fractional"
	cursorColor := Color red.
	cursorColorAtZeroCrossings := Color red.
	startIndex := 1.
	hasChanged := false.
	self data: ((0 to: 360 - 1) collect: [:x | (100.0 * x degreesToRadians sin) asInteger])
]

{ #category : 'accessing' }
GraphMorph >> interpolatedValueAtCursor [
	| sz prev frac next |
	data isEmpty ifTrue: [^0].
	sz := data size.
	cursor < 0 ifTrue: [^data first].	"just to be safe, though cursor shouldn't be negative"
	prev := cursor truncated.
	frac := cursor - prev.
	prev < 1 ifTrue: [prev := sz].
	prev > sz ifTrue: [prev := 1].
	"assert: 1 <= prev <= sz"
	frac = 0 ifTrue: [^data at: prev].	"no interpolation needed"

	"interpolate"
	next := prev = sz ifTrue: [1] ifFalse: [prev + 1].
	^(1.0 - frac) * (data at: prev) + (frac * (data at: next))
]

{ #category : 'private' }
GraphMorph >> keepIndexInView: index [

	| w newStart |
	w := bounds width - (2 * borderWidth).
	index < startIndex ifTrue: [
		newStart := index - w + 1.
		^ self startIndex: (newStart max: 1)].
	index > (startIndex + w) ifTrue: [
		^ self startIndex: (index min: data size)].

]

{ #category : 'accessing' }
GraphMorph >> lastValue [
	data isEmpty ifTrue: [^0].
	^data last
]

{ #category : 'accessing' }
GraphMorph >> lastValue: aNumber [

	self appendValue: aNumber.

]

{ #category : 'layout' }
GraphMorph >> layoutChanged [

	super layoutChanged.
	cachedForm := nil.

]

{ #category : 'commands' }
GraphMorph >> loadSineWave [

	self loadSoundData: SoundBuffer sineTable.

]

{ #category : 'commands' }
GraphMorph >> loadSound: aSound [

	self loadSoundData: aSound samples.

]

{ #category : 'commands' }
GraphMorph >> loadSoundData: aCollection [

	| newData scale |
	scale := 0.
	aCollection do: [:v |
		| absV |
		(absV := v abs) > scale ifTrue: [scale := absV]].
	scale := 100.0 / scale.
	newData := OrderedCollection new: aCollection size.
	1 to: aCollection size do: [:i | newData addLast: (scale * (aCollection at: i))].

	self data: newData.
	self startIndex: 1.
	self cursor: 1.

]

{ #category : 'event handling' }
GraphMorph >> mouseMove: evt [

	| x w |
	x := evt cursorPoint x - (bounds left + borderWidth).
	w := self width - (2 * borderWidth).

	self changed.
	x < 0 ifTrue: [
		cursor := startIndex + (3 * x).
		cursor := (cursor max: 1) min: data size.
		^ self startIndex: cursor].
	x > w ifTrue: [
		cursor := startIndex + w + (3 * (x - w)).
		cursor := (cursor max: 1) min: data size.
		^ self startIndex: cursor - w].

	cursor := ((startIndex + x) max: 1) min: data size.

]

{ #category : 'private' }
GraphMorph >> newValueFrom: aPointOrNumber [

	^ aPointOrNumber class = Point
		ifTrue: [aPointOrNumber r]
		ifFalse: [aPointOrNumber].

]

{ #category : 'commands' }
GraphMorph >> playOnce [

	| scaledData scale |
	data isEmpty ifTrue: [^ self].  "nothing to play"
	scale := 1.
	data do: [:v |
		| absV |
		(absV := v abs) > scale ifTrue: [scale := absV]].
	scale := 32767.0 / scale.
	scaledData := SoundBuffer newMonoSampleCount: data size.
	1 to: data size do: [:i | scaledData at: i put: (scale * (data at: i)) truncated].
	SoundSystem current playSampledSound: scaledData rate: 11025.

]

{ #category : 'commands' }
GraphMorph >> reverse [

	data := data reversed.
	self flushCachedForm.

]

{ #category : 'accessing' }
GraphMorph >> startIndex [

	^ startIndex

]

{ #category : 'accessing' }
GraphMorph >> startIndex: aNumber [

	startIndex ~= aNumber ifTrue:  [
		startIndex := aNumber asInteger.
		self flushCachedForm].

]

{ #category : 'stepping and presenter' }
GraphMorph >> step [
	"Make a deferred damage rectangle if I've changed. This allows applications to call methods that invalidate my display at high-bandwidth without paying the cost of doing the damage reporting on ever call; they can merely set hasChanged to true."

	super step.
	hasChanged isNil ifTrue: [hasChanged := false].
	hasChanged 
		ifTrue: 
			[self changed.
			hasChanged := false]
]

{ #category : 'accessing' }
GraphMorph >> valueAtCursor [

	data isEmpty ifTrue: [^ 0].
	^ data at: ((cursor truncated max: 1) min: data size)

]

{ #category : 'accessing' }
GraphMorph >> valueAtCursor: aPointOrNumber [

	data isEmpty ifTrue: [^ 0].
	data
		at: ((cursor truncated max: 1) min: data size)
		put: (self newValueFrom: aPointOrNumber).
	self flushCachedForm.

]
