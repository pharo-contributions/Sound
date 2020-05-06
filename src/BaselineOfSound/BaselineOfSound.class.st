Class {
	#name : #BaselineOfSound,
	#superclass : #BaselineOf,
	#category : #BaselineOfSound
}

{ #category : #baselines }
BaselineOfSound >> baseline: spec [ 
	<baseline>
		
	spec for: #pharo do: [
		spec 
			package: 'SoundMorphicExtension';
			package: 'Sound' "with: [ spec requires: 'SoundMorphicExtension' ]" ;
			package: 'Settings-Sound';
			package: 'SoundOgg' with: [ spec requires: 'Sound' ];
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: #('Sound' 'SoundMorphicExtension') ].
			
		"spec postLoadDoIt: #enableSound."
	]
]

{ #category : #baselines }
BaselineOfSound >> enableSound [
	SoundSystem soundEnabled: true
]
