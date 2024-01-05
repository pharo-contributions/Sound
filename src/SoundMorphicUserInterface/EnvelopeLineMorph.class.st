"
I'm a special polgon used to draw line in the envelop editor morph.
"
Class {
	#name : 'EnvelopeLineMorph',
	#superclass : 'PolygonMorph',
	#instVars : [
		'editor'
	],
	#category : 'SoundMorphicUserInterface',
	#package : 'SoundMorphicUserInterface'
}

{ #category : 'initialization' }
EnvelopeLineMorph >> defaultColor [
"answer the default color/fill style for the receiver"
	^ Color transparent
]

{ #category : 'editing' }
EnvelopeLineMorph >> dragVertex: ix event: evt fromHandle: handle [
	| p |
	super dragVertex: ix event: evt fromHandle: handle.
	p := owner acceptGraphPoint: evt cursorPoint at: ix.
	self verticesAt: ix put: p.

]

{ #category : 'editing' }
EnvelopeLineMorph >> dropVertex: ix event: evt fromHandle: handle [
	| oldVerts |
	oldVerts := vertices.
	super dropVertex: ix event: evt fromHandle: handle.
	vertices = oldVerts ifFalse: [owner deletePoint: ix "deleted a vertex"]
]

{ #category : 'editing' }
EnvelopeLineMorph >> newVertex: ix event: evt fromHandle: handle [
	"Install a new vertex if there is room."
	(owner insertPointAfter: ix) ifFalse: [^ self "not enough room"].
	super newVertex: ix event: evt fromHandle: handle.
	self verticesAt: ix+1 put: (owner acceptGraphPoint: evt cursorPoint at: ix+1).

]

{ #category : 'initialization' }
EnvelopeLineMorph >> vertices: verts borderWidth: bw borderColor: bc [ 
	super initialize.
	vertices := verts.
	
	borderWidth := bw.
	borderColor := bc.
	closed := false.
	arrows := #none.
	self beStraightSegments.
	self computeBounds
]
