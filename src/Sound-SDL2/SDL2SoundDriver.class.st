Class {
	#name : #SDL2SoundDriver,
	#superclass : #SoundDriver,
	#pools : [
		'SDL2Constants'
	],
	#category : #'Sound-SDL2'
}

{ #category : #testing }
SDL2SoundDriver class >> isAvailable [
	^ SDL2 isAvailable
]

{ #category : #accessing }
SDL2SoundDriver >> createMainSoundSink [
	^ self createSoundSinkNamed: nil
]

{ #category : #accessing }
SDL2SoundDriver >> createSoundSinkNamed: sinkName [
	| desiredAudioSpec obtainedAudioSpec audioDevice |
	desiredAudioSpec := SDL_AudioSpec new
		freq: self defaultMixerSampleRate;
		format: AUDIO_S16;
		channels: 2;
		samples: self defaultMixerSampleCount;
		yourself.
	obtainedAudioSpec := SDL_AudioSpec new.
	audioDevice := SDL2 openAudioDevice: sinkName isCapture: 0 desired: desiredAudioSpec obtained: obtainedAudioSpec allowedChanges: SDL_AUDIO_ALLOW_FREQUENCY_CHANGE | SDL_AUDIO_ALLOW_SAMPLES_CHANGE.
	audioDevice <= 1 ifTrue: [ ^ self createNullSoundSink ].

	^ SDL2SoundSink new
		audioDevice: audioDevice;
		startMixingProcessWithBufferSize: (obtainedAudioSpec samples // 2 max: self defaultMixerSampleCount) * 2 samplingRate: obtainedAudioSpec freq numchannels: obtainedAudioSpec channels;
		yourself
]

{ #category : #initialization }
SDL2SoundDriver >> initialize [
	super initialize.
	SDL2 initAudio.
]
