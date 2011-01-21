Class {
	#name : #SoundSettings,
	#superclass : #Object,
	#category : #'Settings-Sound'
}

{ #category : #settings }
SoundSettings class >> loopSoundSettingOn: aBuilder [
    <systemsettings>
    (aBuilder setting: #infinitelyLoopSounds)
    parent: #soundEnabled;
        label: 'Loop sounds' translated;
	  description: 'Sounds will start over when done' translated;
        target: SoundPlayer 
]

{ #category : #settings }
SoundSettings class >> quickStartSoundSettingOn: aBuilder [
    <systemsettings>
    (aBuilder setting: #soundQuickStart)
    parent: #soundEnabled;
        label: 'Start sounds immediately' translated;
	description: 'Turn this off if your VM crashes when playing sound' translated;
        target: SoundPlayer 
]
