"
Just here for archival perspective. 
Just as extracted.
"
Class {
	#name : #OggVorbisCodec,
	#superclass : #OggDriver,
	#category : #SoundOgg
}

{ #category : #'user interface' }
OggVorbisCodec class >> fileReaderServicesForFile: fullName suffix: suffix [ 
	"[self playFileNamed: 'LesVoyages.ogg'] fork"
	^ suffix = 'ogg'
		ifTrue: [self services]
		ifFalse: [#()]
]

{ #category : #'user interface' }
OggVorbisCodec class >> visibleCodecName [
	"Answer a name by which this codec can be known externally."

	^ 'Vorbis'
]

{ #category : #initialization }
OggVorbisCodec >> startDecoder [
	^ self primitiveOpen: (SqVorbis bitOr: SqOggDecode)
]

{ #category : #initialization }
OggVorbisCodec >> startEncoder [
	| s |
	s := self primitiveOpen: (SqVorbis bitOr: SqOggEncode).
	channels := channels
				ifNil: [1].
	rate := rate
				ifNil: [11025].
	quality := quality
				ifNil: [0.0].
	self primitiveSetChannels: s with: channels.
	self primitiveSetRate: s with: rate.
	self primitiveSetQuality: s with: quality.
	^ s
]
