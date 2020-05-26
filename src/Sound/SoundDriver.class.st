Class {
	#name : #SoundDriver,
	#superclass : #Object,
	#instVars : [
		'mixerSounds',
		'mixerMutex',
		'mixerSamplingRate',
		'mutex',
		'mainSoundSink'
	],
	#classVars : [
		'CurrentDriver',
		'CurrentDriverSession'
	],
	#category : #'Sound-Driver'
}

{ #category : #'driver selection' }
SoundDriver class >> current [
	"
	self current.
	"
	(CurrentDriver isNil or: [ CurrentDriverSession ~~ Smalltalk session ]) ifTrue: [ 
		CurrentDriver := self pickDriverClass new.
		CurrentDriverSession := Smalltalk session
	].

	^ CurrentDriver
]

{ #category : #'as yet unclassified' }
SoundDriver class >> defaultMixerSampleCount [
	^ 2048
]

{ #category : #'as yet unclassified' }
SoundDriver class >> defaultMixerSampleRate [
	^ 48000
]

{ #category : #testing }
SoundDriver class >> isAvailable [
	^ false
]

{ #category : #testing }
SoundDriver class >> isSuitable [
	^ self isAvailable
]

{ #category : #'driver selection' }
SoundDriver class >> pickDriverClass [
	self subclassesDo: [ :s | s isSuitable ifTrue: [ ^ s ] ].
	^ NullSoundDriver
]

{ #category : #'driver selection' }
SoundDriver class >> reset [
	<script>
	(CurrentDriverSession == Smalltalk session and: [ CurrentDriver isNotNil ]) ifTrue: [ 
		CurrentDriver shutdown.
	].

	CurrentDriver := nil.
]

{ #category : #accessing }
SoundDriver >> createMainSoundSink [
	^ self createNullSoundSink
]

{ #category : #accessing }
SoundDriver >> createNullSoundSink [
	^ NullSoundSink new
		startMixingProcessWithBufferSize: 1024 samplingRate: 11025 numchannels: 1;
		yourself
]

{ #category : #accessing }
SoundDriver >> defaultMixerSampleCount [
	^ self class defaultMixerSampleCount
]

{ #category : #accessing }
SoundDriver >> defaultMixerSampleRate [
	^ self class defaultMixerSampleRate
]

{ #category : #initialization }
SoundDriver >> initialize [
	super initialize.
	mutex := Semaphore forMutualExclusion.
	"We want low latency for sound."
	ProcessorScheduler idleTime: 1000.
]

{ #category : #accessing }
SoundDriver >> mainSoundSink [
	^ mutex critical: [
		mainSoundSink ifNil: [ mainSoundSink := self createMainSoundSink ]
	]
]

{ #category : #accessing }
SoundDriver >> samplingRate [
	^ mixerSamplingRate
]

{ #category : #'as yet unclassified' }
SoundDriver >> shutdown [
	"This is the place for shutting down the driver when a explicit reset is requested"
]
