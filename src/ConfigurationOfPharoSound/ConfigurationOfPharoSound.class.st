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
	"Minimum package versions from which to boot Metacello. Corresponds to version 1.0-beta.15"

	Smalltalk at: #MetacelloProject ifAbsent: [
		Smalltalk at: #Gofer ifAbsent: [
			"Current version of Gofer from which to bootstrap - as of 1.0-beta.15"
			self bootstrapPackage: 'Gofer-lr.83' from: 'http://seaside.gemstone.com/ss/metacello' ].
		Smalltalk at: #Gofer ifPresent: [:gofer |
			gofer new
				url: 'http://seaside.gemstone.com/ss/metacello';
				addVersion: 'Metacello-Core-dkh.302'; "Minimum version from which to bootstrap Metacello"
				addVersion: 'Metacello-MC-dkh.258'; "Minimum version from which to bootstrap Metacello"
				addPackage: 'ConfigurationOfMetacello'; "Loads latest version of configuration package"
				load ].
		"load latest version of Metacello, load a specific version if desired"
		(Smalltalk at: #ConfigurationOfMetacello) loadLatestVersion ]
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

{ #category : #'as yet unclassified' }
ConfigurationOfPharoSound >> baseline10: spec [ 
	<version: '1.0-baseline'>
	
	spec for: #pharo do: [
		spec blessing: #baseline.
		spec repository: 'http://www.squeaksource.com/PharoSound'.

		spec 
			package: 'Sound';
			package: 'SoundMorphicUserInterface'.
			
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

{ #category : #'as yet unclassified' }
ConfigurationOfPharoSound >> version10: spec [
	<version: '1.0' imports: #('1.0-baseline')>

	spec for: #pharo do: [
		spec blessing: #release.
		spec author: Author fullName.
		spec description: 'First release 1.0 of this project '.
		
	spec 
		package: 'Sound' with: 'Sound-StephaneDucasse.47';
		package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-DamienCassou.6'.
		
	]
			
]
