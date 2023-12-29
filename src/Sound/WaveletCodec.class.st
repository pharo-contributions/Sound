"
The Wavelet codec performs a wavelet transform on the original data.  It then achieves its compression by thresholding the transformed data, converting all values below a given magnitude to zero, and then run-coding the resulting data.  The run-coding provides automatic variable compression depending on the parameters chosen.

As is, this codec achieves reasonable reproduction at 10:1 compression, although the quality from the GSMCodec is definitely better.  I feel that the quality would be comparable if uLaw scaling were introduced prior to thresholding.

The nice thing about using wavelets is there are numerous factors to play with for better performance:
	nLevels - the ""order"" of the transform performed
	alpha and beta - these specify the wavelet shape (some are better for speech)
	the actual threshold used
By simply changing these parameters, one can easily vary the compression achieved from 5:1 to 50:1, and listen to the quality at each step.

The specific format for an encoded buffer is as follows:
	4 bytes: frameCount.
	4 bytes: samplesPerFrame.
	4 bytes: nLevels.
	4 bytes: alpha asIEEE32BitWord.
	4 bytes: beta asIEEE32BitWord.
	frameCount occurrences of...
		2 bytes: frameSize in bytes, not including these 2
			may be = 0 for complete silence, meaning no scale even.
		4 bytes: scale asIEEE32BitWord.
		A series of 1- or 2-byte values encoded as follows:
			0-111: 	a run of N+1 consecutive 0's;
			112-127:	a run of (N-112)*256 + nextByte + 1 consecutive 0's;
			128-255:	a 15-bit signed value = (N*256 + nextByte) - 32768 - 16384.
"
Class {
	#name : 'WaveletCodec',
	#superclass : 'SoundCodec',
	#instVars : [
		'fwt',
		'samplesPerFrame',
		'nLevels',
		'alpha',
		'beta'
	],
	#category : 'Sound-Core',
	#package : 'Sound',
	#tag : 'Core'
}

{ #category : 'subclass responsibilities' }
WaveletCodec >> bytesPerEncodedFrame [
	"Answer the number of bytes required to hold one frame of compressed sound data. Answer zero if this codec produces encoded frames of variable size."

	^ 0

]

{ #category : 'subclass responsibilities' }
WaveletCodec >> decodeFrames: frameCount from: srcByteArray at: srcIndex into: dstSoundBuffer at: dstIndex [
	"Decode the given number of monophonic frames starting at the given index in the given ByteArray of compressed sound data and storing the decoded samples into the given SoundBuffer starting at the given destination index. Answer a pair containing the number of bytes of compressed data consumed and the number of decompressed samples produced."
	"Note: Assume that the sender has ensured that the given number of frames will not exhaust either the source or destination buffers."

	| frameBase coeffArray scale i c nullCount samples sourceFrameEnd frameSize inStream val |
	inStream := ReadStream on: srcByteArray from: srcIndex to: srcByteArray size.
	"frameCount := " inStream nextNumber: 4.
	samplesPerFrame := inStream nextNumber: 4.
	nLevels := inStream nextNumber: 4.
	alpha := Float fromIEEE32Bit: (inStream nextNumber: 4).
	beta := Float fromIEEE32Bit: (inStream nextNumber: 4).
	fwt ifNil:
		["NOTE: This should read parameters from the encoded data"
		fwt := FWT new.
		fwt nSamples: samplesPerFrame nLevels: nLevels.
		fwt setAlpha: alpha beta: beta].
	frameBase := dstIndex.
	coeffArray := fwt coeffs.  "A copy that we can modify"

	1 to: frameCount do:
		[:frame | 

		"Decode the scale for this frame"
		frameSize := inStream nextNumber: 2.
		sourceFrameEnd := frameSize + inStream position.
		scale := Float fromIEEE32Bit: (inStream nextNumber: 4).

		"Expand run-coded samples to scaled float values."
		i := 5.
		[i <= coeffArray size]
			whileTrue:
			[c := inStream next.
			c < 128
				ifTrue: [nullCount := c < 112
							ifTrue: [c + 1]
							ifFalse: [(c-112)*256 + inStream next + 1].
						i to: i + nullCount - 1 do: [:j | coeffArray at: j put: 0.0].
						i := i + nullCount]
				ifFalse: [val := (c*256 + inStream next) - 32768 - 16384.
						coeffArray at: i put: val * scale.
						i := i + 1]].

		"Copy float values into the wavelet sample array"		
			fwt coeffs: coeffArray.

		"Compute the transform"
		fwt transformForward: false.

		"Determine the scale for this frame"
		samples := fwt samples.
		samples size = samplesPerFrame ifFalse: [self error: 'frame size error'].
		1 to: samples size do:
			[:j | dstSoundBuffer at: frameBase + j - 1 put: (samples at: j) asInteger].

		inStream position = sourceFrameEnd ifFalse: [self error: 'frame size error'].
		frameBase := frameBase + samplesPerFrame].

	^ Array with: inStream position + 1 - srcIndex
			with: frameBase - dstIndex
]

{ #category : 'subclass responsibilities' }
WaveletCodec >> encodeFrames: frameCount from: srcSoundBuffer at: srcIndex into: dstByteArray at: dstIndex [
	"Encode the given number of frames starting at the given index in the given monophonic SoundBuffer and storing the encoded sound data into the given ByteArray starting at the given destination index. Encode only as many complete frames as will fit into the destination. Answer a pair containing the number of samples consumed and the number of bytes of compressed data produced."
	"Note: Assume that the sender has ensured that the given number of frames will not exhaust either the source or destination buffers."

	| frameBase coeffs maxVal minVal c scale nullCount frameI outFrameSize threshold sm outStream cMin val |
	threshold := 2000.
	fwt ifNil:
		[samplesPerFrame := self samplesPerFrame.
		nLevels := 8.
		"Here are some sample mother wavelets, with the compression achieved on a
		sample of my voice at a threshold of 2000:
									compression achieved "
		alpha := 0.0.  beta := 0.0.		"12.1"
		alpha := 1.72.  beta := 1.51.	"14.0"
		alpha := -1.86.  beta := -1.53.	"14.4"
		alpha := 1.28.  beta := -0.86.	"15.9"
		alpha := -1.15.  beta := 0.69.	"16.0"
		fwt := FWT new.
		fwt nSamples: samplesPerFrame nLevels: nLevels.
		fwt setAlpha: alpha beta: beta].

	(outStream := WriteStream on: dstByteArray from: dstIndex to: dstByteArray size)
		nextNumber: 4 put: frameCount;
		nextNumber: 4 put: samplesPerFrame;
		nextNumber: 4 put: nLevels;
		nextNumber: 4 put: alpha asIEEE32BitWord;
		nextNumber: 4 put: beta asIEEE32BitWord.
	frameBase := srcIndex.
	1 to: frameCount do:
		[:frame | 

		"Copy float values into the wavelet sample array"		
		fwt samples: ((frameBase to: frameBase + samplesPerFrame-1) 
				collect: [:i | (srcSoundBuffer at: i) asFloat]).

		"Compute the transform"
		fwt transformForward: true.

		frameI := outStream position+1.  "Reserve space for frame size"
		outStream nextNumber: 2 put: 0.

		"Determine and output the scale for this frame"
		coeffs := fwt coeffs.
		maxVal := 0.0.  minVal := 0.0.
		5 to: coeffs size do:
			[:i | c := coeffs at: i.
			c > maxVal ifTrue: [maxVal := c].
			c < minVal ifTrue: [minVal := c]].
		scale := (maxVal max: minVal negated) / 16000.0.  "Will scale all to -16k..16k: 15 bits"
		outStream nextNumber: 4 put: scale asIEEE32BitWord.

		"Copy scaled values, with run-coded sequences of 0's, to destByteArray"
		nullCount := 0.
		cMin := threshold / scale.
		5 to: coeffs size do:
			[:i | c := (coeffs at: i) / scale.
			c abs < cMin
			ifTrue: ["Below threshold -- count nulls."
					nullCount := nullCount + 1]
			ifFalse: ["Above threshold -- emit prior null count and this sample."
					nullCount > 0 ifTrue:
						[nullCount <= 112
						ifTrue: [outStream nextNumber: 1 put: nullCount-1]
						ifFalse: [outStream nextNumber: 2 put: (112*256) + nullCount-1].
						nullCount := 0].
						val := c asInteger + 16384 + 32768.  "Map -16k..16k into 32k..64k"
						outStream nextNumber: 2 put: val]].

					nullCount > 0 ifTrue:
						[nullCount <= 112
						ifTrue: [outStream nextNumber: 1 put: nullCount-1]
						ifFalse: [outStream nextNumber: 2 put: (112*256) + nullCount-1]].
		outFrameSize := outStream position+1 - frameI - 2.  "Write frame size back at the beginning"
		(WriteStream on: dstByteArray from: frameI to: dstByteArray size)
			nextNumber: 2 put: outFrameSize.
		frameBase := frameBase + samplesPerFrame].

"This displays a temporary indication of compression achieved"
sm := TextMorph new contents: (((frameBase - srcIndex) *2.0 / (outStream position+1 - dstIndex) truncateTo: 0.1) printString , ' : 1') asText allBold.
sm position: Sensor cursorPoint + (-20@30).
ActiveWorld addMorph: sm.
World doOneCycleNow.
sm delete.

	outStream position > dstByteArray size ifTrue:
		["The calling routine only provides buffer space for compression of 2:1 or better.  If you are just testing things, you can increase it to, eg, codeFrameSize := frameSize*3, which would be sufficient for a threshold of 0 (lossless conversion)."
		self error: 'Buffer overrun'].

	^ Array with: frameBase - srcIndex
			with: outStream position+1 - dstIndex
]

{ #category : 'subclass responsibilities' }
WaveletCodec >> frameCount: aByteArray [
	"Compute the frame count for this byteArray.  This default computation will have to be overridden by codecs with variable frame sizes."

	^ (ReadStream on: aByteArray) nextNumber: 4.

]

{ #category : 'subclass responsibilities' }
WaveletCodec >> samplesPerFrame [
	"Answer the number of sound samples per compression frame."

	^ 4096

]
