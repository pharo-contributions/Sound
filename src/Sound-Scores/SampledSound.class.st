Class {
	#name : #SampledSound,
	#superclass : #AbstractSound,
	#instVars : [
		'initialCount',
		'count',
		'samples',
		'originalSamplingRate',
		'samplesSize',
		'scaledIndex',
		'indexHighBits',
		'scaledIncrement'
	],
	#classVars : [
		'SoundLibrary',
		'NominalSamplePitch',
		'DefaultSampleTable',
		'ScaledIndexOverflow',
		'IncrementScaleFactor',
		'IncrementFractionBits',
		'CoffeeCupClink'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #'sound library' }
SampledSound class >> addLibrarySoundNamed: aString fromAIFFfileNamed: fileName [
	"Add a sound from the given AIFF file to the library."
	"SampledSound
		addLibrarySoundNamed: 'shutterClick'
		fromAIFFfileNamed: '7.aif'"
	"Add all .aif files in the current directory to the sound library:
	| fileNames |
	fileNames := FileDirectory default fileNamesMatching: '*.aif'.
	fileNames do: [:fName |
		SampledSound
			addLibrarySoundNamed: (fName copyUpTo: $.)
			fromAIFFfileNamed: fName]"

	| snd |
	snd := self fromAIFFfileNamed: fileName.
	self addLibrarySoundNamed: aString
		samples: snd samples
		samplingRate: snd originalSamplingRate.

]

{ #category : #'sound library' }
SampledSound class >> addLibrarySoundNamed: aString samples: sampleData samplingRate: samplesPerSecond [
	"Add the given sound to the sound library. The sample data may be either a ByteArray or a SoundBuffer. If the former, it is take to be 8-bit unsigned samples. If the latter, it is taken to be 16 bit signed samples."

	SoundLibrary
		at: aString
		put: (Array with: sampleData with: samplesPerSecond).

]

{ #category : #'sound library' }
SampledSound class >> assimilateSoundsFrom: aDictionary [
 	"assimilate sounds with new keys from the given dictionary"
 
 	aDictionary associationsDo:
 		[:assoc | (SoundLibrary includesKey: assoc key) ifFalse:
 			[SoundLibrary add: assoc]]
]

{ #category : #'instance creation' }
SampledSound class >> beep [
	"Beep in the presence of the sound system.
	Not to be used directly - use Beeper class>>beep
	or Beeper class>>beepPrimitive instead."

	(self new
			setSamples: self coffeeCupClink
			samplingRate: 12000) play
			
]

{ #category : #'coffee cup clink' }
SampledSound class >> coffeeCupClink [
	"Return the samples array for the sound of a spoon being tapped against a coffee cup."

	CoffeeCupClink ifNil: [self initializeCoffeeCupClink].
	^ CoffeeCupClink

]

{ #category : #utilities }
SampledSound class >> convert8bitSignedFrom: aByteArray to16Bit: aSoundBuffer [
	"Copy the contents of the given array of signed 8-bit samples into the given array of 16-bit signed samples."

	| n s |
	<primitive: 'primitiveConvert8BitSigned' module: 'MiscPrimitivePlugin'>
	self var: #aByteArray declareC: 'unsigned char *aByteArray'.
	self var: #aSoundBuffer declareC: 'unsigned short *aSoundBuffer'.
	n := aByteArray size.
	1 to: n do: [:i |
		s := aByteArray at: i.
		s > 127
			ifTrue: [aSoundBuffer at: i put: ((s - 256) bitShift: 8)]
			ifFalse: [aSoundBuffer at: i put: (s bitShift: 8)]].

]

{ #category : #utilities }
SampledSound class >> convert8bitSignedTo16Bit: aByteArray [
	"Convert the given array of samples--assumed to be 8-bit signed, linear data--into 16-bit signed samples. Return an array containing the resulting samples. Typically used to read uncompressed AIFF sound data."

	| result |
	result := SoundBuffer newMonoSampleCount: aByteArray size.
	self convert8bitSignedFrom: aByteArray to16Bit: result.
	^ result

]

{ #category : #utilities }
SampledSound class >> convert8bitUnsignedTo16Bit: anArray [
	"Convert the given array of samples--assumed to be 8-bit unsigned, linear data--into 16-bit signed samples. Return an array containing the resulting samples. Typically used to read uncompressed WAVE sound data."

	| n samples s |
	n := anArray size.
	samples := SoundBuffer newMonoSampleCount: n.
	1 to: n do: [:i |
		s := anArray at: i.
		samples at: i put: (s - 128 * 256)].
	^ samples

]

{ #category : #utilities }
SampledSound class >> convertBytesTo16BitSamples: aByteArray mostSignificantByteFirst: msbFirst [
	"Convert the given ByteArray (with the given byte ordering) into 16-bit sample buffer."

	| n data src b1 b2 w |
	n := aByteArray size // 2.
	data := SoundBuffer newMonoSampleCount: n.
	src := 1.
	1 to: n do: [:i |
		b1 := aByteArray at: src.
		b2 := aByteArray at: src + 1.
		msbFirst
			ifTrue: [w := (b1 bitShift: 8) + b2]
			ifFalse: [w := (b2 bitShift: 8) + b1].
		w > 32767 ifTrue: [w := w - 65536].
		data at: i put: w.
		src := src + 2].
	^ data

]

{ #category : #'default sound' }
SampledSound class >> defaultSampleTable: anArray [
	"Set the sample table to be used as the default waveform for playing a score such as the Bach fugue. Array is assumed to contain monaural signed 16-bit sample values."

	DefaultSampleTable := SoundBuffer fromArray: anArray.

]

{ #category : #'default sound' }
SampledSound class >> defaultSamples: anArray repeated: n [

	| data |
	data := WriteStream on: (SoundBuffer newMonoSampleCount: anArray size * n).
	n timesRepeat: [
		anArray do: [:sample | data nextPut: sample truncated]].
	DefaultSampleTable := data contents.

]

{ #category : #'instance creation' }
SampledSound class >> fromAIFFfileNamed: fileName [
	"Read a SampledSound from the AIFF file of the given name, merging stereo to mono if necessary."
	"(SampledSound fromAIFFfileNamed: '1.aif') play"
	"| snd |
	 FileDirectory default fileNames do: [:n |
		(n endsWith: '.aif')
			ifTrue: [
				snd := SampledSound fromAIFFfileNamed: n.
				snd play.
				SoundPlayer waitUntilDonePlaying: snd]]."

	| aiffFileReader |
	aiffFileReader := AIFFFileReader new.
	aiffFileReader readFromFile: fileName
		mergeIfStereo: true
		skipDataChunk: false.
	^ self
		samples: (aiffFileReader channelData at: 1)
		samplingRate: aiffFileReader samplingRate

]

{ #category : #'instance creation' }
SampledSound class >> fromWaveFileNamed: fileName [
	"(SampledSound fromWaveFileNamed: 'c:\windows\media\chimes.wav') play"
	"| snd fd |
	fd := FileDirectory on:'c:\windows\media\'.
	fd fileNames do: [:n |
		(n asLowercase endsWith: '.wav')
			ifTrue: [
				snd := SampledSound fromWaveFileNamed: (fd pathName,n).
				snd play.
				SoundPlayer waitUntilDonePlaying: snd]]."

	^self fromWaveStream: (FileStream oldFileNamed: fileName)

]

{ #category : #'instance creation' }
SampledSound class >> fromWaveStream: fileStream [

	| stream header data type channels samplingRate blockAlign bitsPerSample leftAndRight |
	header := self readWaveChunk: 'fmt ' inRIFF: fileStream.
	data := self readWaveChunk: 'data' inRIFF: fileStream.
	fileStream close.
	stream := ReadStream on: header.
	type := self next16BitWord: false from: stream.
	type = 1 ifFalse: [^ self error:'Unexpected wave format'].
	channels := self next16BitWord: false from: stream.
	(channels < 1 or: [channels > 2])
		ifTrue: [^ self error: 'Unexpected number of wave channels'].
	samplingRate := self next32BitWord: false from: stream.
	stream skip: 4. "skip average bytes per second"
	blockAlign := self next16BitWord: false from: stream.
	bitsPerSample := self next16BitWord: false from: stream.
	(bitsPerSample = 8 or: [bitsPerSample = 16])
		ifFalse: [  "recompute bits per sample"
			bitsPerSample := (blockAlign // channels) * 8].

	bitsPerSample = 8
		ifTrue: [data := self convert8bitUnsignedTo16Bit: data]
		ifFalse: [data := self convertBytesTo16BitSamples: data mostSignificantByteFirst: false].

	channels = 2 ifTrue: [
		leftAndRight := data splitStereo.
		^ MixedSound new
			add: (self samples: leftAndRight first samplingRate: samplingRate) pan: 0.0;
			add: (self samples: leftAndRight last samplingRate: samplingRate) pan: 1.0;
			yourself].

	^ self samples: data samplingRate: samplingRate

]

{ #category : #initialization }
SampledSound class >> initialize [
	"SampledSound initialize"

	IncrementFractionBits := 16.
	IncrementScaleFactor := 2 raisedTo: IncrementFractionBits.
	ScaledIndexOverflow := 2 raisedTo: 29.  "handle overflow before needing LargePositiveIntegers"
	self useCoffeeCupClink.
	SoundLibrary ifNil: [SoundLibrary := Dictionary new].
	
	"Beeper setDefault: (self new
						setSamples: self coffeeCupClink
						samplingRate: 12000).
	"
]

{ #category : #'coffee cup clink' }
SampledSound class >> initializeCoffeeCupClink [
	"Initialize the samples array for the sound of a spoon being tapped against a coffee cup."
	"SampledSound initializeCoffeeCupClink"

	| samples |
	samples := #(768 1024 -256 2304 -13312 26624 32512 19200 6400 -256 5888 32512 28928 32512 -32768 32512 -32768 18688 26368 -26112 32512 32512 2304 32512 5632 2816 10240 -4608 -1792 32512 32512 -5376 10752 32512 32512 32512 8192 15872 32512 -3584 -32768 -23296 -24832 -32768 -32768 -32768 -2304 32512 32512 -32768 32512 -15360 6400 8448 -18176 -32768 -256 -32768 -29440 9472 20992 17920 32512 32512 -256 32512 -32768 -32768 -23040 -32768 -25088 -32768 -27648 -1536 24320 -32768 32512 20480 27904 22016 16384 -32768 32512 -27648 -32768 -7168 28160 -6400 5376 32512 -256 32512 -7168 -11776 -19456 -27392 -24576 -32768 -24064 -19456 12800 32512 27136 2048 25344 15616 8192 -4608 -28672 -32768 -30464 -2560 17664 256 -8192 8448 32512 27648 -6144 -512 -7424 -18688 7936 -256 -22272 -14080 2048 27648 15616 -12288 -768 5376 3328 5632 3072 -6656 -20480 10240 27136 -10752 -11008 -768 -2048 6144 -7168 -3584 -1024 -7680 19712 26112 1024 -11008 3072 16384 -8960 -14848 -4864 -23808 -11264 12288 8192 7168 4864 23040 32512 512 -11776 -5632 -16896 -21504 -12800 -6144 -16896 -4352 32512 32512 23296 21760 5632 2816 -9472 -20992 -11264 -29440 -32768 -3584 7680 8448 15360 32512 32512 15616 15104 -2048 -27904 -27904 -25600 -12288 -12032 -13568 17152 22272 15360 30208 28160 7680 -5632 -8192 -16384 -31744 -25856 -10752 -3840 6656 13056 24320 26368 12800 20736 12288 -19200 -20992 -16640 -21504 -17920 -6912 8448 11264 14080 23040 18176 8192 -1024 0 256 -20992 -19712 -4608 -11264 -2048 14080 12032 8192 6912 13056 9216 -5632 -5376 -3840 -6656 -9984 -5632 4864 -3584 -1280 17408 7680 -1280 4096 2816 -1024 -4864 3328 8448 -768 -5888 -2048 5120 0 3072 11008 -7680 -15360 2560 6656 -3840 0 11776 7680 2816 1536 -1280 -3840 -8704 -1536 3584 -9728 -9728 11776 18688 7680 6656 6400 -4864 -3840 -256 -6912 -13312 -11264 2304 9728 1792 3328 18944 18432 6912 6144 -1536 -17664 -14336 -2304 -10496 -15616 -4096 9728 17152 14848 13312 11520 2304 -1024 2560 -8704 -26624 -18688 -256 -256 2816 14080 13824 12544 14080 9728 -512 -12032 -8960 -3328 -9984 -15872 -5120 8192 3584 10496 20224 7936 4608 6144 1280 -8704 -12800 -7424 -8448 -8960 -3840 7424 13056 8704 13312 13056 -2304 -4864 -768 -7168 -10496 -4608 -1536 -3072 -1280 6144 13312 11008 4864 4864 1536 -8960 -7680 1792 -4864 -7680 2816 5632 3328 2560 5376 7936 3584 -512 512 -4608 -9728 0 9216 768 -4096 7680 7168 256 4608 -768 -8704 -6400 2048 6144 -3072 -3328 6400 9472 3840 -768 1792 -3840 -5120 6144 768 -9984 -4352 5120 9472 6912 2816 1792 1280 768 512 -2816 -9728 -6912 6912 6912 -3328 -768 8448 11776 10752 3328 -6912 -10752 -8704 -1536 0 -6912 -3328 9984 13568 7424 6144 6656 256 0 256 -12032 -17920 -8192 3584 8960 4096 5632 12032 8704 6912 5632 -3584 -10496 -7936 -2048 -9216 -11776 2304 9472 15104 14848 5888 512 -2816 1024 2560 -9984 -13312 -5120 768 1792 768 8448 12032 11264 12800 -256 -11264 -9728 -2304 3072 -4352 -6912 256 2304 5376 9984 8192 2816 1280 3584 -2048 -11008 -8448 -2048 3072 4864 2304 3072 3072 3072 7168 3328 -5376 -4864 512 512 -1792 -1792 1792 5376 5888 5888 512 -5888 -3584 4096 3584 -6400 -4864 4608 3072 3840 5376 1024 768 2816 5888 -768 -12288 -7936 2304 5888 3328 2048 6144 3072 3072 6400 -3328 -7168 256 4096 -512 -9472 -6656 3328 6912 9216 8704 3840 -2560 -256 6656 -2560 -11264 -4608 -768 -1280 1536 3072 4096 5120 9984 11264 1024 -8192 -6144 -1024 -3840 -5632 -512 1024 2304 9728 9728 1280 512 4096 2816 -3584 -9984 -6912 -2304 512 5632 7680 3584 1024 5632 5888 -1280 -3584 -2304 -2560 -1536 -1024 -1792 -512 1536 7680 9984 2048 -2048 2048 3328 -1280 -4096 -3328 -4608 -1280 4352 3328 1280 1792 5120 6912 1024 -2560 0 -768 -1024 1280 -256 -4608 -1280 6400 5120 768 1792 2560 2048 0 -1536 -1280 -2304 1024 5376 2560 -2560 -512 4096 2048 512 768 -1280 -256 2560 2560 -256 -1024 768 3584 1280 -3328 -1536 1792 2816 3328 2304 -256 256 2816 2304 -1280 -3328 -1536 2304 2304 -256 -256 1024 1536 3840 5120 1024 -2048 0 1536 -768 -2560 -1792 256 2304 2048 1536 256 768 5888 6656 256 -3840 -2304 -1280 -1536 256 0 -512 2304 4352 3840 768 0 2304 3072 256 -3072 -2560 -2560 256 4608 2560 256 1536 3072 3072 1792 256 256 512 -256 -768 -1280 -1536 768 4352 2816 -512 768 2560 2560 2304 -256 -1792 -768 768 1792 256 -2304 -256 3328 3840 2304 2304 1536 256 2048 1024 -1536 -1792 -1024 512 256 -512 0 2304 4864 5120 4352 1024 -1280 0 -768 -2816 -2304 -512 1024 2048 2304 2048 3072 3840 2816 2048 -512 -3072 -1792 -1536 -1280 768 1280 1536 2304 2816 2048 1536 2048 1536 1536 -768 -3840 -2048 0 1280 2816 1792 1536 2560 3584 2816 1024 256 -768 -768 -1280 -2816 -768 1792 3328 5120 3072 1280 1536 1792 768 -1024 -1280 -1536 -768 512 256 1536 2560 2560 3328 1280 0 768 1536 768 -256 -512 -1536 -1280 768 1280 2304 2560 2560 2560 1024 -256 -512 0 1280 1536 768 -1280 -512 2048 1536 2048 1280 -256 256 512 768 768 1280 2304 1792 512 -1280 -1024 768 1536 1536 256 -768 1536 3584 3072 1792 -256 -1536 -512 256 -512 -512 768 2048 2048 1792 1280 1280 3072 2816 768 -1024 -2304 -1024 256 256 1280 1792 2304 2816 2304 1280 512 1024 768 -768 -1280 -1280 -512 1536 2560 2816 2048 512 1024 1792 1280 768 0 -768 -768 0 256 256 1280 2560 2304 2304 1536 512 512 1024 1280 0 -1792 -1536 -512 1280 3072 2816 1792 512 1024 1536 256 -256 768 768 256 256 -256 512 1280 1280 1536 768 1024 1792 1536 1024 0 256 -512 -256 1024 512 256 768 1792 2304 1280 256 768 1024 1280 1792 768 -768 -768 768 512 256 1024 1792 1536 1280 1536 1792 1280 768 512 -512 -1792 -512 512 768 2304 2816 1792 768 1536 2304 1536 0 -256 -256 -768 -768 256 1536 1536 2304 2048 256 768 2048 2304 1280 0 -256 -1024 -1024 0 1024 1792 2304 2304 1280 512 1280 2048 1280 256 -512 -1792 -1536 256 1536 1792 2048 2048 2048 1536 512 512 768 256 -256 0 -512 -1024 768 2048 2304 2304 1280 1280 1024 1024 1024 0 -512 256 768 0 -256 1536 2304 1792 2304 1280 -512 -256 768 1536 1024 256 512 512 1024 1792 1792 1536 1024 1280 0 -1280 256 2048 2560 2048 1024 -256 -256 1024 1280 1536 1024 0 0 256 768 1792 2304 2048 1280 1024 0 -512 -256 256 1024 1024 512 768 768 1280 2048 1792 1024 768 768 -256 -1024 0 256 1024 1536 1024 1280 1536 1792 1792 1024 512 512 0 -512 -256 512 768 1280 1280 1024 1280 1792 1792 1280 512 -256 -256 256 512 1280 1024 1280 1280 1024 1024 768 1024 1024 1024 1280 256 256 768 768 1024 512 256 768 1280 2560 2560 1280 512 -256 -512 -256 1024 1536 768 1024 1280 768 1024 1536 1536 1024 256 0 0 0 768 768 512 1280 1536 1280 1280 1280 1280 768 768 256 -256 768 768 256 768 1280 1792 1536 1536 1536 256 512 1024 0 -768 -256 768 512 1024 2048 1536 1024 1536 1536 768 0 0 -256).

	CoffeeCupClink := SoundBuffer fromArray: samples.

]

{ #category : #'wav reading' }
SampledSound class >> next16BitWord: msbFirst from: stream [
	"Read a 16-bit positive integer from the input stream."
	"Assume: Stream has at least two bytes left."

	| n |
	n := stream next: 2.
	^msbFirst
		ifTrue:[(n at: 1) * 256 + (n at: 2)]
		ifFalse:[(n at: 2) * 256 + (n at: 1)]

]

{ #category : #'wav reading' }
SampledSound class >> next32BitWord: msbFirst from: stream [
	"Read a 32-bit positive integer from the input stream."
	"Assume: Stream has at least four bytes left."

	| n |
	n := stream next: 4.
	^msbFirst
		ifTrue:[(n at: 1) * 256 + (n at: 2) * 256 + (n at: 3) * 256 + (n at: 4)]
		ifFalse:[(n at: 4) * 256 + (n at: 3) * 256 + (n at: 2) * 256 + (n at: 1)]

]

{ #category : #'default sound' }
SampledSound class >> nominalSamplePitch: aNumber [
	"Record an estimate of the normal pitch of the sampled sound."

	NominalSamplePitch := aNumber.

]

{ #category : #'sound library' }
SampledSound class >> playSoundNamed: aString [
	"Play the sound with given name. Do nothing if there is no sound of that name in the library."
	"SampledSound playSoundNamed: 'croak'"

	| snd |
	snd := self soundNamed: aString.
	snd ifNotNil: [snd play].
	^ snd

]

{ #category : #'sound library' }
SampledSound class >> putCoffeeCupClinkInSoundLibrary [
	"SampledSound putCoffeeCupClinkInSoundLibrary"

	self addLibrarySoundNamed: 'clink'
		samples: self coffeeCupClink
		samplingRate: 11025
]

{ #category : #'wav reading' }
SampledSound class >> readWaveChunk: chunkType inRIFF: stream [
	"Search the stream for a format chunk of the given type and return its contents."

	| id count |
	stream reset; binary.
	stream skip: 8.  "skip 'RIFF' and total length"
	id := (stream next: 4) asString.  "contents type"
	id = 'WAVE' ifFalse: [^ ''].     "content type must be WAVE"

	"search for a chunk of the given type"
	[id := (stream next: 4) asString.
	 count := self next32BitWord: false from: stream.
	 id = chunkType] whileFalse: [
		"skip this chunk, rounding length up to a word boundary"
		stream skip: (count + 1 bitAnd: 16rFFFFFFFE).
		stream atEnd ifTrue: [^ '']].

	^ stream next: count  "return raw chunk data"

]

{ #category : #'sound library' }
SampledSound class >> removeSoundNamed: aString [
	"Remove the sound with the given name from the sound library."

	SoundLibrary removeKey: aString ifAbsent: [].

]

{ #category : #'instance creation' }
SampledSound class >> samples: anArrayOf16BitSamples samplingRate: samplesPerSecond [
	"Return a SampledSound with the given samples array and sampling rate."

	^ self new setSamples: anArrayOf16BitSamples samplingRate: samplesPerSecond

]

{ #category : #'sound library' }
SampledSound class >> soundLibrary [
	"Answer the sound library dictionary."

	^ SoundLibrary

]

{ #category : #'sound library' }
SampledSound class >> soundNamed: aString [
	"Answer the sound of the given name, or, if there is no sound of that name, put up an informer so stating, and answer nil"

	"(SampledSound soundNamed: 'shutterClick') play"

	^ self soundNamed: aString ifAbsent: [Beeper default]
]

{ #category : #'sound library' }
SampledSound class >> soundNamed: aString ifAbsent: aBlock [
	"Answer the sound of the given name, or if there is no sound of that name, answer the result of evaluating aBlock"
	"(SampledSound soundNamed: 'shutterClick') play"

	| entry samples |
	entry := SoundLibrary
		at: aString
		ifAbsent:
			[^ aBlock value].
	entry ifNil: [^ aBlock value].
	samples := entry at: 1.
	samples class isBytes ifTrue: [samples := self convert8bitSignedTo16Bit: samples].
	^ self samples: samples samplingRate: (entry at: 2)

]

{ #category : #'sound library' }
SampledSound class >> soundNames [
	"Answer a list of sound names for the sounds stored in the sound library."
	"| s |
	 SampledSound soundNames asSortedCollection do: [:n |
		n asParagraph display.
		s := SampledSound soundNamed: n.
		s ifNotNil: [s playAndWaitUntilDone]]"

	^ SoundLibrary keys asArray

]

{ #category : #utilities }
SampledSound class >> uLawDecode: aByteArray [
	"Convert the given array of uLaw-encoded 8-bit samples into a SoundBuffer of 16-bit signed samples."

	| n out decodingTable |
	n := aByteArray size.
	out := SoundBuffer newMonoSampleCount: n.
	decodingTable := self uLawDecodeTable.
	1 to: n do: [:i | out at: i put: (decodingTable at: (aByteArray at: i) + 1)].
	^ out

]

{ #category : #utilities }
SampledSound class >> uLawDecodeTable [
	"Return a 256 entry table to be used to decode 8-bit uLaw-encoded samples."
	"Details: This table was computed as follows:
		| d encoded lastEncodedPos lastEncodedNeg |
		d := Array new: 256.
		lastEncodedPos := nil.
		lastEncodedNeg := nil.
		4095 to: 0 by: -1 do: [:s |
			encoded := SampledSound uLawEncodeSample: s.
			lastEncodedPos = encoded
				ifFalse: [
					d at: (encoded + 1) put: (s bitShift: 3).
					lastEncodedPos := encoded].
			encoded := encoded bitOr: 16r80.
			lastEncodedNeg = encoded
				ifFalse: [
					d at: (encoded + 1) put: (s bitShift: 3) negated.
					lastEncodedNeg := encoded]].
		d "

	^ #(32760 31608 30584 29560 28536 27512 26488 25464 24440 23416 22392 21368 20344 19320 18296 17272 16248 15736 15224 14712 14200 13688 13176 12664 12152 11640 11128 10616 10104 9592 9080 8568 8056 7800 7544 7288 7032 6776 6520 6264 6008 5752 5496 5240 4984 4728 4472 4216 3960 3832 3704 3576 3448 3320 3192 3064 2936 2808 2680 2552 2424 2296 2168 2040 1912 1848 1784 1720 1656 1592 1528 1464 1400 1336 1272 1208 1144 1080 1016 952 888 856 824 792 760 728 696 664 632 600 568 536 504 472 440 408 376 360 344 328 312 296 280 264 248 232 216 200 184 168 152 136 120 112 104 96 88 80 72 64 56 48 40 32 24 16 8 0 -32760 -31608 -30584 -29560 -28536 -27512 -26488 -25464 -24440 -23416 -22392 -21368 -20344 -19320 -18296 -17272 -16248 -15736 -15224 -14712 -14200 -13688 -13176 -12664 -12152 -11640 -11128 -10616 -10104 -9592 -9080 -8568 -8056 -7800 -7544 -7288 -7032 -6776 -6520 -6264 -6008 -5752 -5496 -5240 -4984 -4728 -4472 -4216 -3960 -3832 -3704 -3576 -3448 -3320 -3192 -3064 -2936 -2808 -2680 -2552 -2424 -2296 -2168 -2040 -1912 -1848 -1784 -1720 -1656 -1592 -1528 -1464 -1400 -1336 -1272 -1208 -1144 -1080 -1016 -952 -888 -856 -824 -792 -760 -728 -696 -664 -632 -600 -568 -536 -504 -472 -440 -408 -376 -360 -344 -328 -312 -296 -280 -264 -248 -232 -216 -200 -184 -168 -152 -136 -120 -112 -104 -96 -88 -80 -72 -64 -56 -48 -40 -32 -24 -16 -8 0)

]

{ #category : #utilities }
SampledSound class >> uLawEncode: anArray [
	"Convert the given array of 16-bit signed samples into a ByteArray of uLaw-encoded 8-bit samples."

	| n out s |
	n := anArray size.
	out := ByteArray new: n.
	1 to: n do: [:i |
		s := anArray at: i.
		s := s bitShift: -3.  "drop 4 least significant bits"
		s < 0
			ifTrue: [s := (self uLawEncodeSample: s negated) bitOr: 16r80]
			ifFalse: [s := (self uLawEncodeSample: s)].
		out at: i put: s].
	^ out

]

{ #category : #utilities }
SampledSound class >> uLawEncodeSample: s [
	"Encode the given 16-bit signed sample using the uLaw 8-bit encoding."

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

{ #category : #'sound library' }
SampledSound class >> universalSoundKeys [
 	"Answer a list of the sound-names that are expected to be found in the SoundLibrary of every image."
 
 	^ #()
 
 
]

{ #category : #'sound library' }
SampledSound class >> unusedSoundNameLike: desiredName [
	"Pick an unused sound name based on the given string. If necessary, append digits to avoid name conflicts with existing sounds."
	"SampledSound unusedSoundNameLike: 'chirp'"

	| newName i |
	newName := desiredName.
	i := 2.
	[SoundLibrary includesKey: newName] whileTrue: [
		newName := desiredName, i printString.
		i := i + 1].
	^ newName

]

{ #category : #'default sound' }
SampledSound class >> useCoffeeCupClink [
	"Set the sample table to be used as the default waveform to the sound of a coffee cup being tapped with a spoon."
	"SampledSound useCoffeeCupClink bachFugue play"

	DefaultSampleTable := self coffeeCupClink.
	NominalSamplePitch := 400.

]

{ #category : #accessing }
SampledSound >> compressWith: codecClass [
	^ codecClass new compressSound: self
]

{ #category : #accessing }
SampledSound >> compressWith: codecClass atRate: aSamplingRate [

	^ codecClass new compressSound: self atRate: aSamplingRate
]

{ #category : #accessing }
SampledSound >> duration [

	^ initialCount asFloat / self samplingRate asFloat

]

{ #category : #accessing }
SampledSound >> duration: seconds [

	super duration: seconds.
	count := initialCount := (seconds * self samplingRate) rounded.

]

{ #category : #playing }
SampledSound >> endGracefully [
	"See stopGracefully, which affects initialCOunt, and I don't think it should (di)."

	| decayInMs env |
	envelopes isEmpty
		ifTrue: [
			self adjustVolumeTo: 0 overMSecs: 10.
			decayInMs := 10]
		ifFalse: [
			env := envelopes first.
			decayInMs := env attackTime + env decayTime].
	count := decayInMs * self samplingRate // 1000.

]

{ #category : #playing }
SampledSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Mix the given number of samples with the samples already in the given buffer starting at the given index. Assume that the buffer size is at least (index + count) - 1."

	| lastIndex outIndex sampleIndex sample i s overflow |
	<primitive:'primitiveMixSampledSound' module:'SoundGenerationPlugin'>
	self var: #aSoundBuffer declareC: 'short int *aSoundBuffer'.
	self var: #samples declareC: 'short int *samples'.

	lastIndex := (startIndex + n) - 1.
	outIndex := startIndex.    "index of next stereo output sample pair"
	sampleIndex := indexHighBits + (scaledIndex >> IncrementFractionBits).
	[(sampleIndex <= samplesSize) and: [outIndex <= lastIndex]] whileTrue: [
		sample := ((samples at: sampleIndex) * scaledVol) // ScaleFactor.
		leftVol > 0 ifTrue: [
			i := (2 * outIndex) - 1.
			s := (aSoundBuffer at: i) + ((sample * leftVol) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].
		rightVol > 0 ifTrue: [
			i := 2 * outIndex.
			s := (aSoundBuffer at: i) + ((sample * rightVol) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].

		scaledVolIncr ~= 0 ifTrue: [
			scaledVol := scaledVol + scaledVolIncr.
			((scaledVolIncr > 0 and: [scaledVol >= scaledVolLimit]) or:
			 [scaledVolIncr < 0 and: [scaledVol <= scaledVolLimit]])
				ifTrue: [  "reached the limit; stop incrementing"
					scaledVol := scaledVolLimit.
					scaledVolIncr := 0]].

		scaledIndex := scaledIndex + scaledIncrement.
		scaledIndex >= ScaledIndexOverflow ifTrue: [
			overflow := scaledIndex >> IncrementFractionBits.
			indexHighBits := indexHighBits + overflow.
			scaledIndex := scaledIndex - (overflow << IncrementFractionBits)].

		sampleIndex := indexHighBits + (scaledIndex >> IncrementFractionBits).
		outIndex := outIndex + 1].
	count := count - n.

]

{ #category : #accessing }
SampledSound >> originalSamplingRate [

	^ originalSamplingRate

]

{ #category : #initialization }
SampledSound >> pitch: pitchNameOrNumber [

	| p |
	p := self nameOrNumberToPitch: pitchNameOrNumber.
	originalSamplingRate :=
		((self samplingRate asFloat * p asFloat) / NominalSamplePitch asFloat) asInteger.
	self reset.

]

{ #category : #playing }
SampledSound >> playSilentlyUntil: startTime [
	"Used to fast foward to a particular starting time.
	Overridden to be instant for sampled sounds."

"true ifTrue: [^ super playSilentlyUntil: startTime]."
	indexHighBits := (startTime * originalSamplingRate) asInteger.
	scaledIndex := IncrementScaleFactor.
	count := initialCount - (startTime * self samplingRate).
	mSecsSinceStart := (startTime * 1000) asInteger.


]

{ #category : #playing }
SampledSound >> reset [
	"Details: The sample index and increment are scaled to allow fractional increments without having to do floating point arithmetic in the inner loop."

	super reset.
	scaledIncrement :=
		((originalSamplingRate asFloat / self samplingRate) * IncrementScaleFactor) rounded.
	count := initialCount.
	scaledIndex := IncrementScaleFactor.  "index of the first sample, scaled"
	indexHighBits := 0.

]

{ #category : #accessing }
SampledSound >> samples [

	^ samples

]

{ #category : #playing }
SampledSound >> samplesRemaining [

	^ count

]

{ #category : #initialization }
SampledSound >> setPitch: pitchNameOrNumber dur: d loudness: vol [
	"Used to play scores using the default sample table."
	"(SampledSound pitch: 880.0 dur: 1.5 loudness: 0.6) play"

	| p |
	super setPitch: pitchNameOrNumber dur: d loudness: vol.
	p := self nameOrNumberToPitch: pitchNameOrNumber.
	samples := DefaultSampleTable.
	samplesSize := samples size.
	initialCount := (d * self samplingRate asFloat) rounded.
	originalSamplingRate :=
		((self samplingRate asFloat * p asFloat) / NominalSamplePitch asFloat) asInteger.
	self loudness: vol.
	self reset.

]

{ #category : #initialization }
SampledSound >> setSamples: anArray samplingRate: rate [
	"Set my samples array to the given array with the given nominal sampling rate. Altering the rate parameter allows the sampled sound to be played back at different pitches."
	"Note: There are two ways to use sampled sound: (a) you can play them through once (supported by this method) or (b) you can make them the default waveform with which to play a musical score (supported by the class method defaultSampleTable:)."
	"Assume: anArray is either a SoundBuffer or a collection of signed 16-bit sample values."
	"(SampledSound
		samples: SampledSound coffeeCupClink
		samplingRate: 5000) play"

	"copy the array into a SoundBuffer if necessary"
	anArray class isWords
		ifTrue: [samples := anArray]
		ifFalse: [samples := SoundBuffer fromArray: anArray].

	samplesSize := samples size.
	samplesSize >= SmallInteger maxVal ifTrue: [  "this is unlikely..."
		self error: 'sample count must be under ',  SmallInteger maxVal printString].
	originalSamplingRate := rate.
	initialCount := (samplesSize * self samplingRate) // originalSamplingRate.
	self loudness: 1.0.
	self reset.

]

{ #category : #playing }
SampledSound >> setScaledIncrement: aNumber [

	scaledIncrement := (aNumber * IncrementScaleFactor) rounded.


]

{ #category : #'sound tracks' }
SampledSound >> sonogramMorph: height from: start to: stop nPoints: nPoints [
	"FYI:  It is very cool that we can do this, but for sound tracks on a movie,
	simple volume is easier to read, easier to scale, and way faster to compute.
	Code preserved here just in case it makes a useful example."
	"In an inspector of a samplesSound...
		self currentWorld addMorph: (self sonogramMorph: 32 from: 1 to: 50000 nPoints: 256)
	"
	| fft sonogramMorph data width |
	fft := FFT new: nPoints.
	width := stop-start//nPoints.
	sonogramMorph := Sonogram new
			extent: width@height
			minVal: 0.0
			maxVal: 1.0
			scrollDelta: width.
	start to: stop-nPoints by: nPoints do:
		[:i |
		data := fft transformDataFrom: samples startingAt: i.
		data := data collect: [:v | v sqrt].  "square root compresses dynamic range"
		data /= 200.0.
		sonogramMorph plotColumn: data].
	^ sonogramMorph
	

]

{ #category : #playing }
SampledSound >> stopAfterMSecs: mSecs [
	"Terminate this sound this note after the given number of milliseconds."

	count := (mSecs * self samplingRate) // 1000.

]

{ #category : #'file i/o' }
SampledSound >> storeSampleCount: samplesToStore bigEndian: bigEndianFlag on: aBinaryStream [
	"Store my samples on the given stream at the current SoundPlayer sampling rate. If bigFlag is true, then each 16-bit sample is stored most-significant byte first (AIFF files), otherwise it is stored least-significant byte first (WAV files)."

	| reverseBytes |
	self samplingRate ~= originalSamplingRate ifTrue: [
		^ super storeSampleCount: samplesToStore bigEndian: bigEndianFlag on: aBinaryStream].

	"optimization: if sampling rates match, just store my buffer"
	reverseBytes := bigEndianFlag ~= SmalltalkImage current  isBigEndian.
	reverseBytes ifTrue: [samples reverseEndianness].
	(aBinaryStream isKindOf: StandardFileStream)
		ifTrue: [  "optimization for files: write sound buffer directly to file"
			aBinaryStream next: (samples size // 2) putAll: samples startingAt: 1]  "size in words"
		ifFalse: [  "for non-file streams:"
			1 to: samples monoSampleCount do: [:i | aBinaryStream int16: (samples at: i)]].
	reverseBytes ifTrue: [samples reverseEndianness].  "restore to original endianness"

]

{ #category : #'sound tracks' }
SampledSound >> volumeForm: height from: start to: stop nSamplesPerPixel: nPerPixel [
	"Note: nPerPixel can be Integer or Float for pixel-perfect alignment."
	"In an inspector of a samplesSound...
		self currentWorld addMorph: (ImageMorph new image:
			(self volumeForm: 32 from: 1 to: samples size nSamplesPerPixel: 225))
	"
	| volPlot width sample min max vol |
	width := stop-start//nPerPixel.
	volPlot := Form extent: width@height.
	(start max: 1) to: (stop min: samples size)-nPerPixel by: nPerPixel do:
		[:i | min:= max:= 0.
		i asInteger to: (i+nPerPixel-1) asInteger by: 4 do:  "by: 4 makes it faster yet looks the same"
			[:j | sample := samples at: j.
			sample < min ifTrue: [min := sample].
			sample > max ifTrue: [max := sample]].
		vol := (max - min) * height // 65536.
		volPlot fillBlack: ((i-start//nPerPixel) @ (height-vol//2) extent: 1@(vol+1))].
	^ volPlot
	

]
