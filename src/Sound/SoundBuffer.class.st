"
SoundBuffers store 16 bit unsigned quantities.  
"
Class {
	#name : 'SoundBuffer',
	#superclass : 'ArrayedCollection',
	#type : 'words',
	#classVars : [
		'SineTable'
	],
	#category : 'Sound-Core',
	#package : 'Sound',
	#tag : 'Core'
}

{ #category : 'instance creation' }
SoundBuffer class >> averageEvery: nSamples from: anotherBuffer upTo: inCount [

	^(self newMonoSampleCount: inCount // nSamples)
		averageEvery: nSamples 
		from: anotherBuffer 
		upTo: inCount
]

{ #category : 'instance creation' }
SoundBuffer class >> fromArray: anArray [
	"Return a new SoundBuffer whose contents are copied from the given Array or ByteArray."

	| new |
	new := SoundBuffer newMonoSampleCount: anArray size.
	1 to: anArray size do: [:i | new at: i put: (anArray at: i)].
	^ new

]

{ #category : 'instance creation' }
SoundBuffer class >> fromByteArray: aByteArray [
	"Convert the given ByteArray (stored with the most significant byte first) into 16-bit sample buffer."

	| n buf src w |
	n := aByteArray size // 2.
	buf := SoundBuffer newMonoSampleCount: n.
	src := 1.
	1 to: n do: [:i |
		w := ((aByteArray at: src) bitShift: 8) + (aByteArray at: src + 1).
		w > 32767 ifTrue: [w := w - 65536].
		buf at: i put: w.
		src := src + 2].
	^ buf

]

{ #category : 'initialization' }
SoundBuffer class >> initialize [
	"Build a sine wave table."
	"SoundBuffer initialize"

	| tableSize radiansPerStep peak |
	tableSize := 4000.
	SineTable := self newMonoSampleCount: tableSize.
	radiansPerStep := (2.0 * Float pi) / tableSize asFloat.
	peak := ((1 bitShift: 15) - 1) asFloat.  "range is +/- (2^15 - 1)"
	1 to: tableSize do: [:i |
		SineTable at: i put: (peak * (radiansPerStep * (i - 1)) sin) rounded].

]

{ #category : 'instance creation' }
SoundBuffer class >> new: anInteger [
	"See the comment in newMonoSampleCount:. To avoid confusion, it is best to create new instances using newMonoSampleCount: or newStereoSampleCount:."

	^ self newMonoSampleCount: anInteger

]

{ #category : 'instance creation' }
SoundBuffer class >> newMonoSampleCount: anInteger [
	"Return a SoundBuffer large enough to hold the given number of monaural samples (i.e., 16-bit words)."
	"Details: The size is rounded up to an even number, since the underlying representation is in terms of 32-bit words."

	^ self basicNew: (anInteger + 1) // 2

]

{ #category : 'instance creation' }
SoundBuffer class >> newStereoSampleCount: anInteger [
	"Return a SoundBuffer large enough to hold the given number of stereo slices. A stereo 'slice' consists of two 16-bit samples, one for each channel."

	^ self basicNew: anInteger

]

{ #category : 'initialization' }
SoundBuffer class >> sineTable [
	"Answer a SoundBuffer containing one complete cycle of a sine wave."

	^ SineTable

]

{ #category : 'objects from disk' }
SoundBuffer class >> startUp [
	"Check if the word order has changed from the last save."

	| la |
	la := ShortIntegerArray classPool at: #LastSaveOrder.
	((la at: 2) = 42 and: [(la at: 1) = 13]) 
		ifTrue: [^self swapHalves]. "Reverse the two 16-bit halves."
				"Another reversal happened automatically which reversed the bytes."

]

{ #category : 'objects from disk' }
SoundBuffer class >> startUpFrom: anImageSegment [ 
	"In this case, do we need to swap word halves when reading this segment?"

	^SmalltalkImage current endianness ~~ anImageSegment endianness 
		ifTrue: [Message selector: #swapHalves	"will be run on each instance"]
		ifFalse: [nil]
]

{ #category : 'utilities' }
SoundBuffer >> asByteArray [
	"Answer a ByteArray containing my sample data serialized in most-significant byte first order."

	| sampleCount bytes dst s |
	sampleCount := self monoSampleCount.
	bytes := ByteArray new: 2 * sampleCount.
	dst := 0.
	1 to: sampleCount do: [:src |
		s := self at: src.
		bytes at: (dst := dst + 1) put: ((s bitShift: -8) bitAnd: 255).
		bytes at: (dst := dst + 1) put: (s bitAnd: 255)].
	^ bytes

	
]

{ #category : 'primitives' }
SoundBuffer >> at: index [
	"Return the 16-bit integer value at the given index of the receiver."

	<primitive: 143>
	index isInteger ifTrue: [self errorSubscriptBounds: index].
	index isNumber ifTrue: [^ self at: index truncated].
	self errorNonIntegerIndex.

]

{ #category : 'primitives' }
SoundBuffer >> at: index put: value [
	"Store the given 16-bit integer at the given index in the receiver."

	<primitive: 144>
	index isInteger
		ifTrue: [
			(index >= 1 and: [index <= self size])
				ifTrue: [self errorImproperStore]
				ifFalse: [self errorSubscriptBounds: index]].
	index isNumber ifTrue: [^ self at: index truncated put: value].
	self errorNonIntegerIndex.

]

{ #category : 'utilities' }
SoundBuffer >> averageEvery: nSamples from: anotherBuffer upTo: inCount [

	| fromIndex sum |

	fromIndex := 1.
	1 to: inCount // nSamples do: [ :i |
		sum := 0.
		nSamples timesRepeat: [
			sum := sum + (anotherBuffer at: fromIndex).
			fromIndex := fromIndex + 1.
		].
		self at: i put: sum // nSamples.
	].

]

{ #category : 'accessing' }
SoundBuffer >> bytesPerElement [
	"Number of bytes in each item.  This multiplied by (self size)*8 gives the number of bits stored."
	^ 2
]

{ #category : 'utilities' }
SoundBuffer >> downSampledLowPassFiltering: doFiltering [
	"Answer a new SoundBuffer half the size of the receiver consisting of every other sample. If doFiltering is true, a simple low-pass filter is applied to avoid aliasing of high frequencies. Assume that receiver is monophonic."
	"Details: The simple low-pass filter in the current implementation could be improved, at some additional cost."

	| n resultBuf j |
	n := self monoSampleCount.
	resultBuf := SoundBuffer newMonoSampleCount: n // 2.
	j := 0.
	doFiltering
		ifTrue: [
			1 to: n by: 2 do: [:i |
				resultBuf at: (j := j + 1) put:
					(((self at: i) + (self at: i + 1)) bitShift: -1)]]
		ifFalse: [
			1 to: n by: 2 do: [:i |
				resultBuf at: (j := j + 1) put: (self at: i)]].

	^ resultBuf
]

{ #category : 'utilities' }
SoundBuffer >> extractLeftChannel [
	"Answer a new SoundBuffer half the size of the receiver consisting of only the left channel of the receiver, which is assumed to contain stereo sound data."

	| n resultBuf j |
	n := self monoSampleCount.
	resultBuf := SoundBuffer newMonoSampleCount: n // 2.
	j := 0.
	1 to: n by: 2 do: [:i | resultBuf at: (j := j + 1) put: (self at: i)].
	^ resultBuf
]

{ #category : 'utilities' }
SoundBuffer >> extractRightChannel [
	"Answer a new SoundBuffer half the size of the receiver consisting of only the right channel of the receiver, which is assumed to contain stereo sound data."

	| n resultBuf j |
	n := self monoSampleCount.
	resultBuf := SoundBuffer newMonoSampleCount: n // 2.
	j := 0.
	2 to: n by: 2 do: [:i | resultBuf at: (j := j + 1) put: (self at: i)].
	^ resultBuf
]

{ #category : 'utilities' }
SoundBuffer >> indexOfFirstSampleOver: threshold [
	"Return the index of the first sample whose absolute value is over the given threshold value. Return an index one greater than my size if no sample is over the threshold."

	1 to: self size do: [:i |
		(self at: i) abs > threshold ifTrue: [^ i]].
	^ self size + 1
]

{ #category : 'utilities' }
SoundBuffer >> indexOfLastSampleOver: threshold [
	"Return the index of the last sample whose absolute value is over the given threshold value. Return zero if no sample is over the threshold."

	self size to: 1 by: -1 do: [:i |
		(self at: i) abs > threshold ifTrue: [^ i]].
	^ 0

]

{ #category : 'utilities' }
SoundBuffer >> lowPassFiltered [
	"Answer a simple low-pass filtered copy of this buffer. Assume it is monophonic."

	| sz out last this |
	sz := self monoSampleCount.
	out := self copy.
	last := self at: 1.
	2 to: sz do: [:i |
		this := self at: i.
		out at: i put: (this + last) // 2.
		last := this].
	^ out

]

{ #category : 'utilities' }
SoundBuffer >> mergeStereo [
	"Answer a new SoundBuffer half the size of the receiver that mixes the left and right stereo channels of the receiver, which is assumed to contain stereo sound data."

	| n resultBuf j |
	n := self monoSampleCount.
	resultBuf := SoundBuffer newMonoSampleCount: n // 2.
	j := 0.
	1 to: n by: 2 do: [:i | resultBuf at: (j := j + 1) put: (((self at: i) + (self at: i + 1)) // 2)].
	^ resultBuf

]

{ #category : 'accessing' }
SoundBuffer >> monoSampleCount [
	"Return the number of monaural 16-bit samples that fit into this SoundBuffer."

	^ super size * 2

]

{ #category : 'utilities' }
SoundBuffer >> normalized: percentOfFullVolume [
	"Increase my amplitudes so that the highest peak is the given percent of full volume. For example 's normalized: 50' would normalize to half of full volume."

	| peak s mult |
	peak := 0.
	1 to: self size do: [ :i |
		s := (self at: i) abs.
		peak := peak max: s ].
	peak > 0 ifFalse: [ ^ self ].
	mult := 32767.0 * percentOfFullVolume / (10000.0 * peak).
	1 to: self size do: [ :i |
		self at: i put: (mult * (self at: i)) asInteger ]

]

{ #category : 'primitives' }
SoundBuffer >> primFill: aPositiveInteger [
	"Fill the receiver, an indexable bytes or words object, with the given positive integer. The range of possible fill values is [0..255] for byte arrays and [0..(2^32 - 1)] for word arrays."
	"Note: Since 16-bit word arrays are not built into the virtual machine, this primitive fills by 32-bit words."

	<primitive: 145>
	self errorImproperStore.

]

{ #category : 'objects from disk' }
SoundBuffer >> restoreEndianness [
	"This word object was just read in from a stream.  It was stored in Big Endian (Mac) format.  Swap each pair of bytes (16-bit word), if the current machine is Little Endian.
	Why is this the right thing to do?  We are using memory as a byteStream.  High and low bytes are reversed in each 16-bit word, but the stream of words ascends through memory.  Different from a Bitmap."

	| hack blt |
	SmalltalkImage current  isLittleEndian ifTrue: [
		"The implementation is a hack, but fast for large ranges"
		hack := Form new hackBits: self.
		blt := (BitBlt toForm: hack) sourceForm: hack.
		blt combinationRule: Form reverse.  "XOR"
		blt sourceY: 0; destY: 0; height: self size; width: 1.
		blt sourceX: 0; destX: 1; copyBits.  "Exchange bytes 0 and 1"
		blt sourceX: 1; destX: 0; copyBits.
		blt sourceX: 0; destX: 1; copyBits.
		blt sourceX: 2; destX: 3; copyBits.  "Exchange bytes 2 and 3"
		blt sourceX: 3; destX: 2; copyBits.
		blt sourceX: 2; destX: 3; copyBits].


]

{ #category : 'objects from disk' }
SoundBuffer >> reverseEndianness [
	"Swap the bytes of each 16-bit word, using a fast BitBlt hack."

	| hack blt |
	hack := Form new hackBits: self.
	blt := (BitBlt toForm: hack) sourceForm: hack.
	blt combinationRule: Form reverse.  "XOR"
	blt sourceY: 0; destY: 0; height: self size; width: 1.
	blt sourceX: 0; destX: 1; copyBits.  "Exchange bytes 0 and 1"
	blt sourceX: 1; destX: 0; copyBits.
	blt sourceX: 0; destX: 1; copyBits.
	blt sourceX: 2; destX: 3; copyBits.  "Exchange bytes 2 and 3"
	blt sourceX: 3; destX: 2; copyBits.
	blt sourceX: 2; destX: 3; copyBits.

]

{ #category : 'utilities' }
SoundBuffer >> saveAsAIFFFileSamplingRate: rate on: aBinaryStream [
	"Store this mono sound buffer in AIFF file format with the given sampling rate on the given stream."

	| sampleCount s swapBytes |
	sampleCount := self monoSampleCount.
	aBinaryStream nextPutAll: 'FORM' asByteArray.
	aBinaryStream nextInt32Put: (2 * sampleCount) + ((7 * 4) + 18).
	aBinaryStream nextPutAll: 'AIFF' asByteArray.
	aBinaryStream nextPutAll: 'COMM' asByteArray.
	aBinaryStream nextInt32Put: 18.
	aBinaryStream nextNumber: 2 put: 1.  "channels"
	aBinaryStream nextInt32Put: sampleCount.
	aBinaryStream nextNumber: 2 put: 16.  "bits/sample"
	self storeExtendedFloat: rate on: aBinaryStream.
	aBinaryStream nextPutAll: 'SSND' asByteArray.
	aBinaryStream nextInt32Put: (2 * sampleCount) + 8.
	aBinaryStream nextInt32Put: 0.
	aBinaryStream nextInt32Put: 0.

	(aBinaryStream isKindOf: StandardFileStream) ifTrue: [
		"optimization: write sound buffer directly to file"
		swapBytes := SmalltalkImage current  isLittleEndian.
		swapBytes ifTrue: [self reverseEndianness].  "make big endian"
		aBinaryStream next: (self size // 2) putAll: self startingAt: 1.  "size in words"
		swapBytes ifTrue: [self reverseEndianness].  "revert to little endian"
		^ self].

	1 to: sampleCount do: [:i |
		s := self at: i.
		aBinaryStream nextPut: ((s bitShift: -8) bitAnd: 16rFF).
		aBinaryStream nextPut: (s bitAnd: 16rFF)].

]

{ #category : 'accessing' }
SoundBuffer >> size [
	"Return the number of 16-bit sound samples that fit in this sound buffer. To avoid confusion, it is better to get the size of SoundBuffer using monoSampleCount or stereoSampleCount."

	^ self monoSampleCount

]

{ #category : 'utilities' }
SoundBuffer >> splitStereo [
	"Answer an array of two SoundBuffers half the size of the receiver consisting of the left and right channels of the receiver (which is assumed to contain stereo sound data)."

	| n leftBuf rightBuf leftIndex rightIndex |
	n := self monoSampleCount.
	leftBuf := SoundBuffer newMonoSampleCount: n // 2.
	rightBuf := SoundBuffer newMonoSampleCount: n // 2.
	leftIndex := rightIndex := 0.
	1 to: n by: 2 do: [:i |
		leftBuf at: (leftIndex := leftIndex + 1) put: (self at: i).
		rightBuf at: (rightIndex := rightIndex + 1) put: (self at: i + 1)].
	^ Array with: leftBuf with: rightBuf

]

{ #category : 'accessing' }
SoundBuffer >> stereoSampleCount [
	"Return the number of stereo slices that fit into this SoundBuffer. A stereo 'slice' consists of two 16-bit samples, one for each channel."

	^ super size

]

{ #category : 'utilities' }
SoundBuffer >> storeExtendedFloat: aNumber on: aBinaryStream [
	"Store an Apple extended-precision 80-bit floating point number on the given stream."
	"Details: I could not find the specification for this format, so constants were determined empirically based on assumption of 1-bit sign, 15-bit exponent, 64-bit mantissa. This format does not seem to have an implicit one before the mantissa as some float formats do."

	| n isNeg exp mantissa |
	n := aNumber asFloat.
	isNeg := false.
	n < 0.0 ifTrue: [
		n := 0.0 - n.
		isNeg := true].
	exp := (n log: 2.0) ceiling.
	mantissa := (n * (2 raisedTo: 64 - exp)) truncated.
	exp := exp + 16r4000 - 2.  "not sure why the -2 is needed..."
	isNeg ifTrue: [exp := exp bitOr: 16r8000].  "set sign bit"
	aBinaryStream nextPut: ((exp bitShift: -8) bitAnd: 16rFF).
	aBinaryStream nextPut: (exp bitAnd: 16rFF).
	8 to: 1 by: -1 do: [:i | aBinaryStream nextPut: (mantissa digitAt: i)].
]

{ #category : 'converting' }
SoundBuffer >> tfPointerAddress [ 
	^ PointerUtils oopForObjectForcePinInMemory: self
]

{ #category : 'utilities' }
SoundBuffer >> trimmedThreshold: threshold [

	| start end |
	start := self indexOfFirstSampleOver: threshold.
	end :=  self indexOfLastSampleOver: threshold.
	start > end ifTrue: [^ SoundBuffer new].
	start := (start - 200) max: 1.
	end := (end + 200) min: self size.
	^ self copyFrom: start to: end

]

{ #category : 'reading' }
SoundBuffer >> writeOnGZIPByteStream: aStream [ 
	
	aStream nextPutAllWordArray: self
]
