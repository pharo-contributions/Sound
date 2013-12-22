"
(ConfigurationOfPharoSound project version: '6.1') load
	- adding ScaleMorph.

(ConfigurationOfPharoSound project version: '6.0') load
	- adding UpdatingStringMorph to a separate package


(ConfigurationOfPharoSound project version: '5.5') load
	- adding UpdatingStringMorph to the package

(ConfigurationOfPharoSound project version: '5.4') load
	- Work on 3.0 post 30321. Should not load on Pharo20 because (subclass AbstractSoundSystem into SoundSystem if you want and add current: to call default...)

(ConfigurationOfPharoSound project version: '5.3') load
	- Jannik cleans for 2.0
	- Work on 3.0 30321 (ready to work on SoundService refactorings as suggested by Pavel.)

(ConfigurationOfPharoSound project version: '5.2') load
	- starting to work on 2.0
	- does not work on 3.0 alpha
	
(ConfigurationOfPharoSound project version: '5.0') load
	- adding settings

(ConfigurationOfPharoSound project version: '4.2') load
	- update to SmalltalkHub move

(ConfigurationOfPharoSound project version: '4.1') load
	- updated to latest file
"
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

{ #category : #catalog }
ConfigurationOfPharoSound class >> catalogChangeLog [
	^ '-2013-08-24 Version 5.4. 
	Work on 3.0 post 30321. Should not load on Pharo20 because (subclass AbstractSoundSystem into SoundSystem if you want and add current: to call default...). Removed the dependency to Collection-Arithmetic since it confuses metacello because the package is in the image. 
[[[
	(ConfigurationOfPharoSound project version: ''5.4'') load
]]]
- 2013-07 Version 5.3
   Jannik cleans for 2.0 and work on 3.0 30321 (ready to work on SoundService refactorings as suggested by Pavel.)
[[[ 
	(ConfigurationOfPharoSound project version: ''5.3'') load
]]]	

- 2013-07 Version 5.2
	 starting to work on 2.0
	does not work on 3.0 alpha
[[[ 
	(ConfigurationOfPharoSound project version: ''5.2'') load
]]]	
	
- Version 5.0: adding settings	
- version 4.2: update to SmalltalkHub move
- version 4.1: updated to latest files'
]

{ #category : #catalog }
ConfigurationOfPharoSound class >> catalogDescription [

	^ 'Sound is a package offers multiple different ways to create and manipulate sounds. MIDI, sampled are typical examples.'
]

{ #category : #catalog }
ConfigurationOfPharoSound class >> catalogKeyClassesAndExample [

	^ ' To be filled up with more care
- SampledSound
- AbstractSound
- MidiPlayer
- 
'
]

{ #category : #catalog }
ConfigurationOfPharoSound class >> catalogKeywords [
	^ #(sound sample midi piano scores sonogram)
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

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline41: spec [ 
	<version: '4.1-baseline'>
	
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

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline42: spec [ 
	<version: '4.2-baseline'>
	
	spec for: #common do: [
		spec blessing: #baseline.
	].	
		
	spec for: #pharo do: [
		spec repository: 'http://smalltalkhub.com/mc/PharoExtras/Sound/main'.
		spec 
			package: 'Sound';
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'Collections-Arithmetic' with: [ spec repository: 'http://smalltalkhub.com/mc/PharoExtras/CollectionArithmetic/main' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: 'Sound'; requires: 'Collections-Arithmetic' ].
			
	]
]

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline50: spec [ 
	<version: '5.0-baseline'>
	
	spec for: #common do: [
		spec blessing: #baseline.
		spec description: 'Adding Settings'.
	].	
		
	spec for: #pharo do: [
		spec repository: 'http://smalltalkhub.com/mc/PharoExtras/Sound/main'.
		spec 
			package: 'Sound';
			package: 'Settings-Sound';
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'Collections-Arithmetic' with: [ spec repository: 'http://smalltalkhub.com/mc/PharoExtras/CollectionArithmetic/main' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: 'Sound'; requires: 'Collections-Arithmetic' ].
			
	]
]

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline51: spec [ 
	<version: '5.1-baseline'>
	
	spec for: #common do: [
		spec blessing: #baseline.
		spec description: 'Remove Collections-Arithmetic'.
	].	
		
	spec for: #pharo do: [
		spec repository: 'http://smalltalkhub.com/mc/PharoExtras/Sound/main'.
		spec 
			package: 'Sound';
			package: 'Settings-Sound';
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: 'Sound'].
	]
]

{ #category : #baselines }
ConfigurationOfPharoSound >> baseline60: spec [ 
	<version: '6.0-baseline'>
		
	spec for: #pharo do: [
		spec blessing: #baseline.
		spec description: 'Adding MorphExtension'.
		spec repository: 'http://smalltalkhub.com/mc/PharoExtras/Sound/main'.
		spec 
			package: 'SoundMorphicExtension';
			package: 'Sound' "with: [ spec requires: 'SoundMorphicExtension' ]" ;
			package: 'Settings-Sound';
			package: 'SoundScores' with: [ spec requires: 'Sound' ];
			package: 'SoundMorphicUserInterface' with: [ spec requires: #('Sound' 'SoundMorphicExtension') ].
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
	spec for: #'pharo1.4.x' version: '5.0'. 
	spec for: #'pharo2.0.x' version: '5.3'. 
	spec for: #'pharo3.0.x' version: '6.1'. 

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
	<version: '4.0' imports: #('4.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'MarianoMartinezPeck'.
		spec description: ' 
		- Move Sound-Scores to a separate package SoundScores.
		- Adapt for Pharo 1.4  '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-MarianoMartinezPeck.67';
			package: 'SoundScores' with: 'SoundScores-MarianoMartinezPeck.2';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-GuillermoPolito.20'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version41: spec [
	<version: '4.1' imports: #('4.1-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		- uses latest published versions of the files '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-HenrikSperreJohansen.69';
			package: 'SoundScores' with: 'SoundScores-MarianoMartinezPeck.2';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-GuillermoPolito.20'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version42: spec [
	<version: '4.2' imports: #('4.2-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		- uses SmalltalkHub now '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-HenrikSperreJohansen.69';
			package: 'SoundScores' with: 'SoundScores-MarianoMartinezPeck.2';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-GuillermoPolito.20'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version50: spec [
	<version: '5.0' imports: #('5.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		adding settings '.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-HenrikSperreJohansen.69';
			package: 'Settings-Sound' with: 'Settings-Sound';
			package: 'SoundScores' with: 'SoundScores-MarianoMartinezPeck.2';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-GuillermoPolito.20'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version51: spec [
	<version: '5.1' imports: #('5.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		starting to make things works for 2.0.'.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.70';
			package: 'Settings-Sound' with: 'Settings-Sound';
			package: 'SoundScores' with: 'SoundScores-MarianoMartinezPeck.2';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-StephaneDucasse.21'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version52: spec [
	<version: '5.2' imports: #('5.0-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		Removing SimpleSwicthMorph since it is in Morphic'.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.70';
			package: 'Settings-Sound' with: 'Settings-Sound';
			package: 'SoundScores' with: 'SoundScores-MarianoMartinezPeck.2';
			package: 'Collections-Arithmetic' with: 'Collections-Arithmetic-GuillermoPolito.4';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-StephaneDucasse.22'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version53: spec [
	<version: '5.3' imports: #('5.1-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		Integrating some cleaning of Jannik and making sure UI loads in 30.'.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.75';
			package: 'Settings-Sound' with: 'Settings-Sound-HenrikSperreJohansen.2';
			package: 'SoundScores' with: 'SoundScores-StephaneDucasse.6';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-StephaneDucasse.27'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version54: spec [
	<version: '5.4' imports: #('5.1-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		Does not work anymore in Pharo20 only in Pharo30
		because of the changes on SoundSystem as suggested by Pavel.'.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.76';
			package: 'Settings-Sound' with: 'Settings-Sound-HenrikSperreJohansen.2';
			package: 'SoundScores' with: 'SoundScores-StephaneDucasse.6';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-StephaneDucasse.29'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version55: spec [
	<version: '5.5' imports: #('5.1-baseline')>

	spec for: #common do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: ' 
		Now adding updatingStringMorph and cleaning FM sound'.
	].
	
	spec for: #pharo do: [
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.77';
			package: 'Settings-Sound' with: 'Settings-Sound-HenrikSperreJohansen.2';
			package: 'SoundScores' with: 'SoundScores-StephaneDucasse.6';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-StephaneDucasse.30'.
			
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version60: spec [
	<version: '6.0' imports: #('6.0-baseline')>

	spec for: #pharo do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: 'Extracting updatingStringMorph'.
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.77';
			package: 'SoundMorphicExtension' with:'SoundMorphicExtension-StephaneDucasse.1';
			package: 'Settings-Sound' with: 'Settings-Sound-HenrikSperreJohansen.2';
			package: 'SoundScores' with: 'SoundScores-StephaneDucasse.6';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-StephaneDucasse.31'.
	]		
]

{ #category : #versions }
ConfigurationOfPharoSound >> version61: spec [
	<version: '6.1' imports: #('6.0-baseline')>

	spec for: #pharo do: [
		spec blessing: #release.
		spec author: 'StephaneDucasse'.
		spec description: 'Adding ScaleMorph and making sure that EnvelopeEditorMorph works again'.
		spec 
			package: 'Sound' with: 'Sound-StephaneDucasse.80';
			package: 'SoundMorphicExtension' with: 'SoundMorphicExtension-StephaneDucasse.1';
			package: 'Settings-Sound' with: 'Settings-Sound-HenrikSperreJohansen.2';
			package: 'SoundScores' with: 'SoundScores-StephaneDucasse.6';
			package: 'SoundMorphicUserInterface' with: 'SoundMorphicUserInterface-StephaneDucasse.34'.
	]		
]
