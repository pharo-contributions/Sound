Class {
	#name : 'GSMCodec',
	#superclass : 'SoundCodec',
	#instVars : [
		'encodeState',
		'decodeState'
	],
	#category : 'Sound-Core',
	#package : 'Sound',
	#tag : 'Core'
}

{ #category : 'instance creation' }
GSMCodec class >> new [

	^ super new reset

]

{ #category : 'subclass responsibilities' }
GSMCodec >> bytesPerEncodedFrame [

	^ 33

]

{ #category : 'subclass responsibilities' }
GSMCodec >> decodeFrames: frameCount from: srcByteArray at: srcIndex into: dstSoundBuffer at: dstIndex [

	| p |
	p := self	primDecode: decodeState frames: frameCount
			from: srcByteArray at: srcIndex
			into: dstSoundBuffer at: dstIndex.
	^ Array with: p x with: p y

]

{ #category : 'subclass responsibilities' }
GSMCodec >> encodeFrames: frameCount from: srcSoundBuffer at: srcIndex into: dstByteArray at: dstIndex [

	| p |
	p := self	primEncode: encodeState frames: frameCount
			from: srcSoundBuffer at: srcIndex
			into: dstByteArray at: dstIndex.
	^ Array with: p x with: p y

]

{ #category : 'primitives' }
GSMCodec >> primDecode: state frames: frameCount from: srcSoundBuffer at: srcIndex into: dstByteArray at: dstIndex [

	<primitive: 'primitiveGSMDecode' module: 'SoundCodecPrims'>
	self primitiveFailed.

]

{ #category : 'primitives' }
GSMCodec >> primEncode: state frames: frameCount from: srcSoundBuffer at: srcIndex into: dstByteArray at: dstIndex [

	<primitive: 'primitiveGSMEncode' module: 'SoundCodecPrims'>
	self primitiveFailed.

]

{ #category : 'primitives' }
GSMCodec >> primNewState [

	<primitive: 'primitiveGSMNewState' module: 'SoundCodecPrims'>
	self error: 'The SoundCodecPrims plugin is not available'.

]

{ #category : 'subclass responsibilities' }
GSMCodec >> reset [
	"Reset my encoding/decoding state to prepare to encode or decode a new sound stream."

	encodeState := self primNewState.
	decodeState := self primNewState.

]

{ #category : 'subclass responsibilities' }
GSMCodec >> samplesPerFrame [

	^ 160

]
