"
This is a simple ADPCM (adapative delta pulse code modulation) codec. This is a general audio codec that compresses speech, music, or sound effects equally well, and works at any sampling rate (i.e., it contains no frequency-sensitive filters). It compresses 16-bit sample data down to 5, 4, 3, or 2 bits per sample, with lower fidelity and increased noise at the lowest bit rates. Although it does not deliver state-of-the-art compressions, the algorithm is small, simple, and extremely fast, since the encode/decode primitives have been translated into C primitives.

This codec will also encode and decode all Flash .swf file compressed sound formats, both mono and stereo. (Note: stereo Flash compression is not yet implemented, but stereo decompression works.)

"
Class {
	#name : #ADPCMCodec,
	#superclass : #SoundCodec,
	#instVars : [
		'predicted',
		'index',
		'deltaSignMask',
		'deltaValueMask',
		'deltaValueHighBit',
		'frameSizeMask',
		'currentByte',
		'bitPosition',
		'byteIndex',
		'encodedBytes',
		'samples',
		'rightSamples',
		'sampleIndex',
		'bitsPerSample',
		'stepSizeTable',
		'indexTable'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #'instance creation' }
ADPCMCodec class >> new [

	^ super new
		initializeForBitsPerSample: 4
		samplesPerFrame: 0.

]

{ #category : #'instance creation' }
ADPCMCodec class >> newBitsPerSample: bitsPerSample [

	^ super new
		initializeForBitsPerSample: bitsPerSample
		samplesPerFrame: 0.

]

{ #category : #'primitive generation' }
ADPCMCodec class >> translatedPrimitives [
	"Answer a string containing the translated C code for my primitives."
	"Note: This code currently must be hand-edited to remove several methods that are inlined (thus not needed) but not pruned out by the ST-to-C translator."

	^#(
		(ADPCMCodec privateDecodeMono:)
		(ADPCMCodec privateDecodeStereo:)
		(ADPCMCodec privateEncodeMono:)
		(ADPCMCodec privateEncodeStereo:)
		(ADPCMCodec indexForDeltaFrom:to:)
		(ADPCMCodec nextBits:)
		(ADPCMCodec nextBits:put:))

]

{ #category : #'codec stuff' }
ADPCMCodec >> bytesPerEncodedFrame [
	"Answer the number of bytes required to hold one frame of compressed sound data."
	"Note: When used as a normal codec, the frame size is always 8 samples which results in (8 * bitsPerSample) / 8 = bitsPerSample bytes."

	| bitCount |
	frameSizeMask = 0 ifTrue: [^ bitsPerSample].
	"Following assumes mono:"
	bitCount := 16 + 6 + ((self samplesPerFrame - 1) * bitsPerSample).
	^ (bitCount + 7) // 8

]

{ #category : #'codec stuff' }
ADPCMCodec >> compressAndDecompress: aSound [
	"Compress and decompress the given sound. Overridden to use same bits per sample for both compressing and decompressing."

	| compressed decoder |
	compressed := self compressSound: aSound.
	decoder := self class new
		initializeForBitsPerSample: bitsPerSample
		samplesPerFrame: 0.
	^ decoder decompressSound: compressed


]

{ #category : #private }
ADPCMCodec >> decode: aByteArray bitsPerSample: bits [

	^ self
		decode: aByteArray
		sampleCount: (aByteArray size * 8) // bits
		bitsPerSample: bits
		frameSize: 0
		stereo: false

]

{ #category : #private }
ADPCMCodec >> decode: aByteArray sampleCount: count bitsPerSample: bits frameSize: frameSize stereo: stereoFlag [

	self initializeForBitsPerSample: bits samplesPerFrame: frameSize.
	encodedBytes := aByteArray.
	byteIndex := 0.
	bitPosition := 0.
	currentByte := 0.
	stereoFlag
		ifTrue: [
			self resetForStereo.
			samples := SoundBuffer newMonoSampleCount: count.
			rightSamples := SoundBuffer newMonoSampleCount: count.
			sampleIndex := 0.
			self privateDecodeStereo: count.
			^ Array with: samples with: rightSamples]
		ifFalse: [
			samples := SoundBuffer newMonoSampleCount: count.
			sampleIndex := 0.
			self privateDecodeMono: count.
			^ samples]

]

{ #category : #private }
ADPCMCodec >> decodeFlash: aByteArray sampleCount: sampleCount stereo: stereoFlag [

	| bits |
	encodedBytes := aByteArray.
	byteIndex := 0.
	bitPosition := 0.
	currentByte := 0.
	bits := 2 + (self nextBits: 2).  "bits per sample"
	self initializeForBitsPerSample: bits samplesPerFrame: 4096.
	stereoFlag
		ifTrue: [
			self resetForStereo.
			samples := SoundBuffer newMonoSampleCount: sampleCount.
			rightSamples := SoundBuffer newMonoSampleCount: sampleCount.
			sampleIndex := 0.
			self privateDecodeStereo: sampleCount.
			^ Array with: samples with: rightSamples]
		ifFalse: [
			samples := SoundBuffer newMonoSampleCount: sampleCount.
			sampleIndex := 0.
			self privateDecodeMono: sampleCount.
			^ Array with: samples].

]

{ #category : #'codec stuff' }
ADPCMCodec >> decodeFrames: frameCount from: srcByteArray at: srcIndex into: dstSoundBuffer at: dstIndex [
	"Decode the given number of monophonic frames starting at the given index in the given ByteArray of compressed sound data and storing the decoded samples into the given SoundBuffer starting at the given destination index. Answer a pair containing the number of bytes of compressed data consumed and the number of decompressed samples produced."
	"Note: Assume that the sender has ensured that the given number of frames will not exhaust either the source or destination buffers."

	encodedBytes := srcByteArray.
	byteIndex := srcIndex - 1.
	bitPosition := 0.
	currentByte := 0.
	samples := dstSoundBuffer.
	sampleIndex := dstIndex - 1.
	self privateDecodeMono: (frameCount * self samplesPerFrame).
	^ Array with: (byteIndex - (srcIndex - 1)) with: (sampleIndex - (dstIndex - 1))

]

{ #category : #private }
ADPCMCodec >> encode: aSoundBuffer bitsPerSample: bits [

	^ self
		encodeLeft: aSoundBuffer
		right: nil
		bitsPerSample: bits
		frameSize: 0
		forFlash: false

]

{ #category : #private }
ADPCMCodec >> encodeFlashLeft: leftSoundBuffer right: rightSoundBuffer bitsPerSample: bits [

	^ self
		encodeLeft: leftSoundBuffer
		right: rightSoundBuffer
		bitsPerSample: bits
		frameSize: 4096
		forFlash: true

]

{ #category : #'codec stuff' }
ADPCMCodec >> encodeFrames: frameCount from: srcSoundBuffer at: srcIndex into: dstByteArray at: dstIndex [
	"Encode the given number of frames starting at the given index in the given monophonic SoundBuffer and storing the encoded sound data into the given ByteArray starting at the given destination index. Encode only as many complete frames as will fit into the destination. Answer a pair containing the number of samples consumed and the number of bytes of compressed data produced."
	"Note: Assume that the sender has ensured that the given number of frames will not exhaust either the source or destination buffers."

	samples := srcSoundBuffer.
	sampleIndex := srcIndex - 1.
	encodedBytes := dstByteArray.
	byteIndex := dstIndex - 1.
	bitPosition := 0.
	currentByte := 0.
	self privateEncodeMono: (frameCount * self samplesPerFrame).
	^ Array with: frameCount with: (byteIndex - (dstIndex - 1))

]

{ #category : #private }
ADPCMCodec >> encodeLeft: leftSoundBuffer right: rightSoundBuffer bitsPerSample: bits frameSize: frameSize forFlash: flashFlag [

	| stereoFlag sampleCount sampleBitCount bitCount |
	self initializeForBitsPerSample: bits samplesPerFrame: frameSize.
	stereoFlag := rightSoundBuffer notNil.
	sampleCount := leftSoundBuffer monoSampleCount.
	stereoFlag
		ifTrue: [sampleBitCount := 2 * (sampleCount * bitsPerSample)]
		ifFalse: [sampleBitCount := sampleCount * bitsPerSample].
	bitCount := sampleBitCount +
		(self headerBitsForSampleCount: sampleCount stereoFlag: stereoFlag).

	encodedBytes := ByteArray new: ((bitCount / 8) ceiling roundUpTo: self bytesPerEncodedFrame).
	byteIndex := 0.
	bitPosition := 0.
	currentByte := 0.
	flashFlag ifTrue: [self nextBits: 2 put: bits - 2].
	stereoFlag
		ifTrue: [
			samples := Array with: leftSoundBuffer with: rightSoundBuffer.
			sampleIndex := Array with: 0 with: 0.
			self privateEncodeStereo: sampleCount]
		ifFalse: [
			samples := leftSoundBuffer.
			sampleIndex := 0.
			self privateEncodeMono: sampleCount].

	^ encodedBytes

]

{ #category : #private }
ADPCMCodec >> headerBitsForSampleCount: sampleCount stereoFlag: stereoFlag [
	"Answer the number of extra header bits required for the given number of samples. This will be zero if I am not using frame headers."

	| frameCount bitsPerHeader |
	frameSizeMask = 0 ifTrue: [^ 0].
	frameCount := (sampleCount / self samplesPerFrame) ceiling.
	bitsPerHeader := 16 + 6.
	stereoFlag ifTrue: [bitsPerHeader := 2 * bitsPerHeader].
	^ frameCount * bitsPerHeader

]

{ #category : #private }
ADPCMCodec >> indexForDeltaFrom: thisSample to: nextSample [
	"Answer the best index to use for the difference between the given samples."
	"Details: Scan stepSizeTable for the first entry >= the absolute value of the difference between sample values. Since indexes are zero-based, the index used during decoding will be the one in the following stepSizeTable entry. Since the index field of a Flash frame header is only six bits, the maximum index value is 63."
	"Note: Since there does not appear to be any documentation of how Flash actually computes the indices used in its frame headers, this algorithm was guessed by reverse-engineering the Flash ADPCM decoder."

	| diff bestIndex |
	self inline: true.

	diff := nextSample - thisSample.
	diff < 0 ifTrue: [diff := 0 - diff].
	bestIndex := 63.
	1 to: 62 do: [:j |
		bestIndex = 63 ifTrue: [
			(stepSizeTable at: j) >= diff ifTrue: [bestIndex := j]]].
	^ bestIndex

]

{ #category : #private }
ADPCMCodec >> initializeForBitsPerSample: sampleBits samplesPerFrame: frameSize [

	self resetForMono.
	stepSizeTable := #(7 8 9 10 11 12 13 14 16 17 19 21 23 25 28 31 34 37 41 45 50 55 60 66 73 80 88 97 107 118 130 143 157 173 190 209 230 253 279 307 337 371 408 449 494 544 598 658 724 796 876 963 1060 1166 1282 1411 1552 1707 1878 2066 2272 2499 2749 3024 3327 3660 4026 4428 4871 5358 5894 6484 7132 7845 8630 9493 10442 11487 12635 13899 15289 16818 18500 20350 22385 24623 27086 29794 32767).

	indexTable := nil.
	sampleBits = 2 ifTrue: [
		indexTable := #(-1 2)].
	sampleBits = 3 ifTrue: [
		indexTable := #(-1 -1 2 4)].
	sampleBits = 4 ifTrue: [
		indexTable := #(-1 -1 -1 -1 2 4 6 8)].
	sampleBits = 5 ifTrue: [
		indexTable := #(-1 -1 -1 -1 -1 -1 -1 -1 1 2 4 6 8 10 13 16)].
	indexTable ifNil: [self error: 'unimplemented bits/sample'].

	bitsPerSample := sampleBits.
	deltaSignMask := 1 bitShift: bitsPerSample - 1.
	deltaValueMask := deltaSignMask - 1.
	deltaValueHighBit := deltaSignMask / 2.

	frameSize <= 1
		ifTrue: [frameSizeMask := 0]
		ifFalse: [
			(frameSize = (1 bitShift: frameSize highBit - 1))
				ifFalse: [self error: 'frameSize must be a power of two'].
			frameSizeMask := frameSize - 1].

	"keep as SoundBuffer to allow fast access from primitive"
	indexTable := SoundBuffer fromArray: indexTable.
	stepSizeTable := SoundBuffer fromArray: stepSizeTable.

]

{ #category : #'bit streaming' }
ADPCMCodec >> nextBits: n [
	"Answer the next n bits of my bit stream as an unsigned integer."

	| result remaining shift |
	self inline: true.

	result := 0.
	remaining := n.
	[true] whileTrue: [
		shift := remaining - bitPosition.
		result := result + (currentByte bitShift: shift).
		shift > 0
			ifTrue: [  "consumed currentByte buffer; fetch next byte"
				remaining := remaining - bitPosition.			
				currentByte := (encodedBytes at: (byteIndex := byteIndex + 1)).
				bitPosition := 8]
			ifFalse: [  "still some bits left in currentByte buffer"
				bitPosition := bitPosition - remaining.
				"mask out the consumed bits:"
				currentByte := currentByte bitAnd: (255 bitShift: (bitPosition - 8)).
				^ result]].

]

{ #category : #'bit streaming' }
ADPCMCodec >> nextBits: n put: anInteger [
	"Write the next n bits to my bit stream."

	| buf bufBits bitsAvailable shift |
	self inline: true.

	buf := anInteger.
	bufBits := n.
	[true] whileTrue: [
		bitsAvailable := 8 - bitPosition.
		shift := bitsAvailable - bufBits.  "either left or right shift"
		"append high bits of buf to end of currentByte:"
		currentByte := currentByte + (buf bitShift: shift).
		shift < 0
			ifTrue: [  "currentByte buffer filled; output it"
				encodedBytes at: (byteIndex := byteIndex + 1) put: currentByte.
				bitPosition := 0.
				currentByte := 0.
				"clear saved high bits of buf:"
				buf := buf bitAnd: (1 bitShift: 0 - shift) - 1.
				bufBits := bufBits - bitsAvailable]
			ifFalse: [  "still some bits available in currentByte buffer"
				bitPosition := bitPosition + bufBits.
				^ self]].

]

{ #category : #private }
ADPCMCodec >> privateDecodeMono: count [

	| delta step predictedDelta bit |
	<primitive: 'primitiveDecodeMono' module: 'ADPCMCodecPlugin'>
	self var: #stepSizeTable declareC: 'short int *stepSizeTable'.
	self var: #indexTable declareC: 'short int *indexTable'.
	self var: #samples declareC: 'short int *samples'.
	self var: #encodedBytes declareC: 'unsigned char *encodedBytes'.

	1 to: count do: [:i |
		(i bitAnd: frameSizeMask) = 1
			ifTrue: [  "start of frame; read frame header"
				predicted := self nextBits: 16.
				predicted > 32767 ifTrue: [predicted := predicted - 65536].
				index := self nextBits: 6.
				samples at: (sampleIndex := sampleIndex + 1) put: predicted]
			ifFalse: [
				delta := self nextBits: bitsPerSample.
				step := stepSizeTable at: index + 1.
				predictedDelta := 0.
				bit := deltaValueHighBit.
				[bit > 0] whileTrue: [
					(delta bitAnd: bit) > 0 ifTrue: [predictedDelta := predictedDelta + step].
					step := step bitShift: -1.
					bit := bit bitShift: -1].
				predictedDelta := predictedDelta + step.

				(delta bitAnd: deltaSignMask) > 0
					ifTrue: [predicted := predicted - predictedDelta]
					ifFalse: [predicted := predicted + predictedDelta].
				predicted > 32767
					ifTrue: [predicted := 32767]
					ifFalse: [predicted < -32768 ifTrue: [predicted := -32768]].

				index := index + (indexTable at: (delta bitAnd: deltaValueMask) + 1).
				index < 0
					ifTrue: [index := 0]
					ifFalse: [index > 88 ifTrue: [index := 88]].

				samples at: (sampleIndex := sampleIndex + 1) put: predicted]].

]

{ #category : #private }
ADPCMCodec >> privateDecodeStereo: count [

	| predictedLeft predictedRight indexLeft indexRight deltaLeft deltaRight
	 stepLeft stepRight predictedDeltaLeft predictedDeltaRight bit |

	<primitive: 'primitiveDecodeStereo' module: 'ADPCMCodecPlugin'>
	self var: #stepSizeTable declareC: 'short int *stepSizeTable'.
	self var: #indexTable declareC: 'short int *indexTable'.
	self var: #samples declareC: 'short int *samples'.
	self var: #encodedBytes declareC: 'unsigned char *encodedBytes'.
	self var: #rightSamples declareC: 'short int *rightSamples'.
	self var: #predicted declareC: 'short int *predicted'.
	self var: #index declareC: 'short int *index'.

	"make local copies of decoder state variables"
	predictedLeft := predicted at: 1.
	predictedRight := predicted at: 2.
	indexLeft := index at: 1.
	indexRight := index at: 2.

	1 to: count do: [:i |
		(i bitAnd: frameSizeMask) = 1
			ifTrue: [  "start of frame; read frame header"
				predictedLeft := self nextBits: 16.
				indexLeft := self nextBits: 6.
				predictedRight := self nextBits: 16.
				indexRight := self nextBits: 6.
				predictedLeft > 32767 ifTrue: [predictedLeft := predictedLeft - 65536].
				predictedRight > 32767 ifTrue: [predictedRight := predictedRight - 65536].
				samples at: (sampleIndex := sampleIndex + 1) put: predictedLeft.
				rightSamples at: sampleIndex put: predictedRight]
			ifFalse: [
				deltaLeft := self nextBits: bitsPerSample.
				deltaRight := self nextBits: bitsPerSample.
				stepLeft := stepSizeTable at: indexLeft + 1.
				stepRight := stepSizeTable at: indexRight + 1.
				predictedDeltaLeft := predictedDeltaRight := 0.
				bit := deltaValueHighBit.
				[bit > 0] whileTrue: [
					(deltaLeft bitAnd: bit) > 0 ifTrue: [
						predictedDeltaLeft := predictedDeltaLeft + stepLeft].
					(deltaRight bitAnd: bit) > 0 ifTrue: [
						predictedDeltaRight := predictedDeltaRight + stepRight].
					stepLeft := stepLeft bitShift: -1.
					stepRight := stepRight bitShift: -1.
					bit := bit bitShift: -1].
				predictedDeltaLeft := predictedDeltaLeft + stepLeft.
				predictedDeltaRight := predictedDeltaRight + stepRight.

				(deltaLeft bitAnd: deltaSignMask) > 0
					ifTrue: [predictedLeft := predictedLeft - predictedDeltaLeft]
					ifFalse: [predictedLeft := predictedLeft + predictedDeltaLeft].
				(deltaRight bitAnd: deltaSignMask) > 0
					ifTrue: [predictedRight := predictedRight - predictedDeltaRight]
					ifFalse: [predictedRight := predictedRight + predictedDeltaRight].
				predictedLeft > 32767
					ifTrue: [predictedLeft := 32767]
					ifFalse: [predictedLeft < -32768 ifTrue: [predictedLeft := -32768]].
				predictedRight > 32767
					ifTrue: [predictedRight := 32767]
					ifFalse: [predictedRight < -32768 ifTrue: [predictedRight := -32768]].

				indexLeft := indexLeft + (indexTable at: (deltaLeft bitAnd: deltaValueMask) + 1).
				indexLeft < 0
					ifTrue: [indexLeft := 0]
					ifFalse: [indexLeft > 88 ifTrue: [indexLeft := 88]].
				indexRight := indexRight + (indexTable at: (deltaRight bitAnd: deltaValueMask) + 1).
				indexRight < 0
					ifTrue: [indexRight := 0]
					ifFalse: [indexRight > 88 ifTrue: [indexRight := 88]].

				samples at: (sampleIndex := sampleIndex + 1) put: predictedLeft.
				rightSamples at: sampleIndex put: predictedRight]].

	"save local copies of decoder state variables"
	predicted at: 1 put: predictedLeft.
	predicted at: 2 put: predictedRight.
	index at: 1 put: indexLeft.
	index at: 2 put: indexRight.

]

{ #category : #private }
ADPCMCodec >> privateEncodeMono: count [

	| step sign diff delta predictedDelta bit p |
	<primitive: 'primitiveEncodeMono' module: 'ADPCMCodecPlugin'>
	self var: #stepSizeTable declareC: 'short int *stepSizeTable'.
	self var: #indexTable declareC: 'short int *indexTable'.
	self var: #samples declareC: 'short int *samples'.
	self var: #encodedBytes declareC: 'unsigned char *encodedBytes'.

	step := stepSizeTable at: 1.
	1 to: count do: [:i |
		(i bitAnd: frameSizeMask) = 1 ifTrue: [
			predicted := samples at: (sampleIndex := sampleIndex + 1).
			(p := predicted) < 0 ifTrue: [p := p + 65536].
			self nextBits: 16 put: p.
			i < count ifTrue: [
				index := self indexForDeltaFrom: predicted to: (samples at: sampleIndex + 1)].
			self nextBits: 6 put: index.
		] ifFalse: [
			"compute sign and magnitude of difference from the predicted sample"
			sign := 0.
			diff := (samples at: (sampleIndex := sampleIndex + 1)) - predicted.
			diff < 0 ifTrue: [
				sign := deltaSignMask.
				diff := 0 - diff].

			"Compute encoded delta and the difference that this will cause in the predicted sample value during decoding. Note that this code approximates:
				delta := (4 * diff) / step.
				predictedDelta := ((delta + 0.5) * step) / 4;
			but in the shift step bits are dropped. Thus, even if you have fast mul/div hardware you cannot use it since you would get slightly different bits what than the algorithm defines."
			delta := 0.
			predictedDelta := 0.
			bit := deltaValueHighBit.
			[bit > 0] whileTrue: [
				diff >= step ifTrue: [
					delta := delta + bit.
					predictedDelta := predictedDelta + step.
					diff := diff - step].
				step := step bitShift: -1.
				bit := bit bitShift: -1].
			predictedDelta := predictedDelta + step.

			"compute and clamp new prediction"
			sign > 0
				ifTrue: [predicted := predicted - predictedDelta]
				ifFalse: [predicted := predicted + predictedDelta].
			predicted > 32767
				ifTrue: [predicted := 32767]
				ifFalse: [predicted < -32768 ifTrue: [predicted := -32768]].

			"compute new index and step values"
			index := index + (indexTable at: delta + 1).
			index < 0
				ifTrue: [index := 0]
				ifFalse: [index > 88 ifTrue: [index := 88]].
			step := stepSizeTable at: index + 1.

			"output encoded, signed delta"
			self nextBits: bitsPerSample put: (sign bitOr: delta)]].

	bitPosition > 0 ifTrue: [  "flush the last output byte, if necessary"
		encodedBytes at: (byteIndex := byteIndex + 1) put: currentByte].

]

{ #category : #private }
ADPCMCodec >> privateEncodeStereo: count [

	<primitive: 'primitiveEncodeStereo' module: 'ADPCMCodecPlugin'>
	"not yet implemented"
	self inline: false.
	self success: false.
]

{ #category : #'codec stuff' }
ADPCMCodec >> reset [

	self resetForMono.

]

{ #category : #'codec stuff' }
ADPCMCodec >> resetForMono [
	"Reset my encoding and decoding state for mono."

	predicted := 0.
	index := 0.

]

{ #category : #'codec stuff' }
ADPCMCodec >> resetForStereo [
	"Reset my encoding and decoding state for stereo."

	"keep state as SoundBuffers to allow fast access from primitive"
	predicted := SoundBuffer new: 2.
	index := SoundBuffer new: 2.

]

{ #category : #'codec stuff' }
ADPCMCodec >> samplesPerFrame [
	"Answer the number of sound samples per compression frame."

	frameSizeMask > 0 ifTrue: [^ frameSizeMask + 1].
	^ 8  "frame size when there are no running headers"

]
