Class {
	#name : #SoundSettings,
	#superclass : #Object,
	#classVars : [
		'SoundEnabled',
		'SoundQuickStart',
		'UseThemeSounds'
	],
	#category : #'Sound-Settings'
}

{ #category : #accessing }
SoundSettings class >> soundQuickStart [
	^ SoundQuickStart ifNil: [SoundQuickStart := false]
]

{ #category : #accessing }
SoundSettings class >> soundQuickStart: aBoolean [
	SoundQuickStart := aBoolean
]

{ #category : #accessing }
SoundSettings class >> useThemeSounds [
	^ UseThemeSounds ifNil: [UseThemeSounds := false]
]

{ #category : #accessing }
SoundSettings class >> useThemeSounds: aBoolean [
	UseThemeSounds := aBoolean
]
