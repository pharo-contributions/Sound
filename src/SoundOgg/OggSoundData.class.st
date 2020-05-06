"
Because vorbis and speex requires statefull encoding, we can't use CompressedSoundData as is. 
CompressedSoundData only remembers its codec class, so it doesn't help to reproduce the original context. 
OggSoundData remembers its header chunk to keep correspond decoder.

Structure:
 decoder			SoundCodec -- decoder instance (only on header sound)
 header			OggSound -- an OggSound including decoder


"
Class {
	#name : #OggSoundData,
	#superclass : #CompressedSoundData,
	#instVars : [
		'decoder',
		'header'
	],
	#category : #SoundOgg
}

{ #category : #'instance creation' }
OggSoundData class >> codecName: aSymbol [
	^ self new codecName: aSymbol.
]

{ #category : #examples }
OggSoundData class >> example1 [
	"OggSoundData example1"
	| source codec sound |
	source := FMSound majorChord asSampledSound.
	sound := SequentialSound new.
	codec := OggVorbisCodec new.
	sound add: (codec compressSound: source).
	sound add: (codec compressSound: source).
	sound add: (codec compressSound: source).
	sound play
]

{ #category : #'instance creation' }
OggSoundData class >> source: aByteArray codecName: aSymbol [ 
	| instance |
	instance := self new.
	instance source: aByteArray.
	instance codecName: aSymbol.
	^ instance
]

{ #category : #converting }
OggSoundData >> asSound [
	| codecClass theDecoder |
	self isHeader
		ifTrue: [codecClass := self class environment
						at: codecName
						ifAbsent: [^ self error: 'The codec for decompressing this sound is not available'].
			codecClass isAvailable
				ifFalse: [^ self error: 'The codec for decompressing this sound is not available'].
			decoder
				ifNotNil: [decoder release].
			theDecoder := decoder := codecClass new]
		ifFalse: [ theDecoder := header decoder ].
	^ theDecoder soundFromCompressedData: channels first
]

{ #category : #accessing }
OggSoundData >> codecName: aSymbol [
	codecName := aSymbol
]

{ #category : #accessing }
OggSoundData >> codecSignature [
	^ self className , ' codecName: ', codecName printString
]

{ #category : #accessing }
OggSoundData >> copy [
	"Don't copy! Because OggSoundData needs correct reference for the
	header, it is just a
	workaround. I'll fix it later. -- takashi"
	^ self
]

{ #category : #accessing }
OggSoundData >> decoder [
	self isHeader
		ifTrue: [^ decoder].
	self error: 'Only header has a decoder.'
]

{ #category : #accessing }
OggSoundData >> header: anOggSoundData [
	header := anOggSoundData
]

{ #category : #accessing }
OggSoundData >> isHeader [
	^ header isNil
]

{ #category : #printing }
OggSoundData >> printOn: aStream [ 
	super printOn: aStream.
	self isHeader
		ifTrue: [aStream nextPutAll: '[header]']
]
