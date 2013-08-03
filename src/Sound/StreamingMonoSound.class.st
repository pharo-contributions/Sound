"
I implement a streaming player for monophonic Sun (.au) and AIFF (.aif) audio files.
Example of use:
	(StreamingMonoSound onFileNamed: 'song.aif') play.

"
Class {
	#name : #StreamingMonoSound,
	#superclass : #AbstractSound,
	#instVars : [
		'stream',
		'volume',
		'repeat',
		'headerStart',
		'audioDataStart',
		'streamSamplingRate',
		'totalSamples',
		'codec',
		'mixer',
		'leftoverSamples',
		'lastBufferMSecs',
		'mutex'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #'instance creation' }
StreamingMonoSound class >> onFileNamed: fileName [
	"Answer an instance of me for playing the file with the given name."

	| f |
	f := fileName asFileReference.
	f exists ifFalse: [^ self error: 'could not open ', fileName].
	^ self new initStream: f headerStart: 0

]

{ #category : #'instance creation' }
StreamingMonoSound class >> onFileNamed: fileName headerStart: anInteger [
	"Answer an instance of me for playing audio data starting at the given position in the file with the given name."

	| f |
	f := fileName asFileReference.
	f exists ifFalse: [^ self error: 'could not open ', fileName].
	^ self new initStream: f headerStart: anInteger

]

{ #category : #other }
StreamingMonoSound >> closeFile [
	"Close my stream, if it responds to close."

	stream ifNotNil: [
		(stream respondsTo: #close) ifTrue: [stream close]].
	mixer := nil.
	codec := nil.

]

{ #category : #private }
StreamingMonoSound >> createMixer [
	"Create a mixed sound consisting of sampled sounds with one sound buffer's worth of samples."

	| snd |
	mixer := MixedSound new.
	snd := SampledSound
		samples: (SoundBuffer newMonoSampleCount: 2)  "buffer size will be adjusted dynamically"
		samplingRate: streamSamplingRate.
	mixer add: snd pan: 0.5 volume: volume.

]

{ #category : #private }
StreamingMonoSound >> currentSampleIndex [
	"Answer the index of the current sample."

	| bytePosition frameIndex |
	bytePosition := stream position - audioDataStart.
	codec
		ifNil: [^ bytePosition // 2]
		ifNotNil: [
			frameIndex := bytePosition // codec bytesPerEncodedFrame.
			^ (frameIndex * codec samplesPerFrame) - leftoverSamples monoSampleCount].

]

{ #category : #accessing }
StreamingMonoSound >> duration [
	"Answer the duration of this sound in seconds."

	^ totalSamples asFloat / streamSamplingRate

]

{ #category : #other }
StreamingMonoSound >> extractFrom: startSecs to: endSecs [
	"Extract a portion of this sound between the given start and end times. The current implementation only works if the sound is uncompressed."

	| emptySound first last sampleCount byteStream sndBuf |
	codec ifNotNil: [^ self error: 'only works on uncompressed sounds'].
	emptySound := SampledSound samples: SoundBuffer new samplingRate: streamSamplingRate.
	first := (startSecs * streamSamplingRate) truncated max: 0.
	last := ((endSecs * streamSamplingRate) truncated min: totalSamples) - 1.
	first >= last ifTrue: [^ emptySound].
	codec ifNotNil: [self error: 'extracting from compressed sounds is not supported'].
	sampleCount := last + 1 - first.
	stream position: audioDataStart + (2 * first).
	byteStream := ReadStream on: (stream next: 2 * sampleCount).
	sndBuf := SoundBuffer newMonoSampleCount: sampleCount.
	1 to: sampleCount do: [:i | sndBuf at: i put: byteStream int16].
	^ SampledSound samples: sndBuf samplingRate: streamSamplingRate

]

{ #category : #initialization }
StreamingMonoSound >> initStream: aStream headerStart: anInteger [
	"Initialize for streaming from the given stream. The audio file header starts at the given stream position."

	stream := aStream.
	volume := 1.0.
	repeat := false.
	headerStart := anInteger.
	self reset.

]

{ #category : #private }
StreamingMonoSound >> loadBuffer: aSoundBuffer compressedSampleCount: sampleCount [
	"Load the given sound buffer from the compressed sample stream."
	"Details: Most codecs decode in multi-sample units called 'frames'. Since the requested sampleCount is typically not an even multiple of the frame size, we need to deal with partial frames. The unused samples from a partial frame are retained until the next call to this method."

	| n samplesNeeded frameCount encodedBytes r decodedCount buf j |
	"first, use any leftover samples"
	n := self loadFromLeftovers: aSoundBuffer sampleCount: sampleCount.
	samplesNeeded := sampleCount - n.
	samplesNeeded <= 0 ifTrue: [^ self].

	"decode an integral number of full compression frames"
	frameCount := samplesNeeded // codec samplesPerFrame.
	encodedBytes := stream next: (frameCount * codec bytesPerEncodedFrame).
	r := codec decodeFrames: frameCount from: encodedBytes at: 1 into: aSoundBuffer at: n + 1.
	decodedCount := r last.
	decodedCount >= samplesNeeded ifTrue: [^ self].

	"decode one last compression frame to finish filling the buffer"
	buf := SoundBuffer newMonoSampleCount: codec samplesPerFrame.
	encodedBytes := stream next: codec bytesPerEncodedFrame.
	codec decodeFrames: 1 from: encodedBytes at: 1 into: buf at: 1.
	j := 0.
	(n + decodedCount + 1) to: sampleCount do: [:i |
		aSoundBuffer at: i put: (buf at: (j := j + 1))].

	"save the leftover samples"
	leftoverSamples := buf copyFrom: (j + 1) to: buf monoSampleCount.

]

{ #category : #private }
StreamingMonoSound >> loadBuffer: aSoundBuffer uncompressedSampleCount: sampleCount [
	"Load the given sound buffer from the uncompressed sample stream."

	"read directly into the sample buffer; count is in 32-bit words"
	stream next: sampleCount // 2 into: aSoundBuffer startingAt: 1.
	aSoundBuffer restoreEndianness.

	"read the final sample if sampleCount is odd:"
	sampleCount odd ifTrue: [aSoundBuffer at: sampleCount put: stream int16].

]

{ #category : #private }
StreamingMonoSound >> loadBuffersForSampleCount: count [
	"Load the sound buffers from the stream."

	| snd buf sampleCount |
	snd := mixer sounds first.
	buf := snd samples.
	buf monoSampleCount = count ifFalse: [
		buf := SoundBuffer newMonoSampleCount: count.
		snd setSamples: buf samplingRate: streamSamplingRate].
	sampleCount := count min: (totalSamples - self currentSampleIndex).
	sampleCount < count ifTrue: [buf primFill: 0].

	codec
		ifNil: [self loadBuffer: buf uncompressedSampleCount: sampleCount]
		ifNotNil: [self loadBuffer: buf compressedSampleCount: sampleCount].

	mixer reset.

]

{ #category : #private }
StreamingMonoSound >> loadFromLeftovers: aSoundBuffer sampleCount: sampleCount [
	"Load the given sound buffer from the samples leftover from the last frame. Answer the number of samples loaded, which typically is less than sampleCount."

	| leftoverCount n |
	leftoverCount := leftoverSamples monoSampleCount.
	leftoverCount = 0 ifTrue: [^ 0].

	n := leftoverCount min: sampleCount.
	1 to: n do: [:i | aSoundBuffer at: i put: (leftoverSamples at: i)].
	n < sampleCount
		ifTrue: [leftoverSamples := SoundBuffer new]
		ifFalse: [leftoverSamples := leftoverSamples copyFrom: n + 1 to: leftoverSamples size].
	^ n

]

{ #category : #playing }
StreamingMonoSound >> millisecondsSinceStart [
	"Answer the number of milliseconds of this sound started playing."

	| mSecs |
	(stream isNil or: [stream closed]) ifTrue: [^ 0].
	mSecs := self currentSampleIndex * 1000 // streamSamplingRate.
	(self isPlaying and: [lastBufferMSecs > 0]) ifTrue: [
		"adjust mSecs by the milliseconds since the last buffer"
		mutex critical: [
			mSecs := self currentSampleIndex * 1000 // streamSamplingRate.
			mSecs := mSecs + ((Time millisecondClockValue - lastBufferMSecs) max: 0)]].
	^ mSecs + 350 - (2 * SoundPlayer bufferMSecs)

]

{ #category : #playing }
StreamingMonoSound >> playSampleCount: n into: aSoundBuffer startingAt: startIndex [
	"Mix the next n samples of this sound into the given buffer starting at the given index"

	self repeat ifTrue: [  "loop if necessary"
		(totalSamples - self currentSampleIndex) < n ifTrue: [self startOver]].

	mutex critical: [
		lastBufferMSecs := Time millisecondClockValue.
		self loadBuffersForSampleCount: (n * streamSamplingRate) // SoundPlayer samplingRate.
		mixer playSampleCount: n into: aSoundBuffer startingAt: startIndex].

]

{ #category : #private }
StreamingMonoSound >> positionCodecTo: desiredSampleIndex [
	"Position to the closest frame before the given sample index when using a codec. If using the ADPCM codec, try to ensure that it is in sync with the compressed sample stream."

	| desiredFrameIndex desiredPosition tmpStream tmpCodec byteBuf bufFrames sampleBuf frameCount n startOffset |
	(codec isKindOf: ADPCMCodec) ifFalse: [
		"stateless codecs (or relatively stateless ones, like GSM: just jump to frame boundary"
		desiredFrameIndex := desiredSampleIndex // codec samplesPerFrame.
		stream position: audioDataStart + (desiredFrameIndex * codec bytesPerEncodedFrame).
		codec reset.
		^ self].

	"compute the desired stream position"
	desiredFrameIndex := desiredSampleIndex // codec samplesPerFrame.
	desiredPosition := audioDataStart + (desiredFrameIndex * codec bytesPerEncodedFrame).

	"copy stream and codec"
	(stream isKindOf: FileStream)
		ifTrue: [tmpStream := (FileStream readOnlyFileNamed: stream name) binary]
		ifFalse: [tmpStream := stream deepCopy].
	tmpCodec := codec copy reset.

	"reset the codec and start back about 30 seconds to try to get codec in sync"
	startOffset := ((desiredFrameIndex - 80000) max: 0) * codec bytesPerEncodedFrame.
	tmpStream position: audioDataStart + startOffset.

	"decode forward to the desired position"
	byteBuf := ByteArray new: (32000 roundTo: codec bytesPerEncodedFrame).
	bufFrames := byteBuf size // codec bytesPerEncodedFrame.
	sampleBuf := SoundBuffer newMonoSampleCount: bufFrames * codec samplesPerFrame.
	frameCount := (desiredPosition - tmpStream position) // codec bytesPerEncodedFrame.
	[frameCount > 0] whileTrue: [
		n := bufFrames min: frameCount.
		tmpStream next: n * codec bytesPerEncodedFrame into: byteBuf startingAt: 1.
		tmpCodec decodeFrames: n from: byteBuf at: 1 into: sampleBuf at: 1.
		frameCount := frameCount - n].

	codec := tmpCodec.
	stream position: tmpStream position.
	(tmpStream isKindOf: FileStream) ifTrue: [tmpStream close].
]

{ #category : #private }
StreamingMonoSound >> readAIFFHeader [
	"Read an AIFF file header from stream."

	| aiffReader |
	aiffReader := AIFFFileReader new.
	aiffReader readFromStream: stream mergeIfStereo: false skipDataChunk: true.
	aiffReader channelCount = 1 ifFalse: [self error: 'not monophonic'].
	aiffReader bitsPerSample = 16 ifFalse: [self error: 'not 16-bit'].

	audioDataStart := headerStart + aiffReader channelDataOffset.
	streamSamplingRate := aiffReader samplingRate.
	totalSamples := aiffReader frameCount min: (stream size - audioDataStart) // 2.
	codec := nil.

]

{ #category : #private }
StreamingMonoSound >> readHeader [
	"Read the sound file header from my stream."

	| id |
	stream position: headerStart.
	id := (stream next: 4) asString.
	stream position: headerStart.
	id = '.snd' ifTrue: [^ self readSunAudioHeader].
	id = 'FORM' ifTrue: [^ self readAIFFHeader].
	self error: 'unrecognized sound file format'.

]

{ #category : #private }
StreamingMonoSound >> readSunAudioHeader [
	"Read a Sun audio file header from my stream."

	| id headerBytes dataBytes format channelCount |
	id := (stream next: 4) asString.
	headerBytes := stream uint32.  "header bytes"
	dataBytes := stream uint32.
	format := stream uint32.
	streamSamplingRate := stream uint32.
	channelCount := stream uint32.

	id = '.snd' ifFalse: [self error: 'not Sun audio format'].
	dataBytes := dataBytes min: (stream size - headerBytes).
	channelCount = 1 ifFalse: [self error: 'not monophonic'].
	audioDataStart := headerStart + headerBytes.
	codec := nil.
	format = 1 ifTrue: [  "8-bit u-LAW"
		codec := MuLawCodec new.
		totalSamples := dataBytes.
		^ self].
	format = 3 ifTrue: [  "16-bit linear"
		totalSamples := dataBytes // 2.
		^ self].
	format = 23 ifTrue: [  "ADPCM-4 bit (CCITT G.721)"
		codec := ADPCMCodec new
			initializeForBitsPerSample: 4 samplesPerFrame: 0.
		totalSamples := (dataBytes // 4) * 8.
		^ self].
	format = 25 ifTrue: [  "ADPCM-3 bit (CCITT G.723)"
		codec := ADPCMCodec new
			initializeForBitsPerSample: 3 samplesPerFrame: 0.
		totalSamples := (dataBytes // 3) * 8.
		^ self].
	format = 26 ifTrue: [  "ADPCM-5 bit (CCITT G.723)"
		codec := ADPCMCodec new
			initializeForBitsPerSample: 5 samplesPerFrame: 0.
		totalSamples := (dataBytes // 5) * 8.
		^ self].
	format = 610 ifTrue: [  "GSM 06.10 (this format was added by Squeak)"
		codec := GSMCodec new.
		totalSamples := (dataBytes // 33) * 160.
		^ self].
	self error: 'unsupported Sun audio format ', format printString

]

{ #category : #accessing }
StreamingMonoSound >> repeat [
	"Answer the repeat flag."

	^ repeat

]

{ #category : #accessing }
StreamingMonoSound >> repeat: aBoolean [
	"Set the repeat flag. If true, this sound will loop back to the beginning when it gets to the end."

	repeat := aBoolean.

]

{ #category : #playing }
StreamingMonoSound >> reset [

	super reset.
	self startOver.
	self createMixer.

]

{ #category : #playing }
StreamingMonoSound >> samplesRemaining [
	"Answer the number of samples remaining to be played."

	| result |
	(stream isNil or: [stream closed]) ifTrue: [^ 0].
	self repeat ifTrue: [^ 1000000].
	result := (totalSamples - self currentSampleIndex) max: 0.
	result <= 0 ifTrue: [self closeFile].
	^ result

]

{ #category : #converting }
StreamingMonoSound >> saveAsFileNamed: newFileName compressionType: compressionTypeString [
	"Store this sound in a new file with the given name using the given compression type. Useful for converting between compression formats."

	| outFile |
	outFile := (FileStream newFileNamed: newFileName) binary.
	self storeSunAudioOn: outFile compressionType: compressionTypeString.
	outFile close.

]

{ #category : #accessing }
StreamingMonoSound >> soundPosition [
	"Answer the relative position of sound playback as a number between 0.0 and 1.0."

	(stream isNil or: [stream closed]) ifTrue: [^ 0.0].
	^ self currentSampleIndex asFloat / totalSamples

]

{ #category : #accessing }
StreamingMonoSound >> soundPosition: fraction [
	"Jump to the position the given fraction through the sound file. The argument is a number between 0.0 and 1.0."

	| desiredSampleIndex |
	(stream isNil or: [stream closed]) ifTrue: [^ self].
	desiredSampleIndex := ((totalSamples * fraction) truncated max: 0) min: totalSamples.
	codec
		ifNil: [stream position: audioDataStart + (desiredSampleIndex * 2)]
		ifNotNil: [self positionCodecTo: desiredSampleIndex].
	leftoverSamples := SoundBuffer new.

]

{ #category : #private }
StreamingMonoSound >> startOver [
	"Jump back to the first sample."

	stream reopen; binary.
	self readHeader.
	stream position: audioDataStart.
	leftoverSamples := SoundBuffer new.
	lastBufferMSecs := 0.
	mutex := Semaphore forMutualExclusion.

]

{ #category : #converting }
StreamingMonoSound >> storeSunAudioOn: aBinaryStream compressionType: compressionName [
	"Store myself on the given stream as a monophonic sound compressed with the given type of compression. The sampling rate is reduced to 22050 samples/second if it is higher."

	| fmt inBufSize samplesPerFrame outCodec compressed outSamplingRate audioWriter |
	self pause; reset.  "stop playing and return to beginning"

	fmt := SunAudioFileWriter formatCodeForCompressionType: compressionName.
	inBufSize := 64000.
	samplesPerFrame := 1.
	outCodec := SunAudioFileWriter codecForFormatCode: fmt.
	outCodec ifNotNil: [
		samplesPerFrame := outCodec samplesPerFrame.
		inBufSize := inBufSize roundUpTo: (2 * samplesPerFrame).
		compressed := ByteArray new:
			(inBufSize // samplesPerFrame) * outCodec bytesPerEncodedFrame].
	outSamplingRate := streamSamplingRate.
	streamSamplingRate > 22050 ifTrue: [
		streamSamplingRate = 44100 ifFalse: [self error: 'unexpected MP3 sampling rate'].
		outSamplingRate := 22050].

	"write audio header"
	audioWriter := SunAudioFileWriter onStream: aBinaryStream.
	audioWriter writeHeaderSamplingRate: outSamplingRate format: fmt.

	"convert and write sound data"
	'Storing audio...' displayProgressAt: Sensor cursorPoint
		from: 0 to: totalSamples during: [:bar | | outBuf counts inBuf samplesRemaining byteCount |
			samplesRemaining := totalSamples.
			[samplesRemaining > 0] whileTrue: [
				bar value: totalSamples - samplesRemaining.
				self loadBuffersForSampleCount: (inBufSize min: samplesRemaining).
				inBuf := mixer sounds first samples.
				outSamplingRate < streamSamplingRate
					ifTrue: [outBuf := inBuf downSampledLowPassFiltering: true]
					ifFalse: [outBuf := inBuf].
				outCodec
					ifNil: [audioWriter appendSamples: outBuf]
					ifNotNil: [
						counts := outCodec
							encodeFrames: (outBuf size // samplesPerFrame)
							from: outBuf at: 1
							into: compressed at: 1.
						byteCount := counts last.
						byteCount = compressed size
							ifTrue: [audioWriter appendBytes: compressed]
							ifFalse: [audioWriter appendBytes: (compressed copyFrom: 1 to: byteCount)]].
				samplesRemaining := samplesRemaining - inBuf monoSampleCount]].

	"update audio header"
	audioWriter updateHeaderDataSize.

]

{ #category : #accessing }
StreamingMonoSound >> streamSamplingRate [
	"Answer the sampling rate of the MP3 stream."

	^ streamSamplingRate

]

{ #category : #accessing }
StreamingMonoSound >> volume [
	"Answer my volume."

	^ volume

]

{ #category : #accessing }
StreamingMonoSound >> volume: aNumber [
	"Set my volume to the given number between 0.0 and 1.0."

	volume := aNumber.
	self createMixer.

]
