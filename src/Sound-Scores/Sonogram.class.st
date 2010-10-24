"
Sonograms are imageMorphs that will repeatedly plot arrays of values as black on white columns moving to the right in time and scrolling left as necessary.
"
Class {
	#name : #Sonogram,
	#superclass : #ImageMorph,
	#instVars : [
		'lastX',
		'scrollDelta',
		'columnForm',
		'minVal',
		'maxVal',
		'pixValMap'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #geometry }
Sonogram >> extent: newExtent [
	super image: (Form extent: newExtent depth: Display depth).
	lastX := -1.
	columnForm := Form extent: (32//image depth)@(image height) depth: image depth.
	pixValMap := ((1 to: 256) collect:
			[:i | columnForm pixelValueFor: (Color gray: (256-i)/255.0)])
		as: Bitmap.

]

{ #category : #all }
Sonogram >> extent: extent minVal: min maxVal: max scrollDelta: d [
	minVal := min.
	maxVal := max.
	scrollDelta := d.
	self extent: extent.

" try following with scrolldelta = 1, 20, 200
	| s data |
	s := Sonogram new extent: 200@50
				minVal: 0.0 maxVal: 1.0 scrollDelta: 20.
	World addMorph: s.
	data := (1 to: 133) collect: [:i | 0.0].
	1 to: 300 do:
		[:i | data at: (i\\133)+1 put: 1.0.
		s plotColumn: data.
		data at: (i\\133)+1 put: 0.0.
		World doOneCycleNow].
	s delete	
"
]

{ #category : #all }
Sonogram >> plotColumn: dataArray [ 
	| chm1 i normVal r |
	columnForm unhibernate.
	chm1 := columnForm height - 1.
	0 to: chm1
		do: 
			[:y | 
			i := y * (dataArray size - 1) // chm1 + 1.
			normVal := ((dataArray at: i) - minVal) / (maxVal - minVal).
			normVal := normVal max: 0.0.
			normVal := normVal min: 1.0.
			columnForm bits at: chm1 - y + 1
				put: (pixValMap at: (normVal * 255.0) truncated + 1)].
	(lastX := lastX + 1) > (image width - 1) ifTrue: [self scroll].
	image 
		copy: (r := lastX @ 0 extent: 1 @ image height)
		from: (32 // image depth - 1) @ 0
		in: columnForm
		rule: Form over.
	"self changed."
	self invalidRect: (r translateBy: self position)
]

{ #category : #all }
Sonogram >> scroll [
	image copy: (scrollDelta@0 extent: (image width-scrollDelta)@image height)
			from: image to: 0@0 rule: Form over.
	lastX := lastX - scrollDelta.
	self changed
]
