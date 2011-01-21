Class {
	#name : #SoundSettings,
	#superclass : #Object,
	#category : #'Settings-Sound'
}

{ #category : #settings }
SoundSettings class >> keepPlayerAroundSettingOn: aBuilder [
    <systemsettings>
    (aBuilder setting: #stopSoundWhenDone)
    parent: #soundEnabled;
        label: 'Keep sound player active' translated;
	  description: 'The sound player is shut down after playing finished' translated;
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

{ #category : #settings }
SoundSettings class >> recordWhilePlayingSettingOn: aBuilder [
    <systemsettings>
    (aBuilder setting: #canRecordWhilePlaying)
  	  parent: #soundEnabled;
        label: 'Allow simultanious recording and playing' translated;
	  description: 'Turn this off if your VM crashes when playing sound' translated;
        target: SoundRecorder 

]
