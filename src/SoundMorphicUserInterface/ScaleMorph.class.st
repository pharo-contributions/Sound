"
I'm a scale with start and stop and labelsAbove and captionAbove. 

Determines where the labels and captions print, if they exist. Tick marks can either go up or down. For ticks going up, put in majorTickLength > 0. 

Negative value will make ticks go down. Examples on Class side.

 (ScaleMorph new
		start: 100
		stop: 150
		minorTick: 1
		minorTickLength: 2
		majorTick: 10
		majorTickLength: 10
		caption: 'Example 1'
		tickPrintBlock: [:v | v printString];
		width: 300) openInWorld
"
Class {
	#name : #ScaleMorph,
	#superclass : #BorderedMorph,
	#instVars : [
		'caption',
		'start',
		'stop',
		'minorTick',
		'minorTickLength',
		'majorTick',
		'majorTickLength',
		'tickPrintBlock',
		'labelsAbove',
		'captionAbove'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #examples }
ScaleMorph class >> example1 [
	"Example 1 captions and labels above, ticks point up"
	^ (self new
		start: 0
		stop: 150
		minorTick: 1
		minorTickLength: 2
		majorTick: 10
		majorTickLength: 10
		caption: 'Example 1'
		tickPrintBlock: [:v | v printString];
		width: 300) openInWorld
]

{ #category : #examples }
ScaleMorph class >> example2 [
	"Example 2 captions and labels above, ticks point down"
	^ (self new
		start: 0
		stop: 150
		minorTick: 1
		minorTickLength: 2
		majorTick: 10
		majorTickLength: -10
		caption: 'Example 2'
		tickPrintBlock: [:v | v printString];
		width: 300) openInWorld
]

{ #category : #examples }
ScaleMorph class >> example3 [
	"Example 3 caption above, labels below, ticks point down"
	^ (self new
		start: -23
		stop: 47
		minorTick: 1
		minorTickLength: 2
		majorTick: 10
		majorTickLength: -10
		caption: 'Example 3'
		tickPrintBlock: [:v | v printString]
		labelsAbove: false
		captionAbove: true;
		color: Color lightBlue;
		width: 300) openInWorld
]

{ #category : #examples }
ScaleMorph class >> example4 [
	"Example 4 caption below, labels above, ticks point up"
	^ (self new
		start: 100000
		stop: 300000
		minorTick: 5000
		minorTickLength: 2
		majorTick: 50000
		majorTickLength: 10
		caption: 'Example 4'
		tickPrintBlock: [:v | '$' , v printString]
		labelsAbove: true
		captionAbove: false;
		color: Color lightOrange;
		width: 300) openInWorld
]

{ #category : #drawing }
ScaleMorph >> buildLabels [
	| scale x1 y1 y2 captionMorph loopStart offset |
	majorTickLength * minorTickLength < 0 
		ifTrue: [ minorTickLength := 0 - minorTickLength ].
	self removeAllMorphs.
	caption ifNotNil: 
		[ captionMorph := StringMorph contents: caption.
		offset := captionAbove 
			ifTrue: [majorTickLength abs + captionMorph height + 7]
			ifFalse: [2].
		captionMorph 
			align: captionMorph bounds bottomCenter
			with: self bounds bottomCenter - (0 @ offset).
		self addMorph: captionMorph].
	tickPrintBlock ifNotNil: 
			["Calculate the offset for the labels, depending on whether or not 
			  1) there's a caption   
			below, 2) the labels are above or below the ticks, and 3) the   
			ticks go up or down"
			offset := labelsAbove 
					ifTrue: [majorTickLength abs + minorTickLength abs + 2]
					ifFalse: [2].
			caption 
				ifNotNil: [captionAbove ifFalse: [offset := offset + captionMorph height + 2]].
			scale := (self innerBounds width - 1) / (stop - start) asFloat.
			x1 := self innerBounds left.
			y1 := self innerBounds bottom.
			y2 := y1 - offset.
			"Start loop on multiple of majorTick"
			loopStart := (start / majorTick) ceiling * majorTick.
			loopStart to: stop
				by: majorTick
				do: 
					[ :v | | x tickMorph | 
					x := x1 + (scale * (v - start)).
					tickMorph := StringMorph contents: (tickPrintBlock value: v).
					tickMorph align: tickMorph bounds bottomCenter with: x @ y2.
					tickMorph left < self left 
						ifTrue: [ tickMorph position: self left @ tickMorph top ].
					tickMorph right > self right 
						ifTrue: [ tickMorph position: (self right - tickMorph width) @ tickMorph top].
					self addMorph: tickMorph ]]
]

{ #category : #accessing }
ScaleMorph >> caption [
	^ caption
]

{ #category : #accessing }
ScaleMorph >> caption: aString [
	caption := aString
]

{ #category : #accessing }
ScaleMorph >> captionAbove: aBoolean [ 
	captionAbove := aBoolean
]

{ #category : #geometry }
ScaleMorph >> checkExtent: newExtent [ 
	| pixPerTick newWidth |
	pixPerTick := newExtent x - (self borderWidth * 2) - 1 / ((stop - start) asFloat / minorTick).
	pixPerTick := pixPerTick
				detentBy: 0.1
				atMultiplesOf: 1.0
				snap: false.
	newWidth := pixPerTick * ((stop - start) asFloat / minorTick) + (self borderWidth * 2) + 1.
	^ (newWidth @ newExtent y).
]

{ #category : #default }
ScaleMorph >> defaultBorderWidth [
	"answer the default border width for the receiver"
	^ 0
]

{ #category : #default }
ScaleMorph >> defaultColor [
	"answer the default color/fill style for the receiver"
	^ Color lightGreen
]

{ #category : #drawing }
ScaleMorph >> drawMajorTicksOn: aCanvas [ 
	| scale x1 y1 y2 y3 loopStart checkStart yoffset randomLabel even |
	scale := (self innerBounds width - 1) / (stop - start) asFloat.
	yoffset := majorTickLength < 0 
		ifTrue: [ majorTickLength abs + 1]
		ifFalse: [1].
	caption ifNotNil: 
			[captionAbove 
				ifFalse: 
					[randomLabel := StringMorph contents: 'Foo'.
					yoffset := yoffset + randomLabel height + 2]].
	tickPrintBlock ifNotNil: 
			[labelsAbove 
				ifFalse: 
					[randomLabel := StringMorph contents: '50'.
					yoffset := yoffset + randomLabel height + 2]].
	x1 := self innerBounds left.
	y1 := self innerBounds bottom - yoffset.
	y2 := y1 - majorTickLength.
	y3 := y1 - ((minorTickLength + majorTickLength) // 2).
	even := true.
	"Make sure major ticks start drawing on a multiple of majorTick"
	loopStart := (start / majorTick) ceiling * majorTick.
	checkStart := (start / (majorTick / 2.0)) ceiling * majorTick.
	"Check to see if semimajor tick should be drawn before majorTick"
	checkStart = (loopStart * 2) 
		ifFalse: 
			[loopStart := checkStart / 2.0.
			even := false].
	loopStart to: stop
		by: majorTick / 2.0
		do: 
			[:v | | yy x | 
			x := x1 + (scale * (v - start)).
			yy := even ifTrue: [y2] ifFalse: [y3].
			aCanvas 
				line: x @ y1
				to: x @ yy
				width: 1
				color: Color black.
			even := even not]
]

{ #category : #drawing }
ScaleMorph >> drawMinorTicksOn: aCanvas [ 
	| scale x1 y1 y2 loopStart yoffset randomLabel |
	scale := (self innerBounds width - 1) / (stop - start) asFloat.
	yoffset := majorTickLength < 0 
				ifTrue: [majorTickLength abs + 1]
				ifFalse: [1]. 
	caption ifNotNil: 
			[captionAbove 
				ifFalse: 
					[randomLabel := StringMorph contents: 'Foo'.
					yoffset := yoffset + randomLabel height + 2]].
	tickPrintBlock ifNotNil: 
			[labelsAbove 
				ifFalse: 
					[randomLabel := StringMorph contents: '50'.
					yoffset := yoffset + randomLabel height + 2]].
	x1 := self innerBounds left.
	y1 := self innerBounds bottom - yoffset.
	y2 := y1 - minorTickLength.
	loopStart := (start / minorTick) ceiling * minorTick.
	loopStart to: stop
		by: minorTick
		do: 
			[:v | | x | 
			x := x1 + (scale * (v - start)).
			aCanvas 
				line: x @ y1
				to: x @ y2
				width: 1
				color: Color black]
]

{ #category : #drawing }
ScaleMorph >> drawOn: aCanvas [ 
	
	super drawOn: aCanvas.
	self drawTicksOn: aCanvas.
]

{ #category : #drawing }
ScaleMorph >> drawTicksOn: aCanvas [ 
	self drawMajorTicksOn: aCanvas.
	self drawMinorTicksOn: aCanvas
]

{ #category : #geometry }
ScaleMorph >> extent: newExtent [ 
	| modExtent |
	modExtent := self checkExtent: newExtent.
	super extent: modExtent.
	self buildLabels
]

{ #category : #initialization }
ScaleMorph >> initialize [
	"initialize the state of the receiver"
	
	super initialize.
	start := 0.
	stop := 100.
	minorTick := 1.
	majorTick := 10.
	minorTickLength := 3.
	majorTickLength := 10.
	caption := nil.
	tickPrintBlock := [:v | v printString].
	labelsAbove := true.
	captionAbove := true
]

{ #category : #accessing }
ScaleMorph >> labelsAbove: aBoolean [
	labelsAbove := aBoolean
]

{ #category : #accessing }
ScaleMorph >> majorTickLength: anInteger [ 
	majorTickLength := anInteger
]

{ #category : #accessing }
ScaleMorph >> minorTickLength: anInteger [
	minorTickLength := anInteger
]

{ #category : #'stepping and presenter' }
ScaleMorph >> start [
	^ start
]

{ #category : #accessing }
ScaleMorph >> start: aNumber [
	start := aNumber
]

{ #category : #initialization }
ScaleMorph >> start: strt stop: stp minorTick: mnt minorTickLength: mntLen majorTick: mjt majorTickLength: mjtLen [

	self 
		start: strt 
		stop: stp 
		minorTick: mnt 
		minorTickLength: mntLen 
		majorTick: mjt 
		majorTickLength: mjtLen 
		caption: nil 
		tickPrintBlock: nil
	
]

{ #category : #initialization }
ScaleMorph >> start: strt stop: stp minorTick: mnt minorTickLength: mntLen majorTick: mjt majorTickLength: mjtLen caption: cap tickPrintBlock: blk [ 

	self 
		start: strt 
		stop: stp 
		minorTick: mnt 
		minorTickLength: mntLen 
		majorTick: mjt 
		majorTickLength: mjtLen 
		caption: cap 
		tickPrintBlock: blk 
		labelsAbove: true 
		captionAbove: true.
	
]

{ #category : #initialization }
ScaleMorph >> start: strt stop: stp minorTick: mnt minorTickLength: mntLen majorTick: mjt majorTickLength: mjtLen caption: cap tickPrintBlock: blk labelsAbove: aBoolean captionAbove: notherBoolean [ 
	
	start := strt.
	stop := stp.
	minorTick := mnt.
	minorTickLength := mntLen.
	majorTick := mjt.
	majorTickLength := mjtLen.
	caption := cap.
	tickPrintBlock := blk.
	labelsAbove := aBoolean.
	captionAbove := notherBoolean.
	self buildLabels
]

{ #category : #'stepping and presenter' }
ScaleMorph >> stop [
	^ stop
]

{ #category : #accessing }
ScaleMorph >> stop: aNumber [
	stop := aNumber
]

{ #category : #accessing }
ScaleMorph >> tickPrintBlock: aBlock [
	tickPrintBlock := aBlock
]
