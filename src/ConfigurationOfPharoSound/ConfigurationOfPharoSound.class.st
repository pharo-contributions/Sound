Class {
	#name : #ConfigurationOfPharoSound,
	#superclass : #Object,
	#instVars : [
		'project'
	],
	#classVars : [
		'LastVersionLoad'
	],
	#category : #ConfigurationOfPharoSound
}

{ #category : #private }
ConfigurationOfPharoSound class >> bootstrapPackage: aString from: aPath [ 
	| repository version |
	repository := MCHttpRepository
				location: aPath
				user: ''
				password: ''.
	repository
		versionReaderForFileNamed: aString , '.mcz'
		do: [:reader | 
			version := reader version.
			version load.
			version workingCopy repositoryGroup addRepository: repository]
]

{ #category : #private }
ConfigurationOfPharoSound class >> ensureMetacello [
	"Bootstrap Gofer (if necessary), bootstrap ConfigurationOfMetacello (using old Gofer API), then load the latest 
	version of Metacello itself."

	Smalltalk at: #MetacelloProject ifAbsent: [
		Smalltalk at: #Gofer ifAbsent: [
			"Current version of Gofer from which to bootstrap - as of 1.0-beta.15"
			self bootstrapPackage: 'Gofer-lr.83' from: 'http://seaside.gemstone.com/ss/metacello' ].
		Smalltalk at: #Gofer ifPresent: [:goferClass | | gofer |
			gofer := goferClass new
				url: 'http://seaside.gemstone.com/ss/metacello';
				yourself.
			[ gofer addPackage: 'ConfigurationOfMetacello' ] on: Warning do: [:ex | ex resume ].
			gofer load ].
		"load latest version of Metacello, load a specific version if desired"
		(Smalltalk at: #ConfigurationOfMetacello) perform: #loadLatestVersion ]
]

{ #category : #'metacello tool support' }
ConfigurationOfPharoSound class >> isMetacelloConfig [
	"Answer true and the Metacello tools will operate on you"
	
	^true
]

{ #category : #'metacello tool support' }
ConfigurationOfPharoSound class >> lastMetacelloVersionLoad [
	"Answer the last version loaded and the list of packages loaded for that version."

	LastVersionLoad == nil ifTrue: [ LastVersionLoad := nil -> 'default' ].
	^LastVersionLoad
]

{ #category : #'metacello tool support' }
ConfigurationOfPharoSound class >> metacelloVersion: versionString loads: anArrayOrString [
	"Stash the last version loaded and the list of packages loaded for that version. The list
	 of packages will be used by the tools when doing 'Load Package Version'"

	LastVersionLoad := versionString -> anArrayOrString
]

{ #category : #accessing }
ConfigurationOfPharoSound class >> project [

	^self new project
]

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline10: spec [ 
	<version: '1.0-baseline'>
	
	spec for: #common do: [
		spec blessing: #baseline.
	].	
		
	spec for: #pharo do: [
		spec repository: 'http://www.squeaksource.com/PharoNonCorePackages'.
		spec 
			package: 'Sound';
			package: 'SoundMorphicUserInterface' with: [ spec requires: 'Sound' ].
			
	]
]

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline30: spec [ 
	<version: '3.0-baseline'>
	
	spec for: #common do: [
		spec blessing: #baseline.
	].	
		
	spec for: #pharo do: [
		spec repository: 'http://www.squeaksource.com/PharoSound'.
		spec 
			package: 'Sound';
			package: 'Collections-Arithmetic' with: [ spec repository: 'http://www.squeaksource.com/CollectionArithmetic' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: 'Sound'; requires: 'Collections-Arithmetic' ].
			
	]
]

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline40: spec [ 
	<version: '4.0-baseline'>
	
	spec for: #common do: [
		spec blessing: #baseline.
	].	
		
	spec for: #pharo do: [
		spec repository: 'http://www.squeaksource.com/PharoSound'.
		spec 
			package: 'Sound';
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'Collections-Arithmetic' with: [ spec repository: 'http://www.squeaksource.com/CollectionArithmetic' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: 'Sound'; requires: 'Collections-Arithmetic' ].
			
	]
]

{ #category : #accessing }
ConfigurationOfPharoSound >> project [

	^ project ifNil: [ | constructor |
		"Bootstrap Metacello if it is not already loaded"
		self class ensureMetacello.
		"Construct Metacello project"
		constructor := (Smalltalk at: #MetacelloVersionConstructor) on: self.
		project := constructor project.
		project loadType: #linear.
		project ]
]

{ #category : #'symbolic versions' }
ConfigurationOfPharoSound >> stable: spec [ 
	<symbolicVersion: #stable>
	
	spec for: #'pharo1.0.x' version: '1.0'. 
	spec for: #'pharo1.1.x' version: '3.0'. 
	spec for: #'pharo1.2.x' version: '3.0'. 

]

{ #category : #versions }
ConfigurationOfPharoSound >> version10: spec [
	<version: '1.0' imports: #('1.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'MarianoMartinezPeck'.
		spec description: 'First release 1.0 of this project '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.47';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-DamienCassou.6'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version20: spec [
	<version: '2.0' imports: #('1.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'MarianoMartinezPeck'.
		spec description: '- Changed the repository.
		- Some fixes to work with Pharo 1.1  '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-MarianoMartinezPeck.49';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-MarianoMartinezPeck.9'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version30: spec [
	<version: '3.0' imports: #('3.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'MarianoMartinezPeck'.
		spec description: '- Changed the repository.
		- Some fixes to work with Pharo 1.1  '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-GuillermoPolito.63';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-GuillermoPolito.20'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version40: spec [
	<version: '4.0' imports: #('3.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'MarianoMartinezPeck'.
		spec description: ' Move Sound-Scores to a separate package SoundScores  '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-MarianoMartinezPeck.66';
			package: 'SoundScores' with: 'SoundScores-MarianoMartinezPeck.2';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-GuillermoPolito.20'.
			
	]		
]
