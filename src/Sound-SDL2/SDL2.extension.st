Extension { #name : 'SDL2' }

{ #category : '*Sound-SDL2' }
SDL2 class >> dequeueAudio: dev data: data len: len [
	^ self ffiCall: #( int SDL_DequeueAudio(SDL_AudioDeviceID dev, void* data, Uint32 len) )
]
