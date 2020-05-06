"
OggDriver is a codec with Ogg container.
The subclasses of OggDriver are responsible for actual internal codec.

Structure:
 state		ByteArray -- holds internal state of the plugin.
 rate		SmallInteger -- sample rate
 channels	SmallInteger -- stereo = 2 or mono = 1
 quality		Float -- codec dependent quality value.
 headerSound OggSoundData -- It keeps the header chunk to remember meta data.

http://www.xiph.org/

"
Class {
	#name : #OggDriver,
	#superclass : #SoundCodec,
	#instVars : [
		'state',
		'rate',
		'channels',
		'quality',
		'headerSound'
	],
	#classVars : [
		'SpeexDefaultQuality',
		'SqOggDecode',
		'SqOggEncode',
		'SqOggError',
		'SqOggErrorHeader',
		'SqOggInitialized',
		'SqOggNeedMore',
		'SqOggRunning',
		'SqOggSuccess',
		'SqSpeex',
		'SqSpeexGotInfo',
		'SqVorbis',
		'SqVorbisGotComment',
		'SqVorbisGotInfo'
	],
	#category : #SoundOgg
}

{ #category : #examples }
OggDriver class >> example [
	"OggDriver example"
	self example1. "Primitive test: Writing Ogg Vorbis."
	self example2. "Primitive test: Reading Ogg Vorbis."
	self example3. "Primitive metatada test: Reading Ogg Vorbis and output to Transcript."
	(Delay forSeconds: 1) wait.
	self example4. "Primitive test: Writing Ogg Speex."
	self example5. "Primitive test: Reading Ogg Speex."
	(Delay forSeconds: 1) wait.
	self example6. "OggVorbisCodec test: Encode and decode with Vorbis."
	(Delay forSeconds: 1) wait.
	self example7. "OggSpeexCodec test: Encode and decode with Speex"
	(Delay forSeconds: 1) wait.
	self example8. "OggSound test: Encode and decode with Vorbis."
	(Delay forSeconds: 1) wait.
	self example9. "OggSound test: Encode and decode with Speex."

]

{ #category : #examples }
OggDriver class >> example1 [
	"OggDriver example1"
	"Primitive test: Writing Ogg Vorbis."
	| driver ogg source size compressed f fileName |
	fileName := 'majorChord.ogg'.
	source := FMSound majorChord asSampledSound.
	driver := self new.
	ogg := driver
				primitiveOpen: (SqVorbis bitOr: SqOggEncode).
	driver primitiveSetChannels: ogg with: 1.
	driver primitiveSetRate: ogg with: 22050.
	driver primitiveSetQuality: ogg with: -0.1.
	driver
		primitiveWrite: ogg
		buffer: source samples
		size: source samples monoSampleCount * 2.
	driver primitiveWriteEOS: ogg.
	size := driver primitiveReadSize: ogg.
	compressed := ByteArray new: size.
	driver
		primitiveRead: ogg
		buffer: compressed
		size: size.
	driver primitiveClose: ogg.
	f := FileDirectory default forceNewFileNamed: fileName.
	[f binary.
	f nextPutAll: compressed]
		ensure: [f close]
]

{ #category : #examples }
OggDriver class >> example2 [
	"OggDriver example2"
	"Primitive test: Reading Ogg Vorbis."
	| f compressed driver ogg decoded size fileName rate |
	fileName := 'majorChord.ogg'.
	f := FileDirectory default readOnlyFileNamed: fileName.
	[f binary.
	compressed := f contents]
		ensure: [f close].
	driver := self new.
	ogg := driver
				primitiveOpen: (SqVorbis bitOr: SqOggDecode).
	driver
		primitiveWrite: ogg
		buffer: compressed
		size: compressed size.
	rate := driver primitiveGetRate: ogg.
	size := driver primitiveReadSize: ogg.
	decoded := SoundBuffer newMonoSampleCount: size // 2.
	driver
		primitiveRead: ogg
		buffer: decoded
		size: size.
	driver primitiveClose: ogg.
	(SampledSound samples: decoded samplingRate: rate) play
]

{ #category : #examples }
OggDriver class >> example3 [
	"OggDriver example3"
	"Primitive metatada test: Reading Ogg Vorbis and output to Transcript."
	| f compressed driver ogg vendor comment commentSize fileName rate channels |
	fileName := 'majorChord.ogg'.
	f := FileDirectory default readOnlyFileNamed: fileName.
	[f binary.
	compressed := f contents]
		ensure: [f close].
	driver := self new.
	ogg := driver
				primitiveOpen: (SqVorbis bitOr: SqOggDecode).
	driver
		primitiveWrite: ogg
		buffer: compressed
		size: compressed size.
	self assert: (driver primitiveGetState: ogg)
			== SqOggRunning.
	rate := driver primitiveGetRate: ogg.
	channels := driver primitiveGetChannels: ogg.
	Transcript cr;
		show: ('Bitstream is {1} channel, {2} Hz' format: {rate. channels}).
	vendor := String new: 1024.
	driver
		primitiveGetVendor: ogg
		buffer: vendor
		size: 1024.
	Transcript cr; show: 'Encoded by:'
			, (vendor readStream
					upTo: (Character value: 0)).
	commentSize := driver primitiveGetCommentSize: ogg.
	comment := String new: commentSize.
	driver
		primitiveGetComment: ogg
		buffer: comment
		size: commentSize.
	Transcript cr; show: comment.
	driver primitiveClose: ogg
]

{ #category : #examples }
OggDriver class >> example4 [
	"OggDriver example4"
	"Primitive test: Writing Ogg Speex."
	| driver ogg source size compressed f fileName |
	fileName := 'majorChord.spx'.
	source := FMSound majorChord asSampledSound.
	driver := self new.
	ogg := driver
				primitiveOpen: (SqSpeex bitOr: SqOggEncode).
	driver primitiveSetChannels: ogg with: 1.
	driver primitiveSetRate: ogg with: 22050.
	driver primitiveSetQuality: ogg with: 4.0.
	driver
		primitiveWrite: ogg
		buffer: source samples
		size: source samples monoSampleCount * 2.
	driver primitiveWriteEOS: ogg.
	size := driver primitiveReadSize: ogg.
	compressed := ByteArray new: size.
	driver
		primitiveRead: ogg
		buffer: compressed
		size: size.
	driver primitiveClose: ogg.
	f := FileDirectory default forceNewFileNamed: fileName.
	[f binary.
	f nextPutAll: compressed]
		ensure: [f close]
]

{ #category : #examples }
OggDriver class >> example5 [
	"OggDriver example5"
	"Primitive test: Reading Ogg Speex."
	| f compressed driver ogg decoded size fileName rate |
	fileName := 'majorChord.spx'.
	f := FileDirectory default readOnlyFileNamed: fileName.
	[f binary.
	compressed := f contents]
		ensure: [f close].
	driver := self new.
	ogg := driver
				primitiveOpen: (SqSpeex bitOr: SqOggDecode).
	driver
		primitiveWrite: ogg
		buffer: compressed
		size: compressed size.
	rate := driver primitiveGetRate: ogg.
	size := driver primitiveReadSize: ogg.
	decoded := SoundBuffer newMonoSampleCount: size // 2.
	driver
		primitiveRead: ogg
		buffer: decoded
		size: size.
	driver primitiveClose: ogg.
	(SampledSound samples: decoded samplingRate: rate) play
]

{ #category : #examples }
OggDriver class >> example6 [
	"OggDriver example6"
	"OggVorbisCodec test: Encode and decode with Vorbis."
	| src buffer codec encoded decoded |
	src := SampledSound soundNamed: 'chirp'.
	buffer := src samples.
	codec := OggVorbisCodec new.
	encoded := codec encodeSoundBuffer: buffer.
	codec release.
	codec := OggVorbisCodec new.
	decoded := codec decodeCompressedData: encoded.
	codec release.
	(SampledSound samples: decoded samplingRate: src originalSamplingRate) play
]

{ #category : #examples }
OggDriver class >> example7 [
	"OggDriver example7"
	"OggSpeexCodec test: Encode and decode with Speex"
	| src buffer codec encoded decoded |
	src := SampledSound soundNamed: 'chirp'.
	buffer := src samples.
	codec := OggSpeexCodec new.
	encoded := codec encodeSoundBuffer: buffer.
	codec release.
	codec := OggSpeexCodec new.
	decoded := codec decodeCompressedData: encoded.
	codec release.
	(SampledSound samples: decoded samplingRate: src originalSamplingRate) play
]

{ #category : #examples }
OggDriver class >> example8 [
	"OggDriver example8"
	"OggSound test: Encode and decode with Vorbis."
	| src compressed |
	src := SampledSound soundNamed: 'croak'.
	compressed := src compressWith: OggVorbisCodec.
	compressed asSound play
]

{ #category : #examples }
OggDriver class >> example9 [
	"OggDriver example9"
	"OggSound test: Encode and decode with Speex."
	| src compressed |
	src := SampledSound soundNamed: 'croak'.
	compressed := src compressWith: OggSpeexCodec.
	compressed asSound play
]

{ #category : #'class initialization' }
OggDriver class >> initialize [
	"self initialize"
	SqOggSuccess := 0.
	SqOggNeedMore := -1.
	SqOggError := -2.
	SqOggErrorHeader := -3.

	SqOggInitialized := 1.
	SqVorbisGotInfo := 2.
	SqSpeexGotInfo := 2.
	SqVorbisGotComment := 3.
	SqOggRunning := 4.

	SqOggEncode := 1.
	SqOggDecode := 2.
	SqVorbis := 4.
	SqSpeex := 8.

	self speexDefaultQuality: 4.0. 
]

{ #category : #accessing }
OggDriver class >> isAvailable [
	"self isAvailable"
	^ self new primitiveVersion > 0
]

{ #category : #'class initialization' }
OggDriver class >> playFileNamed: fileName [ 
	"[self playFileNamed: 'LesVoyages.ogg'] fork"
	| f compressed sound player codec |
	SoundPlayer stopReverb.
	player := QueueSound new.
	player play.
	f := FileDirectory default readOnlyFileNamed: fileName.
	[f binary.
	codec := self new.
	[f atEnd]
		whileFalse: [compressed := f next: 4096.
			sound := codec soundFromCompressedData: compressed.
			sound
				ifNotNil: [player add: sound.
					(Delay forSeconds: sound duration * 0.7) wait]]]
		ensure: [f close.
			codec release]
]

{ #category : #'class initialization' }
OggDriver class >> services [
	| service |
	service := SimpleServiceEntry
				provider: self
				label: 'sound file'
				selector: #playFileNamed:
				description: 'play the sound'
				buttonLabel: 'play'.
	^ Array with: service
]

{ #category : #accessing }
OggDriver class >> speexDefaultQuality: aNumber [ 
	SpeexDefaultQuality := aNumber asFloat
]

{ #category : #accessing }
OggDriver >> channels [
	^ channels
]

{ #category : #accessing }
OggDriver >> channels: aNumber [
	^ channels := aNumber
]

{ #category : #'compress/decompress' }
OggDriver >> compressSound: aSound [ 
	| buffer decoded |
	rate := aSound originalSamplingRate asInteger.
	buffer := self encodeSoundBuffer: aSound samples.
	decoded := OggSoundData source: buffer codecName: self class name.
	headerSound
		ifNil: [headerSound := decoded]
		ifNotNil: [decoded header: headerSound].
	^ decoded
]

{ #category : #'compress/decompress' }
OggDriver >> decodeCompressedData: aByteArray [ 
	"Answer decompressed SoundBuffer, or nil if it needs more data"
	| decoded size result |
	state
		ifNil: [state := self startDecoder].
	result := self
				primitiveWrite: state
				buffer: aByteArray
				size: aByteArray size.
	result = SqOggSuccess
		ifFalse: [self error: 'Compressed data is corrupt'].
	size := self primitiveReadSize: state.
	size = 0
		ifTrue: [^ nil].
	decoded := SoundBuffer newMonoSampleCount: size // 2.
	self
		primitiveRead: state
		buffer: decoded
		size: size.
	self hasHeader
		ifFalse: [self headerComplete].
	^ decoded
]

{ #category : #'compress/decompress' }
OggDriver >> encodeSoundBuffer: samples [ 
	| size encoded |
	state
		ifNil: [state := self startEncoder].
	self
		primitiveWrite: state
		buffer: samples
		size: samples monoSampleCount * 2.
	self primitivePacketFlush: state.
	size := self primitiveReadSize: state.
	encoded := ByteArray new: size.
	self
		primitiveRead: state
		buffer: encoded
		size: size.
	^ encoded
]

{ #category : #accessing }
OggDriver >> hasHeader [
	^ rate notNil
]

{ #category : #'compress/decompress' }
OggDriver >> headerComplete [
	rate := self primitiveGetRate: state.
	channels := self primitiveGetChannels: state
]

{ #category : #primitives }
OggDriver >> primitiveClose: ogg [
	<primitive: 'primitiveClose' module: 'OggPlugin'>
]

{ #category : #primitives }
OggDriver >> primitiveExtractMono: dest src: src size: size channel: channel [
	<primitive: 'primitiveExtractMono' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveGetChannels: ogg [
	<primitive: 'primitiveGetChannels' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveGetComment: ogg buffer: buffer size: size [
	<primitive: 'primitiveGetComment' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveGetCommentSize: ogg [
	<primitive: 'primitiveGetCommentSize' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveGetRate: ogg [
	<primitive: 'primitiveGetRate' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveGetState: ogg [
	<primitive: 'primitiveGetState' module: 'OggPlugin'>
	^ SqOggInitialized
]

{ #category : #primitives }
OggDriver >> primitiveGetVendor: ogg buffer: buffer size: size [
	<primitive: 'primitiveGetVendor' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveOpen: mode [
	<primitive: 'primitiveOpen' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitivePacketFlush: ogg [
	<primitive: 'primitivePacketFlush' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveRead: ogg buffer: buffer size: size [
	<primitive: 'primitiveRead' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveReadSize: ogg [
	<primitive: 'primitiveReadSize' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveSetChannels: ogg with: value [
	<primitive: 'primitiveSetChannels' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveSetQuality: ogg with: value [
	<primitive: 'primitiveSetQuality' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveSetRate: ogg with: value [
	<primitive: 'primitiveSetRate' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveVersion [
	"self new primitiveVersion"
	<primitive: 'primitiveVersion' module: 'OggPlugin'>
	^ 0
]

{ #category : #primitives }
OggDriver >> primitiveWrite: ogg buffer: buffer size: size [
	<primitive: 'primitiveWrite' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #primitives }
OggDriver >> primitiveWriteEOS: ogg [
	<primitive: 'primitiveWriteEOS' module: 'OggPlugin'>
	self primitiveFailed
]

{ #category : #accessing }
OggDriver >> quality [
	^ quality
]

{ #category : #accessing }
OggDriver >> quality: aFloat [
	^ quality := aFloat asFloat
]

{ #category : #accessing }
OggDriver >> rate [
	^ rate
]

{ #category : #accessing }
OggDriver >> rate: aNumber [
	^ aNumber
]

{ #category : #'initialize-release' }
OggDriver >> release [
	state
		ifNotNil: [self primitiveClose: state.
			state := nil].
	rate := nil.
	channels := nil.
	quality := nil.
	headerSound := nil
]

{ #category : #'initialize-release' }
OggDriver >> reset [
	self release
]

{ #category : #'subclass responsibilities' }
OggDriver >> samplesPerFrame [
	^1
]

{ #category : #accessing }
OggDriver >> soundFromCompressedData: aByteArray [ 
	| soundBuffer sound monoCount left right |
	soundBuffer := self decodeCompressedData: aByteArray.
	soundBuffer
		ifNil: [^ nil].
	self channels == 1
		ifTrue: [^ SampledSound samples: soundBuffer samplingRate: self rate].
	self channels == 2
		ifTrue: [sound := MixedSound new.
			monoCount := soundBuffer monoSampleCount // 2.
			left := SoundBuffer newMonoSampleCount: monoCount.
			self
				primitiveExtractMono: left
				src: soundBuffer
				size: monoCount
				channel: 0.
			right := SoundBuffer newMonoSampleCount: monoCount.
			self
				primitiveExtractMono: right
				src: soundBuffer
				size: monoCount
				channel: 1.
			sound
				add: (SampledSound samples: left samplingRate: self rate)
				pan: 0.
			sound
				add: (SampledSound samples: right samplingRate: self rate)
				pan: 1.
			^ sound].
	^ nil
]

{ #category : #'initialize-release' }
OggDriver >> startDecoder [
	self shouldBeImplemented
]

{ #category : #'initialize-release' }
OggDriver >> startEncoder [
	self shouldBeImplemented
]
