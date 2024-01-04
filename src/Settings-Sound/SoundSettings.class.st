Class {
	#name : 'SoundSettings',
	#superclass : 'Object',
	#category : 'Settings-Sound',
	#package : 'Settings-Sound'
}

{ #category : 'settings' }
SoundSettings class >> keepPlayerAroundSettingOn: aBuilder [
	<systemsettings>
	(aBuilder setting: #stopSoundWhenDone)
		parent: #soundEnabled;
		label: 'Keep sound player active';
		description: 'The sound player is shut down after playing finished';
		target: SoundPlayer
]

{ #category : 'settings' }
SoundSettings class >> quickStartSoundSettingOn: aBuilder [
	<systemsettings>
	(aBuilder setting: #soundQuickStart)
		parent: #soundEnabled;
		label: 'Start sounds immediately';
		description: 'Turn this off if your VM crashes when playing sound';
		target: SoundPlayer
]

{ #category : 'settings' }
SoundSettings class >> recordWhilePlayingSettingOn: aBuilder [

	<systemsettings>
	(aBuilder setting: #canRecordWhilePlaying)
		parent: #soundEnabled;
		label: 'Allow simultanious recording and playing';
		description: 'Turn this off if your VM crashes when playing sound';
		default: true;
		target: SoundDriver
]
