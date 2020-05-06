"
I encode monophonic sampled sounds in Sun audio (.au) file format. Sun audio files have a very simple format but can store both compressed and uncompressed sample data. I can write this format either directly into a file or onto any writable binary stream.

"
Class {
	#name : #SunAudioFileWriter,
	#superclass : #Object,
	#instVars : [
		'stream',
		'headerStart'
	],
	#category : #'Sound-Core'
}

{ #category : #'sound storing' }
SunAudioFileWriter class >> codecForFormatCode: formatCode [
	"Answer the codec for the given Sun audio file format number."

	formatCode = 1 ifTrue: [^ MuLawCodec new].
	formatCode = 3 ifTrue: [^ nil].  "uncompressed"
	formatCode = 23 ifTrue: [^ ADPCMCodec newBitsPerSample: 4].
	formatCode = 25 ifTrue: [^ ADPCMCodec newBitsPerSample: 3].
	formatCode = 26 ifTrue: [^ ADPCMCodec newBitsPerSample: 5].
	formatCode = 610 ifTrue: [^ GSMCodec new].
	self error: 'unsupported Sun audio format'

]

{ #category : #'sound storing' }
SunAudioFileWriter class >> formatCodeForCompressionType: aString [
	"Answer the Sun audio file format number for the given compression type name."

	| lowercase |
	lowercase := aString asLowercase.
	'mulaw' = lowercase ifTrue: [^ 1].
	'none' = lowercase ifTrue: [^ 3].
	'adpcm3' = lowercase ifTrue: [^ 25].
	'adpcm4' = lowercase ifTrue: [^ 23].
	'adpcm5' = lowercase ifTrue: [^ 26].
	'gsm' = lowercase ifTrue: [^ 610].
	self error: 'unknown compression style'

]

{ #category : #'instance creation' }
SunAudioFileWriter class >> onFileNamed: fileName [
	"Answer an instance of me on a newly created file with the given name."

	| file |
	file := (FileStream newFileNamed: fileName) binary.
	^ self new setStream: file

]

{ #category : #'instance creation' }
SunAudioFileWriter class >> onStream: aBinaryStream [
	"Answer an instance of me on the given binary stream."

	^ self new setStream: aBinaryStream

]

{ #category : #'sound storing' }
SunAudioFileWriter class >> storeSampledSound: aSampledSound onFileNamed: fileName compressionType: aString [
	"Store the samples of the given sampled sound on a file with the given name using the given type of compression. See formatCodeForCompressionType: for the list of compression types."

	| fmt codec f compressed |
	fmt := self formatCodeForCompressionType: aString.
	codec := self codecForFormatCode: fmt.
	f := self onFileNamed: fileName.
	f writeHeaderSamplingRate: aSampledSound originalSamplingRate format: fmt.
	codec
		ifNil: [f appendSamples: aSampledSound samples]
		ifNotNil: [
			compressed := codec encodeSoundBuffer: aSampledSound samples.
			f appendBytes: compressed].
	f closeFile.

]

{ #category : #other }
SunAudioFileWriter >> appendBytes: aByteArray [
	"Append the given sample data to my stream."

	stream nextPutAll: aByteArray.

]

{ #category : #other }
SunAudioFileWriter >> appendSamples: aSoundBuffer [
	"Append the given SoundBuffer to my stream."

	| swapBytes s |
	(stream isKindOf: StandardFileStream) ifTrue: [
		"optimization: write sound buffer directly to file"
		swapBytes := SmalltalkImage current  isLittleEndian.
		swapBytes ifTrue: [aSoundBuffer reverseEndianness].  "make big endian"
		stream next: (aSoundBuffer size // 2) putAll: aSoundBuffer startingAt: 1.  "size in words"
		swapBytes ifTrue: [aSoundBuffer reverseEndianness].  "revert to little endian"
		^ self].

	"for non-file streams:"
	s := WriteStream on: (ByteArray new: 2 * aSoundBuffer monoSampleCount).
	1 to: aSoundBuffer monoSampleCount do: [:i | s int16: (aSoundBuffer at: i)].
	self appendBytes: s contents.

]

{ #category : #other }
SunAudioFileWriter >> closeFile [
	"Update the Sun audio file header to reflect the final size of the sound data. If my stream is a file stream, close it and, on a Macintosh, set the file type and creator to that used by SoundApp for Sun Audio files. (This does nothing on other platforms.)"

	self ensureOpen.
	self updateHeaderDataSize.
	(stream isKindOf: StandardFileStream) ifTrue: [
		stream close.
		FilePluginPrims new setMacFileNamed: stream name type: 'ULAW' creator: 'SCPL'].

]

{ #category : #other }
SunAudioFileWriter >> ensureOpen [
	"Ensure that my stream is open."

	stream closed ifTrue: [stream reopen; binary].

]

{ #category : #initialization }
SunAudioFileWriter >> setStream: aBinaryStream [
	"Initialize myself for writing on the given stream."

	stream := aBinaryStream.
	headerStart := aBinaryStream position.

]

{ #category : #other }
SunAudioFileWriter >> updateHeaderDataSize [
	"Update the Sun audio file header to reflect the final size of the sound data."

	| byteCount |
	byteCount := stream position - (headerStart + 24).
	stream position: headerStart + 8.
	stream uint32: byteCount.

]

{ #category : #other }
SunAudioFileWriter >> writeHeaderSamplingRate: samplingRate [
	"Write a Sun audio file header for 16-bit linear format."

	self writeHeaderSamplingRate: samplingRate format: 3.

]

{ #category : #other }
SunAudioFileWriter >> writeHeaderSamplingRate: samplingRate format: audioFormat [
	"Write a Sun audio file header for the given sampling rate and format. Currently, only monophonic files are supported."

	self ensureOpen.
	stream position: headerStart.
	stream nextPutAll: '.snd' asByteArray.
	stream uint32: 24.	"header size in bytes"
	stream uint32: 0.	"sample data size in bytes; fill in later"
	stream uint32: audioFormat.
	stream uint32: samplingRate truncated.
	stream uint32: 1.	"channel count"

]
