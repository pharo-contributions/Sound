Class {
	#name : #BaselineOfSound,
	#superclass : #BaselineOf,
	#category : #BaselineOfSound
}

{ #category : #baselines }
BaselineOfSound >> baseline61: spec [ 
	<version: '6.1-baseline'>
		
	spec for: #pharo do: [
		spec blessing: #baseline.
		spec description: 'Adding post doit to enable sound'.
		spec repository: 'http://smalltalkhub.com/mc/PharoExtras/Sound/main'.
		spec 
			package: 'SoundMorphicExtension';
			package: 'Sound' "with: [ spec requires: 'SoundMorphicExtension' ]" ;
			package: 'Settings-Sound';
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: #('Sound' 'SoundMorphicExtension') ].
			
		spec postLoadDoIt: #enableSound.
	]
]

{ #category : #baselines }
BaselineOfSound >> baseline: spec [ 
	<baseline>
		
	spec for: #pharo do: [
		spec 
			package: 'SoundMorphicExtension';
			package: 'Sound' "with: [ spec requires: 'SoundMorphicExtension' ]" ;
			package: 'Settings-Sound';
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: #('Sound' 'SoundMorphicExtension') ].
			
		spec postLoadDoIt: #enableSound.
	]
]
