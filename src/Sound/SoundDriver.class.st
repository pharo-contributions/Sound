Class {
	#name : 'SoundDriver',
	#superclass : 'Object',
	#instVars : [
		'mixerSounds',
		'mixerMutex',
		'mixerSamplingRate',
		'mainSoundSink',
		'captureSoundSink',
		'soundMutex',
		'captureMutex'
	],
	#classVars : [
		'CanRecordWhilePlaying',
		'CurrentDriver',
		'CurrentDriverSession'
	],
	#category : 'Sound-Driver',
	#package : 'Sound',
	#tag : 'Driver'
}

{ #category : 'settings' }
SoundDriver class >> canRecordWhilePlaying [
	"Return true if this platform supports simultaneous sound recording and playback."

	^ CanRecordWhilePlaying ifNil: [ true ]
]

{ #category : 'settings' }
SoundDriver class >> canRecordWhilePlaying: aBoolean [
	"Return true if this platform supports simultaneous sound recording and playback."

	CanRecordWhilePlaying := aBoolean
]

{ #category : 'driver selection' }
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

{ #category : 'defaults' }
SoundDriver class >> defaultMixerSampleCount [
	^ 2048
]

{ #category : 'defaults' }
SoundDriver class >> defaultMixerSampleRate [
	^ 48000
]

{ #category : 'initialization' }
SoundDriver class >> initialize [
	SessionManager default
		registerToolClassNamed: self name
]

{ #category : 'testing' }
SoundDriver class >> isAvailable [
	^ false
]

{ #category : 'testing' }
SoundDriver class >> isSuitable [
	^ self isAvailable
]

{ #category : 'testing' }
SoundDriver class >> masterVolumeFindSettingsOn: aBuilder [
	<systemsettings>
	(aBuilder range: #masterVolume)
		target: #SDL2SoundSink;
		label: 'Master Volume' translated;
		description: 'Set the master volume between 0 and 100 percent' translated;
		parent: #soundEnabled;
		default: 100;
		range: (0 to: 100)
]

{ #category : 'driver selection' }
SoundDriver class >> pickDriverClass [
	self subclassesDo: [ :s | s isSuitable ifTrue: [ ^ s ] ].
	^ NullSoundDriver
]

{ #category : 'driver selection' }
SoundDriver class >> reset [
	<script>
	(CurrentDriverSession == Smalltalk session and: [ CurrentDriver isNotNil ]) ifTrue: [ 
		CurrentDriver shutdown.
	].

	CurrentDriver := nil.
]

{ #category : 'system startup' }
SoundDriver class >> shutDown [
	self reset
]

{ #category : 'system startup' }
SoundDriver class >> startUp [
	self reset
]

{ #category : 'accessing' }
SoundDriver >> createMainCaptureSink [
	^ self createNullCaptureSink 
]

{ #category : 'accessing' }
SoundDriver >> createMainSoundSink [
	^ self createNullSoundSink
]

{ #category : 'accessing' }
SoundDriver >> createNullCaptureSink [
	^ NullCaptureSink new
]

{ #category : 'accessing' }
SoundDriver >> createNullSoundSink [
	^ NullSoundSink new
		startMixingProcessWithBufferSize: 1024 samplingRate: 11025 numchannels: 1;
		yourself
]

{ #category : 'accessing' }
SoundDriver >> defaultMixerSampleCount [
	^ self class defaultMixerSampleCount
]

{ #category : 'accessing' }
SoundDriver >> defaultMixerSampleRate [
	^ self class defaultMixerSampleRate
]

{ #category : 'initialization' }
SoundDriver >> initialize [
	super initialize.
	soundMutex := Semaphore forMutualExclusion.
	captureMutex := Semaphore forMutualExclusion.
	"We want low latency for sound."
	ProcessorScheduler idleTime: 1000.
]

{ #category : 'accessing' }
SoundDriver >> mainCaptureSink [
	^ captureMutex critical: [
		captureSoundSink ifNil: [ captureSoundSink := self createMainCaptureSink ]
	]
]

{ #category : 'accessing' }
SoundDriver >> mainSoundSink [
	^ soundMutex critical: [
		mainSoundSink ifNil: [ mainSoundSink := self createMainSoundSink ]
	]
]

{ #category : 'accessing' }
SoundDriver >> samplingRate [
	^ mixerSamplingRate
]

{ #category : 'initialize-destroy' }
SoundDriver >> shutdown [
	"This is the place for shutting down the driver when a explicit reset is requested"
	soundMutex critical: [
		mainSoundSink stopMixingProcess.
		soundMutex terminateProcess.
		mainSoundSink := nil.
		soundMutex := nil.
	].
	captureMutex critical: [  
		captureMutex terminateProcess.
		captureSoundSink := nil.
		captureMutex := nil.
	]
]
