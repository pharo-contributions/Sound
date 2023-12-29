"
I represent a mu-law (u-law) codec. I compress sound data by a factor of 2:1 by encoding the most significant 12 bits of each 16-bit sample as a signed, exponentially encoded byte. The idea is to use more resolution for smaller lower sample values. This encoding was developed for the North American phone system and a variant of it, a-law, is a European phone standard. It is a popular sound encoding on Unix platforms (.au files).

"
Class {
	#name : 'MuLawCodec',
	#superclass : 'SoundCodec',
	#classVars : [
		'DecodingTable'
	],
	#category : 'Sound-Core',
	#package : 'Sound',
	#tag : 'Core'
}

{ #category : 'initialization' }
MuLawCodec class >> initialize [
	"Build the 256 entry table to be used to decode 8-bit uLaw-encoded samples."
	"MuLawCodec initialize"

	| encoded codec lastEncodedPos lastEncodedNeg |
	DecodingTable := Array new: 256.
	codec := self new.
	lastEncodedPos := nil.
	lastEncodedNeg := nil.
	4095 to: 0 by: -1 do: [:s |
		encoded := codec uLawEncode12Bits: s.
		lastEncodedPos = encoded
			ifFalse: [
				DecodingTable at: (encoded + 1) put: (s bitShift: 3).
				lastEncodedPos := encoded].
		encoded := encoded bitOr: 16r80.
		lastEncodedNeg = encoded
			ifFalse: [
				DecodingTable at: (encoded + 1) put: (s bitShift: 3) negated.
				lastEncodedNeg := encoded]].

]

{ #category : 'subclass responsibility' }
MuLawCodec >> bytesPerEncodedFrame [
	"Answer the number of bytes required to hold one frame of compressed sound data. Answer zero if this codec produces encoded frames of variable size."

	^ 1

]

{ #category : 'subclass responsibility' }
MuLawCodec >> decodeFrames: frameCount from: srcByteArray at: srcIndex into: dstSoundBuffer at: dstIndex [
	"Decode the given number of monophonic frames starting at the given index in the given ByteArray of compressed sound data and storing the decoded samples into the given SoundBuffer starting at the given destination index. Answer a pair containing the number of bytes of compressed data consumed and the number of decompressed samples produced."
	"Note: Assume that the sender has ensured that the given number of frames will not exhaust either the source or destination buffers."

	| dst |
	dst := dstIndex.
	srcIndex to: srcIndex + frameCount - 1 do: [:src |
		dstSoundBuffer at: dst put: (DecodingTable at: (srcByteArray at: src) + 1).
		dst := dst + 1].
	^ Array with: frameCount with: frameCount

]

{ #category : 'subclass responsibility' }
MuLawCodec >> encodeFrames: frameCount from: srcSoundBuffer at: srcIndex into: dstByteArray at: dstIndex [
	"Encode the given number of frames starting at the given index in the given monophonic SoundBuffer and storing the encoded sound data into the given ByteArray starting at the given destination index. Encode only as many complete frames as will fit into the destination. Answer a pair containing the number of samples consumed and the number of bytes of compressed data produced."
	"Note: Assume that the sender has ensured that the given number of frames will not exhaust either the source or destination buffers."

	srcIndex to: srcIndex + frameCount - 1 do: [:i |
		dstByteArray at: i put: (self uLawEncodeSample: (srcSoundBuffer at: i))].
	^ Array with: frameCount with: frameCount

]

{ #category : 'subclass responsibility' }
MuLawCodec >> samplesPerFrame [
	"Answer the number of sound samples per compression frame."

	^ 1

]

{ #category : 'external access' }
MuLawCodec >> uLawDecodeSample: byte [
	"Decode a 16-bit signed sample from 8 bits using uLaw decoding"

	^ DecodingTable at: byte + 1
]

{ #category : 'private' }
MuLawCodec >> uLawEncode12Bits: s [
	"Encode a 12-bit unsigned sample (0-4095) into 7 bits using uLaw encoding.
	This gets called by a method that scales 16-bit signed integers down to a
		12-bit magnitude, and then ORs in 16r80 if they were negative.
	Detail: May get called with s >= 4096, and this works fine."

	s < 496 ifTrue: [
		s < 112 ifTrue: [
			s < 48 ifTrue: [
				s < 16
					ifTrue: [^ 16r70 bitOr: (15 - s)]
					ifFalse: [^ 16r60 bitOr: (15 - ((s - 16) bitShift: -1))]].
			^ 16r50 bitOr: (15 - ((s - 48) bitShift: -2))].
		s < 240
			ifTrue: [^ 16r40 bitOr: (15 - ((s - 112) bitShift: -3))]
			ifFalse: [^ 16r30 bitOr: (15 - ((s - 240) bitShift: -4))]].

	s < 2032 ifTrue: [
		s < 1008
			ifTrue: [^ 16r20 bitOr: (15 - ((s - 496) bitShift: -5))]
			ifFalse: [^ 16r10 bitOr: (15 - ((s - 1008) bitShift: -6))]].

	s < 4080
		ifTrue: [^ 15 - ((s - 2032) bitShift: -7)]
		ifFalse: [^ 0].

]

{ #category : 'external access' }
MuLawCodec >> uLawEncodeSample: sample [
	"Encode a 16-bit signed sample into 8 bits using uLaw encoding"

	| s |
	s := sample // 8.  "drop 3 least significant bits"
	s < 0 ifTrue: [^ (self uLawEncode12Bits: 0-s) + 16r80]
		ifFalse: [^ (self uLawEncode12Bits: s)].

]
