"
An AbstractSound class is a class to represent sound.

SoundSystem soundEnabled: true.
SoundSystem initialize.
FMSound bassoon1 play


SoundPlayer initialize.
PluckedSound bachFugue play
"
Class {
	#name : #AbstractSound,
	#superclass : #Object,
	#instVars : [
		'envelopes',
		'mSecsSinceStart',
		'samplesUntilNextControl',
		'scaledVol',
		'scaledVolIncr',
		'scaledVolLimit'
	],
	#classVars : [
		'FloatScaleFactor',
		'MaxScaledValue',
		'PitchesForBottomOctave',
		'ScaleFactor',
		'Sounds',
		'TopOfBottomOctave',
		'UnloadedSnd'
	],
	#category : #'Sound-Synthesis'
}

{ #category : #'examples-bach fugue' }
AbstractSound class >> bachFugue [
	"Play a fugue by J. S. Bach using and instance of me as the sound for all four voices."
	"PluckedSound bachFugue play"

	^ self bachFugueOn: self default

]

{ #category : #'examples-bach fugue' }
AbstractSound class >> bachFugueOn: aSound [
	"Play a fugue by J. S. Bach using the given sound as the sound for all four voices."
	"PluckedSound bachFugue play"

	^ MixedSound new
		add: (self bachFugueVoice1On: aSound) pan: 1.0;
		add: (self bachFugueVoice2On: aSound) pan: 0.0;
		add: (self bachFugueVoice3On: aSound) pan: 1.0;
		add: (self bachFugueVoice4On: aSound) pan: 0.0.

]

{ #category : #'examples-bach fugue' }
AbstractSound class >> bachFugueVoice1On: aSound [
	"Voice one of a fugue by J. S. Bach."

	^ self noteSequenceOn: aSound from: #(
		(1047 0.15 268)
		(988  0.15 268)
		(1047 0.30 268)
		(784  0.30 268)
		(831  0.30 268)
		(1047 0.15 268)
		(988  0.15 268)
		(1047 0.30 268)
		(1175 0.30 268)
		(784  0.30 268)
		(1047 0.15 268)
		(988  0.15 268)
		(1047 0.30 268)
		(1175 0.30 268)
		(698  0.15 268)
		(784  0.15 268)
		(831  0.60 268)
		(784  0.15 268)
		(698  0.15 268)
		(622  0.15 268)
		(1047 0.15 268)
		(988  0.15 268)
		(880  0.15 268)
		(784  0.15 268)
		(698  0.15 268)
		(622  0.15 268)
		(587  0.15 268)
		(523  0.30 268)
		(1245 0.30 268)
		(1175 0.30 268)
		(1047 0.30 268)
		(932  0.30 268)
		(880  0.30 268)
		(932  0.30 268)
		(1047 0.30 268)
		(740  0.30 268)
		(784  0.30 268)
		(880  0.30 268)
		(740  0.30 268)
		(784  0.60 268)
		(rest 0.15)
		(523  0.15 268)
		(587  0.15 268)
		(622  0.15 268)
		(698  0.15 268)
		(784  0.15 268)
		(831  0.45 268)
		(587  0.15 268)
		(622  0.15 268)
		(698  0.15 268)
		(784  0.15 268)
		(880  0.15 268)
		(932  0.45 268)
		(622  0.15 268)
		(698  0.15 268)
		(784  0.15 268)
		(831  0.15 268)
		(784  0.15 268)
		(698  0.15 268)
		(622  0.15 268)
		(587  0.30 268)
		(1047 0.15 268)
		(988  0.15 268)
		(1047 0.60 268)
		(rest 0.9)
		(1397 0.30 268)
		(1245 0.30 268)
		(1175 0.30 268)
		(rest 0.3)
		(831  0.30 268)
		(784  0.30 268)
		(698  0.30 268)
		(784  0.30 268)
		(698  0.15 268)
		(622  0.15 268)
		(698  0.30 268)
		(587  0.30 268)
		(784  0.60 268)
		(rest 0.3)
		(988  0.30 268)
		(1047 0.30 268)
		(1047 0.15 268)
		(988  0.15 268)
		(1047 0.30 268)
		(784  0.30 268)
		(831  0.60 268)
		(rest 0.3)
		(880  0.30 268)
		(932  0.30 268)
		(932  0.15 268)
		(880  0.15 268)
		(932  0.30 268)
		(698  0.30 268)
		(784  0.60 268)
		(rest 0.3)
		(784  0.30 268)
		(831  0.30 268)
		(831  0.30 268)
		(784  0.30 268)
		(698  0.30 268)
		(rest 0.3)
		(415  0.30 268)
		(466  0.30 268)
		(523  0.30 268)
		(rest 0.3)
		(415  0.15 268)
		(392  0.15 268)
		(415  0.30 268)
		(349  0.30 268)
		(466  0.30 268)
		(523  0.30 268)
		(466  0.30 268)
		(415  0.30 268)
		(466  0.30 268)
		(392  0.30 268)
		(349  0.30 268)
		(311  0.30 268)
		(349  0.30 268)
		(554  0.30 268)
		(523  0.30 268)
		(466  0.30 268)
		(523  0.30 268)
		(415  0.30 268)
		(392  0.30 268)
		(349  0.30 268)
		(392  0.30 268)
		(784  0.15 268)
		(740  0.15 268)
		(784  0.30 268)
		(523  0.30 268)
		(622  0.30 268)
		(784  0.15 268)
		(740  0.15 268)
		(784  0.30 268)
		(880  0.30 268)
		(587  0.30 268)
		(784  0.15 268)
		(740  0.15 268)
		(784  0.30 268)
		(880  0.30 268)
		(523  0.15 268)
		(587  0.15 268)
		(622  0.60 268)
		(587  0.15 268)
		(523  0.15 268)
		(466  0.30 346)
		(rest 0.45)
		(587  0.15 346)
		(659  0.15 346)
		(740  0.15 346)
		(784  0.15 346)
		(880  0.15 346)
		(932  0.45 346)
		(659  0.15 346)
		(698  0.15 346)
		(784  0.15 346)
		(880  0.15 346)
		(932  0.15 346)
		(1047 0.45 346)
		(740  0.15 346)
		(784  0.15 346)
		(880  0.15 346)
		(932  0.30 346)
		(622  0.15 346)
		(587  0.15 346)
		(622  0.30 346)
		(392  0.30 346)
		(415  0.30 346)
		(698  0.15 346)
		(622  0.15 346)
		(698  0.30 346)
		(440  0.30 346)
		(466  0.30 346)
		(784  0.15 346)
		(698  0.15 346)
		(784  0.30 346)
		(494  0.30 346)
		(523  0.15 346)
		(698  0.15 346)
		(622  0.15 346)
		(587  0.15 346)
		(523  0.15 346)
		(466  0.15 346)
		(440  0.15 346)
		(392  0.15 346)
		(349  0.30 346)
		(831  0.30 346)
		(784  0.30 346)
		(698  0.30 346)
		(622  0.30 346)
		(587  0.30 346)
		(622  0.30 346)
		(698  0.30 346)
		(494  0.30 346)
		(523  0.30 346)
		(587  0.30 346)
		(494  0.30 346)
		(523  0.60 346)
		(rest 0.3)
		(659  0.30 346)
		(698  0.30 346)
		(698  0.15 346)
		(659  0.15 346)
		(698  0.30 346)
		(523  0.30 346)
		(587  0.60 346)
		(rest 0.3)
		(587  0.30 346)
		(622  0.30 346)
		(622  0.15 346)
		(587  0.15 346)
		(622  0.30 346)
		(466  0.30 346)
		(523  1.20 346)
		(523  0.30 346)
		(587  0.15 346)
		(622  0.15 346)
		(698  0.15 346)
		(622  0.15 346)
		(698  0.15 346)
		(587  0.15 346)
		(494  0.30 457)
		(rest 0.6)
		(494  0.30 457)
		(523  0.30 457)
		(rest 0.6)
		(622  0.30 457)
		(587  0.30 457)
		(rest 0.6)
		(698  0.60 457)
		(rest 0.6)
		(698  0.30 457)
		(622  0.30 457)
		(831  0.30 457)
		(784  0.30 457)
		(698  0.30 457)
		(622  0.30 457)
		(587  0.30 457)
		(622  0.30 457)
		(698  0.30 457)
		(494  0.30 457)
		(523  0.30 457)
		(587  0.30 457)
		(494  0.30 457)
		(494  0.30 457)
		(523  0.30 457)
		(rest 0.3)
		(523  0.30 457)
		(698  0.15 457)
		(587  0.15 457)
		(622  0.15 457)
		(523  0.45 457)
		(494  0.30 457)
		(523  0.60 457)
		(rest 0.3)
		(659  0.30 268)
		(698  0.60 268)
		(rest 0.3)
		(698  0.30 268)
		(698  0.30 268)
		(622  0.15 268)
		(587  0.15 268)
		(622  0.30 268)
		(698  0.30 268)
		(587  0.40 268)
		(rest 0.4)
		(587  0.40 268)
		(rest 0.4)
		(523  1.60 268)).
]

{ #category : #'examples-bach fugue' }
AbstractSound class >> bachFugueVoice2On: aSound [
	"Voice two of a fugue by J. S. Bach."

	^ self noteSequenceOn: aSound from: #(
		(rest 4.8)
		(1568 0.15 346)
		(1480 0.15 346)
		(1568 0.30 346)
		(1047 0.30 346)
		(1245 0.30 346)
		(1568 0.15 346)
		(1480 0.15 346)
		(1568 0.30 346)
		(1760 0.30 346)
		(1175 0.30 346)
		(1568 0.15 346)
		(1480 0.15 346)
		(1568 0.30 346)
		(1760 0.30 346)
		(1047 0.15 346)
		(1175 0.15 346)
		(1245 0.60 346)
		(1175 0.15 346)
		(1047 0.15 346)
		(932  0.30 346)
		(1245 0.15 346)
		(1175 0.15 346)
		(1245 0.30 346)
		(784  0.30 346)
		(831  0.30 346)
		(1397 0.15 346)
		(1245 0.15 346)
		(1397 0.30 346)
		(880  0.30 346)
		(932  0.30 346)
		(1568 0.15 346)
		(1397 0.15 346)
		(1568 0.30 346)
		(988  0.30 346)
		(1047 0.30 346)
		(1175 0.15 346)
		(1245 0.15 346)
		(1397 0.90 346)
		(1245 0.15 346)
		(1175 0.15 346)
		(1047 0.15 346)
		(932  0.15 346)
		(831  0.15 346)
		(784  0.15 346)
		(698  0.30 346)
		(1661 0.30 346)
		(1568 0.30 346)
		(1397 0.30 346)
		(1245 0.30 346)
		(1175 0.30 346)
		(1245 0.30 346)
		(1397 0.30 346)
		(988  0.30 346)
		(1047 0.30 346)
		(1175 0.30 346)
		(988  0.30 346)
		(1047 0.30 457)
		(1568 0.15 457)
		(1480 0.15 457)
		(1568 0.30 457)
		(1175 0.30 457)
		(1245 0.60 457)
		(rest 0.3)
		(1319 0.30 457)
		(1397 0.30 457)
		(1397 0.15 457)
		(1319 0.15 457)
		(1397 0.30 457)
		(1047 0.30 457)
		(1175 0.60 457)
		(rest 0.3)
		(1175 0.30 457)
		(1245 0.30 457)
		(1245 0.15 457)
		(1175 0.15 457)
		(1245 0.30 457)
		(932  0.30 457)
		(1047 0.30 457)
		(1245 0.15 457)
		(1175 0.15 457)
		(1245 0.30 457)
		(1397 0.30 457)
		(932  0.30 457)
		(1245 0.15 457)
		(1175 0.15 457)
		(1245 0.30 457)
		(1397 0.30 457)
		(831  0.15 457)
		(932  0.15 457)
		(1047 0.60 457)
		(932  0.15 457)
		(831  0.15 457)
		(784  0.15 457)
		(622  0.15 457)
		(698  0.15 457)
		(784  0.15 457)
		(831  0.15 457)
		(932  0.15 457)
		(1047 0.15 457)
		(1175 0.15 457)
		(1245 0.15 457)
		(1175 0.15 457)
		(1047 0.15 457)
		(1175 0.15 457)
		(1245 0.15 457)
		(1397 0.15 457)
		(1568 0.15 457)
		(1760 0.15 457)
		(1865 0.15 457)
		(698  0.15 457)
		(784  0.15 457)
		(831  0.15 457)
		(932  0.15 457)
		(1047 0.15 457)
		(1175 0.15 457)
		(1319 0.15 457)
		(1397 0.15 457)
		(1245 0.15 457)
		(1175 0.15 457)
		(1245 0.15 457)
		(1397 0.15 457)
		(1568 0.15 457)
		(1760 0.15 457)
		(1976 0.15 457)
		(2093 0.30 457)
		(1976 0.15 457)
		(1760 0.15 457)
		(1568 0.15 457)
		(1397 0.15 457)
		(1245 0.15 457)
		(1175 0.15 457)
		(1047 0.30 457)
		(1245 0.30 457)
		(1175 0.30 457)
		(1047 0.30 457)
		(932  0.30 457)
		(880  0.30 457)
		(932  0.30 457)
		(1047 0.30 457)
		(740  0.30 457)
		(784  0.30 457)
		(880  0.30 457)
		(740  0.30 457)
		(784  0.30 457)
		(1175 0.15 457)
		(1047 0.15 457)
		(1175 0.30 457)
		(rest 0.6)
		(1319 0.15 457)
		(1175 0.15 457)
		(1319 0.30 457)
		(rest 0.6)
		(1480 0.15 457)
		(1319 0.15 457)
		(1480 0.30 457)
		(rest 0.6)
		(784  0.15 457)
		(698  0.15 457)
		(784  0.30 457)
		(rest 0.6)
		(880  0.15 457)
		(784  0.15 457)
		(880  0.30 457)
		(rest 0.6)
		(988  0.15 457)
		(880  0.15 457)
		(988  0.30 457)
		(rest 0.6)
		(1047 0.15 457)
		(988  0.15 457)
		(1047 0.30 457)
		(784  0.30 457)
		(831  0.30 457)
		(1047 0.15 457)
		(988  0.15 457)
		(1047 0.30 457)
		(1175 0.30 457)
		(784  0.30 457)
		(1047 0.15 457)
		(988  0.15 457)
		(1047 0.30 457)
		(1175 0.30 457)
		(698  0.15 457)
		(784  0.15 457)
		(831  0.60 457)
		(784  0.15 457)
		(698  0.15 457)
		(622  0.30 457)
		(1047 0.15 457)
		(988  0.15 457)
		(1047 0.30 457)
		(784  0.30 457)
		(831  0.60 457)
		(rest 0.3)
		(880  0.30 457)
		(932  0.30 457)
		(932  0.15 457)
		(880  0.15 457)
		(932  0.30 457)
		(698  0.30 457)
		(784  0.60 457)
		(rest 0.3)
		(784  0.60 457)
		(831  0.15 457)
		(932  0.15 457)
		(1047 0.15 457)
		(988  0.15 457)
		(1047 0.15 457)
		(831  0.15 457)
		(698  1.20 457)
		(698  0.30 591)
		(1175 0.15 591)
		(1047 0.15 591)
		(1175 0.30 591)
		(698  0.30 591)
		(622  0.30 591)
		(1245 0.15 591)
		(1175 0.15 591)
		(1245 0.30 591)
		(784  0.30 591)
		(698  0.30 591)
		(1397 0.15 591)
		(1245 0.15 591)
		(1397 0.30 591)
		(831  0.30 591)
		(784  0.15 591)
		(1397 0.15 591)
		(1245 0.15 591)
		(1175 0.15 591)
		(1047 0.15 591)
		(988  0.15 591)
		(880  0.15 591)
		(784  0.15 591)
		(1047 0.30 591)
		(1397 0.30 591)
		(1245 0.30 591)
		(1175 0.30 591)
		(rest 0.3)
		(831  0.30 591)
		(784  0.30 591)
		(698  0.30 591)
		(784  0.30 591)
		(698  0.15 591)
		(622  0.15 591)
		(698  0.30 591)
		(587  0.30 591)
		(831  0.30 591)
		(784  0.30 591)
		(rest 0.3)
		(880  0.30 591)
		(988  0.30 591)
		(1047 0.30 591)
		(698  0.15 591)
		(622  0.15 591)
		(587  0.15 591)
		(523  0.15 591)
		(523  0.30 591)
		(1047 0.15 346)
		(988  0.15 346)
		(1047 0.30 346)
		(784  0.30 346)
		(831  0.30 346)
		(1047 0.15 346)
		(988  0.15 346)
		(1047 0.30 346)
		(1175 0.30 346)
		(784  0.30 346)
		(1047 0.15 346)
		(988  0.15 346)
		(1047 0.30 346)
		(1175 0.30 346)
		(698  0.20 346)
		(784  0.20 346)
		(831  0.80 346)
		(784  0.20 346)
		(698  0.20 346)
		(659  1.60 346)).

]

{ #category : #'examples-bach fugue' }
AbstractSound class >> bachFugueVoice3On: aSound [
	"Voice three of a fugue by J. S. Bach."

	^ self noteSequenceOn: aSound from: #(
		(rest 14.4)
		(523  0.15 457)
		(494  0.15 457)
		(523  0.30 457)
		(392  0.30 457)
		(415  0.30 457)
		(523  0.15 457)
		(494  0.15 457)
		(523  0.30 457)
		(587  0.30 457)
		(392  0.30 457)
		(523  0.15 457)
		(494  0.15 457)
		(523  0.30 457)
		(587  0.30 457)
		(349  0.15 457)
		(392  0.15 457)
		(415  0.60 457)
		(392  0.15 457)
		(349  0.15 457)
		(311  0.15 457)
		(523  0.15 457)
		(494  0.15 457)
		(440  0.15 457)
		(392  0.15 457)
		(349  0.15 457)
		(311  0.15 457)
		(294  0.15 457)
		(262  0.15 457)
		(294  0.15 457)
		(311  0.15 457)
		(294  0.15 457)
		(262  0.15 457)
		(233  0.15 457)
		(208  0.15 457)
		(196  0.15 457)
		(175  0.15 457)
		(466  0.15 457)
		(415  0.15 457)
		(392  0.15 457)
		(349  0.15 457)
		(311  0.15 457)
		(294  0.15 457)
		(262  0.15 457)
		(233  0.15 457)
		(262  0.15 457)
		(294  0.15 457)
		(262  0.15 457)
		(233  0.15 457)
		(208  0.15 457)
		(196  0.15 457)
		(175  0.15 457)
		(156  0.15 457)
		(415  0.15 457)
		(392  0.15 457)
		(349  0.15 457)
		(311  0.15 457)
		(277  0.15 457)
		(262  0.15 457)
		(233  0.15 457)
		(208  0.30 457)
		(523  0.30 457)
		(466  0.30 457)
		(415  0.30 457)
		(392  0.30 457)
		(349  0.30 457)
		(392  0.30 457)
		(415  0.30 457)
		(294  0.30 457)
		(311  0.30 457)
		(349  0.30 457)
		(294  0.30 457)
		(311  0.30 457)
		(415  0.30 457)
		(392  0.30 457)
		(349  0.30 457)
		(392  0.30 457)
		(311  0.30 457)
		(294  0.30 457)
		(262  0.30 457)
		(294  0.30 457)
		(466  0.30 457)
		(415  0.30 457)
		(392  0.30 457)
		(415  0.30 457)
		(349  0.30 457)
		(311  0.30 457)
		(294  0.30 457)
		(311  0.30 457)
		(rest 1.2)
		(262  0.30 457)
		(233  0.30 457)
		(220  0.30 457)
		(rest 0.3)
		(311  0.30 457)
		(294  0.30 457)
		(262  0.30 457)
		(294  0.30 457)
		(262  0.15 457)
		(233  0.15 457)
		(262  0.30 457)
		(294  0.30 457)
		(196  0.30 591)
		(466  0.15 591)
		(440  0.15 591)
		(466  0.30 591)
		(294  0.30 591)
		(311  0.30 591)
		(523  0.15 591)
		(466  0.15 591)
		(523  0.30 591)
		(330  0.30 591)
		(349  0.30 591)
		(587  0.15 591)
		(523  0.15 591)
		(587  0.30 591)
		(370  0.30 591)
		(392  0.60 591)
		(rest 0.15)
		(196  0.15 591)
		(220  0.15 591)
		(247  0.15 591)
		(262  0.15 591)
		(294  0.15 591)
		(311  0.45 591)
		(220  0.15 591)
		(233  0.15 591)
		(262  0.15 591)
		(294  0.15 591)
		(311  0.15 591)
		(349  0.45 591)
		(247  0.15 591)
		(262  0.15 591)
		(294  0.15 591)
		(311  0.30 591)
		(rest 0.6)
		(330  0.30 591)
		(349  0.30 591)
		(175  0.30 591)
		(156  0.30 591)
		(147  0.30 591)
		(rest 0.3)
		(208  0.30 591)
		(196  0.30 591)
		(175  0.30 591)
		(196  0.30 591)
		(175  0.15 591)
		(156  0.15 591)
		(175  0.30 591)
		(196  0.30 591)
		(262  0.15 591)
		(294  0.15 591)
		(311  0.15 591)
		(294  0.15 591)
		(262  0.15 591)
		(233  0.15 591)
		(208  0.15 591)
		(196  0.15 591)
		(175  0.15 591)
		(466  0.15 591)
		(415  0.15 591)
		(392  0.15 591)
		(349  0.15 591)
		(311  0.15 591)
		(294  0.15 591)
		(262  0.15 591)
		(233  0.15 591)
		(262  0.15 591)
		(294  0.15 591)
		(262  0.15 591)
		(233  0.15 591)
		(208  0.15 591)
		(196  0.15 591)
		(175  0.15 591)
		(156  0.15 591)
		(415  0.15 591)
		(392  0.15 591)
		(349  0.15 591)
		(311  0.15 591)
		(294  0.15 591)
		(262  0.15 591)
		(233  0.15 591)
		(208  0.15 591)
		(233  0.15 591)
		(262  0.15 591)
		(233  0.15 591)
		(208  0.15 591)
		(196  0.15 591)
		(175  0.15 591)
		(156  0.15 591)
		(147  0.15 591)
		(392  0.15 591)
		(349  0.15 591)
		(311  0.15 591)
		(294  0.15 591)
		(262  0.15 591)
		(247  0.15 591)
		(220  0.15 591)
		(196  0.60 772)
		(196  0.60 772)
		(rest 0.15)
		(196  0.15 772)
		(220  0.15 772)
		(247  0.15 772)
		(262  0.15 772)
		(294  0.15 772)
		(311  0.15 772)
		(349  0.15 772)
		(392  0.15 772)
		(349  0.15 772)
		(415  0.15 772)
		(392  0.15 772)
		(349  0.15 772)
		(311  0.15 772)
		(294  0.15 772)
		(262  0.15 772)
		(247  0.30 772)
		(262  0.15 772)
		(494  0.15 772)
		(262  0.30 772)
		(196  0.30 772)
		(208  0.30 772)
		(262  0.15 772)
		(247  0.15 772)
		(262  0.30 772)
		(294  0.30 772)
		(196  0.30 772)
		(262  0.15 772)
		(247  0.15 772)
		(262  0.30 772)
		(294  0.30 772)
		(175  0.15 772)
		(196  0.15 772)
		(208  0.60 772)
		(196  0.15 772)
		(175  0.15 772)
		(156  0.60 772)
		(rest 0.3)
		(311  0.30 772)
		(294  0.30 772)
		(262  0.30 772)
		(392  0.30 772)
		(196  0.30 772)
		(262  3.60 268)
		(494  0.40 268)
		(rest 0.4)
		(494  0.40 268)
		(rest 0.4)
		(392  1.60 268)).

]

{ #category : #'examples-bach fugue' }
AbstractSound class >> bachFugueVoice4On: aSound [
	"Voice four of a fugue by J. S. Bach."

	^ self noteSequenceOn: aSound from: #(
		(rest 61.2)
		(131  0.15 500)
		(123  0.15 500)
		(131  0.30 500)
		(98   0.30 500)
		(104  0.30 500)
		(131  0.15 500)
		(123  0.15 500)
		(131  0.30 500)
		(147  0.30 500)
		(98   0.30 500)
		(131  0.15 500)
		(123  0.15 500)
		(131  0.30 500)
		(147  0.30 500)
		(87   0.15 500)
		(98   0.15 500)
		(104  0.60 500)
		(98   0.15 500)
		(87   0.15 500)
		(78   0.60 500)
		(rest 0.3)
		(156  0.30 500)
		(147  0.30 500)
		(131  0.30 500)
		(196  0.30 500)
		(98   0.30 500)
		(131  3.60 268)
		(131  3.20 205)).

]

{ #category : #utilities }
AbstractSound class >> busySignal: count [
	"AbstractSound busySignal: 3"
	| m s |
	s := SequentialSound new.
	m := MixedSound new.
	m	add: (FMSound new setPitch: 480 dur: 0.5 loudness: 0.5);
		add: (FMSound new setPitch: 620 dur: 0.5 loudness: 0.5).
	s add: m.
	s add: (FMSound new setPitch: 1 dur: 0.5 loudness: 0).
	^ (RepeatingSound repeat: s count: count) play.


]

{ #category : #examples }
AbstractSound class >> chromaticPitchesFrom: aPitch [

	| halfStep pitch |
	halfStep := 2.0 raisedTo: (1.0 / 12.0).
	pitch := aPitch isNumber
			ifTrue: [aPitch]
			ifFalse: [self pitchForName: aPitch].
	pitch := pitch / halfStep.
	^ (0 to: 14) collect: [:i | pitch := pitch * halfStep]

]

{ #category : #examples }
AbstractSound class >> chromaticRunFrom: startPitch to: endPitch on: aSound [
	"Answer a composite sound consisting of a rapid chromatic run between the given pitches on the given sound."
	"(AbstractSound chromaticRunFrom: 'c3' to: 'c#5' on: FMSound oboe1) play"

	| scale halfStep pEnd p |
	scale := SequentialSound new.
	halfStep := 2.0 raisedTo: (1.0 / 12.0).
	endPitch isNumber
		ifTrue: [pEnd := endPitch asFloat]
		ifFalse: [pEnd := AbstractSound pitchForName: endPitch].
	startPitch isNumber
		ifTrue: [p := startPitch asFloat]
		ifFalse: [p := AbstractSound pitchForName: startPitch].
	[p <= pEnd] whileTrue: [
		scale add: (aSound soundForPitch: p dur: 0.2 loudness: 0.5).
		p := p * halfStep].
	^ scale

]

{ #category : #examples }
AbstractSound class >> chromaticScale [
	"PluckedSound chromaticScale play"

	^ self chromaticScaleOn: self default

]

{ #category : #examples }
AbstractSound class >> chromaticScaleOn: aSound [
	"PluckedSound chromaticScale play"

	^ self noteSequenceOn: aSound
		from: (((self chromaticPitchesFrom: #c4) copyFrom: 1 to: 13)
			 collect: [:pitch | Array with: pitch with: 0.5 with: 300])

]

{ #category : #'instance creation' }
AbstractSound class >> default [
	"Return a default sound prototype for this class, with envelopes if appropriate. (This is in contrast to new, which returns a raw instance without envelopes.)"

	^ self new

]

{ #category : #utilities }
AbstractSound class >> dial: aString [
	| s |
	"AbstractSound dial: '867-5309'" "ask for Jenny"

	s := SequentialSound new.
	aString do: [ :c | | lo m index hi |
		c = $,
			ifTrue: [ s add: (FMSound new setPitch: 1 dur: 1 loudness: 0) ]
			ifFalse: [
				(index := ('123A456B789C*0#D' indexOf: c)) > 0
					ifTrue: [
						lo := #(697 770 852 941) at: (index - 1 // 4 + 1).
						hi := #(1209 1336 1477 1633) at: (index - 1 \\ 4 + 1).
						m := MixedSound new.
						m add: (FMSound new setPitch: lo dur: 0.15 loudness: 0.5).
						m add: (FMSound new setPitch: hi dur: 0.15 loudness: 0.5).
						s add: m.
						s add: (FMSound new setPitch: 1 dur: 0.05 loudness: 0)]]].
	^ s play.


]

{ #category : #utilities }
AbstractSound class >> dialTone: duration [
	"AbstractSound dialTone: 2"
	| m |
	m := MixedSound new.
	m add: (FMSound new setPitch: 350 dur: duration loudness: 0.5).
	m add: (FMSound new setPitch: 440 dur: duration loudness: 0.5).
	m play.
	^ m
]

{ #category : #'instance creation' }
AbstractSound class >> dur: d [
	"Return a rest of the given duration."

	^ self basicNew setDur: d

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> fileInSoundLibrary [
	"Prompt the user for a file name and the file in the sound library with that name."
	"AbstractSound fileInSoundLibrary"

	| fileName |
	fileName := UIManager default request: 'Sound library file name?'.
	fileName isEmptyOrNil ifTrue: [^ self].
	(fileName endsWith: '.sounds') ifFalse: [fileName := fileName, '.sounds'].
	self fileInSoundLibraryNamed: fileName.

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> fileInSoundLibraryNamed: fileName [
	"File in the sound library with the given file name, and add its contents to the current sound library."

	| s newSounds |
	s := FileStream oldFileNamed: fileName.
	[ newSounds := s fileInObjectAndCode ]
		ensure: [ s close ].
	newSounds associationsDo: [:assoc | 
		self storeFiledInSound: assoc value named: assoc key].
	AbstractSound updateScorePlayers.
	Smalltalk garbageCollect.  "Large objects may have been released"

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> fileOutSoundLibrary [
	"File out the current sound library."
	"AbstractSound fileOutSoundLibrary"

	self fileOutSoundLibrary: Sounds.

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> fileOutSoundLibrary: aDictionary [
	"File out the given dictionary, which is assumed to contain sound and instrument objects keyed by their names."
	"Note: This method is separated out so that one can file out edited sound libraries, as well as the system sound library. To make such a collection, you can inspect AbstractSound sounds and remove the items you don't want. Then do: 'AbstractSound fileOutSoundLibrary: self' from the Dictionary inspector."

	| fileName refStream |
	(aDictionary isKindOf: Dictionary)
		ifFalse: [self error: 'arg should be a dictionary of sounds'].
	fileName := UIManager default request: 'Sound library file name?'.
	fileName isEmptyOrNil ifTrue: [^ self].
	refStream := StandardFileStream fileNamed: fileName, '.sounds'.
	[ refStream nextPut: aDictionary ]
		ensure: [ refStream close ]
]

{ #category : #utilities }
AbstractSound class >> hangUpWarning: count [
	"AbstractSound hangUpWarning: 20"
	| m s |
	s := SequentialSound new.
	m := MixedSound new.
	m	add: (FMSound new setPitch: 1400 dur: 0.1 loudness: 0.5);
		add: (FMSound new setPitch: 2060 dur: 0.1 loudness: 0.5).
	s add: m; add: (FMSound new setPitch: 1 dur: 0.1 loudness: 0).
	^ (RepeatingSound repeat: s count: count) play


]

{ #category : #examples }
AbstractSound class >> hiMajorScale [
	"FMSound hiMajorScale play"

	^ self hiMajorScaleOn: self default

]

{ #category : #examples }
AbstractSound class >> hiMajorScaleOn: aSound [
	"FMSound hiMajorScale play"

	^ self majorScaleOn: aSound from: #c6
]

{ #category : #utilities }
AbstractSound class >> indexOfBottomOctavePitch: p [
	"Answer the index of the first pitch in the bottom octave equal to or higher than the given pitch. Assume that the given pitch is below the top pitch of the bottom octave."

	1 to: PitchesForBottomOctave size do: [:i |
		(PitchesForBottomOctave at: i) >= p ifTrue: [^ i]].
	self error: 'implementation error: argument pitch should be below or within the bottom octave'.

]

{ #category : #'sound library' }
AbstractSound class >> initSounds [
	"AbstractSound initSounds"

	Sounds := Dictionary new.
	(FMSound class organization listAtCategoryNamed: #instruments)
		do: [:sel | Sounds at: sel asString put: (FMSound perform: sel)].

]

{ #category : #initialization }
AbstractSound class >> initialize [
	"AbstractSound initialize"
 
	| bottomC |
	ScaleFactor := 2 raisedTo: 15.
	FloatScaleFactor := ScaleFactor asFloat.
	MaxScaledValue := ((2 raisedTo: 31) // ScaleFactor) - 1.  "magnitude of largest scaled value in 32-bits"

	"generate pitches for c-1 through c0"
	bottomC := (440.0 / 32) * (2.0 raisedTo: -9.0 / 12.0).
	PitchesForBottomOctave := (0 to: 12) collect: [:i | bottomC * (2.0 raisedTo: i asFloat / 12.0)].
	TopOfBottomOctave := PitchesForBottomOctave last.

]

{ #category : #examples }
AbstractSound class >> lowMajorScale [
	"PluckedSound lowMajorScale play"

	^ self lowMajorScaleOn: self default

]

{ #category : #examples }
AbstractSound class >> lowMajorScaleOn: aSound [
	"PluckedSound lowMajorScale play"

	^ self majorScaleOn: aSound from: #c3
]

{ #category : #examples }
AbstractSound class >> majorChord [
	"FMSound majorChord play"
	^ self majorChordOn: self default from: #c4
]

{ #category : #examples }
AbstractSound class >> majorChordOn: aSound from: aPitch [
	"FMSound majorChord play"

	| score majorScale leadingRest pan |
	majorScale := self majorPitchesFrom: aPitch.
	score := MixedSound new.
	leadingRest := pan := 0.
	#(1 3 5 8) do: [:noteIndex | | note |
		note := aSound
					soundForPitch: (majorScale at: noteIndex)
					dur: 2.0 - leadingRest
					loudness: 0.3.
		score add: (RestSound dur: leadingRest), note pan: pan.
		leadingRest := leadingRest + 0.2.
		pan := pan + 0.3].
	^ score

]

{ #category : #examples }
AbstractSound class >> majorPitchesFrom: aPitch [
	| chromatic |
	chromatic := self chromaticPitchesFrom: aPitch.
	^ #(1 3 5 6 8 10 12 13 15 13 12 10 8 6 5 3 1) collect: [:i | chromatic at: i].

]

{ #category : #examples }
AbstractSound class >> majorScale [
	"FMSound majorScale play"

	^ self majorScaleOn: self default

]

{ #category : #examples }
AbstractSound class >> majorScaleOn: aSound [
	"FMSound majorScale play"

	^ self majorScaleOn: aSound from: #c5
]

{ #category : #examples }
AbstractSound class >> majorScaleOn: aSound from: aPitch [
	"FMSound majorScale play"

	^ self noteSequenceOn: aSound
		from: ((self majorPitchesFrom: aPitch)
			 collect: [:pitch | Array with: pitch with: 0.5 with: 300])

]

{ #category : #examples }
AbstractSound class >> majorScaleOn: aSound from: aPitch octaves: octaveCount [
	"(AbstractSound majorScaleOn: FMSound oboe1 from: #c2 octaves: 5) play"

	| startingPitch pitches chromatic |
	startingPitch := aPitch isNumber
		ifTrue: [aPitch]
		ifFalse: [self pitchForName: aPitch].
	pitches := OrderedCollection new.
	0 to: octaveCount - 1 do: [:i |
		chromatic := self chromaticPitchesFrom: startingPitch * (2 raisedTo: i).
		#(1 3 5 6 8 10 12) do: [:j | pitches addLast: (chromatic at: j)]].
	pitches addLast: startingPitch * (2 raisedTo: octaveCount).
	^ self noteSequenceOn: aSound
		from: (pitches collect: [:pitch | Array with: pitch with: 0.5 with: 300])

]

{ #category : #utilities }
AbstractSound class >> midiKeyForPitch: pitchNameOrNumber [
	"Answer the midiKey closest to the given pitch. Pitch may be a numeric pitch or a pitch name string such as 'c4'."
	"AbstractSound midiKeyForPitch: 440.0"

	| p octave i midiKey |
	pitchNameOrNumber isNumber
		ifTrue: [p := pitchNameOrNumber asFloat]
		ifFalse: [p := AbstractSound pitchForName: pitchNameOrNumber].
	octave := -1.
	[p >= TopOfBottomOctave] whileTrue: [
		octave := octave + 1.
		p := p / 2.0].

	i := self indexOfBottomOctavePitch: p.
	(i > 1) ifTrue: [
		(p - (PitchesForBottomOctave at: i - 1)) < ((PitchesForBottomOctave at: i) - p)
			ifTrue: [i := i - 1]].

	midiKey := ((octave * 12) + 11 + i).
	midiKey > 127 ifTrue: [midiKey := 127].
	^ midiKey

]

{ #category : #'instance creation' }
AbstractSound class >> noteSequenceOn: aSound from: anArray [
	"Build a note sequence (i.e., a SequentialSound) from the given array using the given sound as the instrument. Elements are either (pitch, duration, loudness) triples or (#rest duration) pairs.  Pitches can be given as names or as numbers."
	| score |
	score := SequentialSound new.
	anArray do: [:el | | pitch |
		el size = 3
			ifTrue: [
				pitch := el at: 1.
				pitch isNumber ifFalse: [pitch := self pitchForName: pitch].
				score add: (
					aSound
						soundForPitch: pitch
						dur: (el at: 2)
						loudness: (el at: 3) / 1000.0)]
			ifFalse: [
				score add: (RestSound dur: (el at: 2))]].
	^ score

]

{ #category : #'instance creation' }
AbstractSound class >> pitch: p dur: d loudness: l [
	"Return a new sound object for a note with the given parameters."

	^ self new setPitch: p dur: d loudness: l

]

{ #category : #utilities }
AbstractSound class >> pitchForMIDIKey: midiKey [
	"Answer the pitch for the given MIDI key."
	"(1 to: 127) collect: [:i | AbstractSound pitchForMIDIKey: i]"

	| indexInOctave octave |
	indexInOctave := (midiKey \\ 12) + 1.
	octave := (midiKey // 12) + 1.
	^ (PitchesForBottomOctave at: indexInOctave) *
		(#(1.0 2.0 4.0 8.0 16.0 32.0 64.0 128.0 256.0 512.0 1024.0) at: octave)

]

{ #category : #utilities }
AbstractSound class >> pitchForName: aString [
	"AbstractSound pitchForName: 'c2'"
	"#(c 'c#' d eb e f fs g 'g#' a bf b) collect: [ :s | AbstractSound pitchForName: s, '4']"

	| s modifier octave i j noteName p |
	s := ReadStream on: aString.
	modifier := $n.
	noteName := s next.
	(s atEnd not and: [s peek isDigit]) ifFalse: [ modifier := s next ].
	s atEnd
		ifTrue: [ octave := 4 ]
		ifFalse: [ octave := Integer readFrom: s ].
	octave < 0 ifTrue: [ self error: 'cannot use negative octave number' ].
	i := 'cdefgab' indexOf: noteName.
	i = 0 ifTrue: [ self error: 'bad note name: ', noteName asString ].
	i := #(2 4 6 7 9 11 13) at: i.
	j := 's#fb' indexOf: modifier.
	j = 0 ifFalse: [ i := i + (#(1 1 -1 -1) at: j) ].  "i is now in range: [1..14]"
	"Table generator: (1 to: 14) collect: [ :i | 16.3516 * (2.0 raisedTo: (i - 2) asFloat / 12.0)]"
	p := #(15.4339 16.3516 17.3239 18.354 19.4454 20.6017 21.8268 23.1247 24.4997 25.9565 27.5 29.1352 30.8677 32.7032) at: i.
	octave timesRepeat: [ p := 2.0 * p ].
	^ p

]

{ #category : #utilities }
AbstractSound class >> pitchTable [
	"AbstractSound pitchTable"

	| out i |
	out := WriteStream on: (String new: 1000).
	i := 12.
	0 to: 8 do: [:octave |
		#(c 'c#' d eb e f fs g 'g#' a bf b) do: [:noteName | | note |
			note := noteName, octave printString.
			out nextPutAll: note; tab.
			out nextPutAll: i printString; tab.
			out nextPutAll: (AbstractSound pitchForName: note) printString; cr.
			i := i + 1]].
	^ out contents

]

{ #category : #initialization }
AbstractSound class >> scaleFactor [

	^ ScaleFactor

]

{ #category : #examples }
AbstractSound class >> scaleTest [
	"AbstractSound scaleTest play"

	^ MixedSound new
		add: FMSound majorScale pan: 0;
		add: (PluckedSound lowMajorScale delayedBy: 0.5) pan: 1.0.

]

{ #category : #'sound library' }
AbstractSound class >> soundNamed: soundName [

	^ Sounds at: soundName

]

{ #category : #'sound library' }
AbstractSound class >> soundNamed: soundName ifAbsent: aBlock [

	^ Sounds at: soundName ifAbsent: aBlock

]

{ #category : #'sound library' }
AbstractSound class >> soundNamed: soundName put: aSound [

	Sounds at: soundName put: aSound.
	AbstractSound updateScorePlayers.

]

{ #category : #'sound library' }
AbstractSound class >> soundNames [

	^ Sounds keys sorted

]

{ #category : #'sound library' }
AbstractSound class >> sounds [

	^ Sounds

]

{ #category : #'examples-bach fugue' }
AbstractSound class >> stereoBachFugue [
	"Play fugue by J. S. Bach in stereo using different timbres."
	"AbstractSound stereoBachFugue play"

	"(AbstractSound bachFugueVoice1On: FMSound flute1) play"
	"(AbstractSound bachFugueVoice1On: PluckedSound default) play"

	^ MixedSound new
		add: (self bachFugueVoice1On: FMSound oboe1) pan: 0.2;
		add: (self bachFugueVoice2On: FMSound organ1) pan: 0.8;
		add: (self bachFugueVoice3On: PluckedSound default) pan: 0.4;
		add: (self bachFugueVoice4On: FMSound brass1) pan: 0.6.

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> storeFiledInSound: snd named: sndName [
	"Store the given sound in the sound library. Use the given name if it isn't in use, otherwise ask the user what to do."

	| choice i |
	(Sounds includesKey: sndName) ifFalse: [  "no name clash"
		Sounds at: sndName put: snd.
		^ self].

	(Sounds at: sndName) == UnloadedSnd ifTrue: [
		"re-loading a sound that was unloaded to save space"
		Sounds at: sndName put: snd.
		^ self].

	"the given sound name is already used"
	choice := UIManager default 
		chooseFrom: {'Replace the existing sound' translated. 'Rename the new sound' translated}
		title: ('"', sndName, '" ', 'has the same name as an existing sound' translated).
	(choice = 1) ifTrue: [
		Sounds at: sndName put: snd.
		^ self].
	(choice = 2) ifTrue: [
		i := 2.
		[Sounds includesKey: (sndName, ' v', i printString)] whileTrue: [i := i + 1].
		Sounds at: (sndName, ' v', i printString) put: snd].

]

{ #category : #examples }
AbstractSound class >> testFMInteractively [
	"Experiment with different settings of the FM modulation and multiplier settings interactively by moving the mouse. The top-left corner of the screen is 0 for both parameters. Stop when the mouse is pressed."
	"AbstractSound testFMInteractively"

	| s mousePt lastVal status mod ratio |
	SoundPlayer startPlayerProcessBufferSize: 1100 rate: 11025 stereo: false.
	s := FMSound pitch: 440.0 dur: 200.0 loudness: 0.2.

	SoundPlayer playSound: s.
	lastVal := nil.
	[Sensor anyButtonPressed] whileFalse: [
		mousePt := Sensor cursorPoint.
		mousePt ~= lastVal ifTrue: [
			mod := mousePt x asFloat / 20.0.
			ratio := mousePt y asFloat / 20.0.
			s modulation: mod ratio: ratio.
			lastVal := mousePt.
			status :=
'mod: ', mod printString, '
ratio: ', ratio printString.
			status displayOn: Display at: 10@10]].

	SoundPlayer shutDown.

]

{ #category : #'primitive generation' }
AbstractSound class >> translatedPrimitives [
	^#(
		(FMSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(PluckedSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(LoopedSampledSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(SampledSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(ReverbSound applyReverbTo:startingAt:count:)
	).

]

{ #category : #'examples-bach fugue' }
AbstractSound class >> unloadSampledTimbres [
	"This can be done to unload those bulky sampled timbres to shrink the image. The unloaded sounds are replaced by a well-known 'unloaded sound' object to enable the unloaded sounds to be detected when the process is reversed."
	"AbstractSound unloadSampledTimbres"

	Sounds keysAndValuesDo: [:soundName : sound|
		((sound isKindOf: SampledInstrument) or:
		 [sound isKindOf: LoopedSampledSound]) ifTrue: [
			Sounds at: soundName put: self unloadedSound]].
	self updateScorePlayers.
	Smalltalk garbageCollect.

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> unloadSoundNamed: soundName [

	(Sounds includesKey: soundName) ifTrue: [
		Sounds at: soundName put: self unloadedSound].
	self updateScorePlayers.

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> unloadedSound [
	"Answer a sound to be used as the place-holder for sounds that have been unloaded."

	UnloadedSnd ifNil: [UnloadedSnd := UnloadedSound default copy].
	^ UnloadedSnd

]

{ #category : #'sound library' }
AbstractSound class >> updateFMSounds [
	"AbstractSound updateFMSounds"

	Sounds keys do: [:k |
		((Sounds at: k) isKindOf: FMSound) ifTrue: [
			Sounds removeKey: k ifAbsent: []]].

	(FMSound class organization listAtCategoryNamed: #instruments) do:
		[:sel | Sounds at: sel asString put: (FMSound perform: sel)].

]

{ #category : #'sound library-file in/out' }
AbstractSound class >> updateScorePlayers [
	| soundsBeingEdited |
	"Force all ScorePlayers to update their instrument list from the sound library. This may done after loading, unloading, or replacing a sound to make all ScorePlayers feel the change."

	ScorePlayer allSubInstancesDo: [:p | p pause].
	SoundPlayer shutDown.
	Smalltalk globals at: #EnvelopeEditorMorph ifPresent: [ :class |
		soundsBeingEdited := class allSubInstances
			collect: [:ed | ed soundBeingEdited ] ].
	Smalltalk globals at: #ScorePlayerMorph ifPresent: [ :class |
		class allSubInstancesDo:
			[:p | p updateInstrumentsFromLibraryExcept: soundsBeingEdited ] ]
]

{ #category : #composition }
AbstractSound >> + aSound [
	"Return the mix of the receiver and the argument sound."

	^(MixedSound new)
		add: self;
		add: aSound;
		yourself

]

{ #category : #composition }
AbstractSound >> , aSound [
	"Return the concatenation of the receiver and the argument sound."

	^(SequentialSound new)
		add: self;
		add: aSound;
		yourself
]

{ #category : #envelopes }
AbstractSound >> addEnvelope: anEnvelope [
	"Add the given envelope to my envelopes list."

	anEnvelope target: self.
	envelopes := envelopes copyWith: anEnvelope.

]

{ #category : #volume }
AbstractSound >> adjustVolumeTo: vol overMSecs: mSecs [
	"Adjust the volume of this sound to the given volume, a number in the range [0.0..1.0], over the given number of milliseconds. The volume will be changed a little bit on each sample until the desired volume is reached."

	| newScaledVol |

	self flag: #bob.		"I removed the upper limit to allow making sounds louder. hmm..."

	newScaledVol := (32768.0 * vol) truncated.
	newScaledVol = scaledVol ifTrue: [^ self].
	scaledVolLimit := newScaledVol.
	"scaledVolLimit > ScaleFactor ifTrue: [scaledVolLimit := ScaleFactor]."
	scaledVolLimit < 0 ifTrue: [scaledVolLimit := 0].
	mSecs = 0
		ifTrue: [  "change immediately"
			scaledVol := scaledVolLimit.
			scaledVolIncr := 0]
		ifFalse: [
			scaledVolIncr :=
				((scaledVolLimit - scaledVol) * 1000) // (self samplingRate * mSecs)].

]

{ #category : #conversion }
AbstractSound >> asSampledSound [
	"Answer a SampledSound containing my samples. If the receiver is some kind of sampled sound, the resulting SampledSound will have the same original sampling rate as the receiver."

	^ SampledSound samples: self samples samplingRate: self originalSamplingRate

]

{ #category : #composition }
AbstractSound >> asSound [

	^ self

]

{ #category : #playing }
AbstractSound >> computeSamplesForSeconds: seconds [
	"Compute the samples of this sound without outputting them, and return the resulting buffer of samples."

	| buf |
	self reset.
	buf := SoundBuffer newStereoSampleCount: (self samplingRate * seconds) asInteger.
	self playSampleCount: buf stereoSampleCount into: buf startingAt: 1.
	^ buf

]

{ #category : #'sampling rates' }
AbstractSound >> controlRate [
	"Answer the number of control changes per second."

	^ 100

]

{ #category : #copying }
AbstractSound >> copyEnvelopes [
	"Private! Support for copying. Copy my envelopes."

	envelopes := envelopes collect: [:e | e copy target: self].

]

{ #category : #composition }
AbstractSound >> delayedBy: seconds [
	"Return a composite sound consisting of a rest for the given amount of time followed by the receiver."

	^ (RestSound dur: seconds), self

]

{ #category : #'sound generation' }
AbstractSound >> doControl [
	"Update the control parameters of this sound using its envelopes, if any."
	"Note: This is only called at a small fraction of the sampling rate."

	| pitchModOrRatioChange |
	envelopes size > 0 ifTrue: [
		pitchModOrRatioChange := false.
		1 to: envelopes size do: [:i |
			((envelopes at: i) updateTargetAt: mSecsSinceStart)
				ifTrue: [pitchModOrRatioChange := true]].
		pitchModOrRatioChange ifTrue: [self internalizeModulationAndRatio]].
	mSecsSinceStart := mSecsSinceStart + (1000 // self controlRate).

]

{ #category : #initialization }
AbstractSound >> duration: seconds [
	"Scale my envelopes to the given duration. Subclasses overriding this method should include a resend to super."

	envelopes do: [:e | e duration: seconds].

]

{ #category : #envelopes }
AbstractSound >> envelopes [
	"Return my collection of envelopes."

	^ envelopes

]

{ #category : #volume }
AbstractSound >> initialVolume: vol [
	"Set the initial volume of this sound to the given volume, a number in the range [0.0..1.0]."

	scaledVol := (((vol asFloat min: 1.0) max: 0.0) * ScaleFactor) rounded.
	scaledVolLimit := scaledVol.
	scaledVolIncr := 0.

]

{ #category : #initialization }
AbstractSound >> initialize [
	super initialize.
	envelopes := #().
	mSecsSinceStart := 0.
	samplesUntilNextControl := 0.
	scaledVol := (1.0 * ScaleFactor) rounded.
	scaledVolIncr := 0.
	scaledVolLimit := scaledVol.

]

{ #category : #'sound generation' }
AbstractSound >> internalizeModulationAndRatio [
	"Overridden by FMSound. This default implementation does nothing."

]

{ #category : #playing }
AbstractSound >> isPlaying [
	"Return true if the receiver is currently playing"
	^ SoundPlayer isPlaying: self
]

{ #category : #accessing }
AbstractSound >> isStereo [
	"Answer true if this sound has distinct left and right channels. (Every sound plays into a stereo sample buffer, but most sounds, which produce exactly the same samples on both channels, are not stereo.)"

	^ false

]

{ #category : #volume }
AbstractSound >> loudness [
	"Answer the current volume setting for this sound."

	^ scaledVol asFloat / ScaleFactor asFloat
]

{ #category : #initialization }
AbstractSound >> loudness: aNumber [
	"Initialize my volume envelopes and initial volume. Subclasses overriding this method should include a resend to super."

	| vol |
	vol := (aNumber asFloat max: 0.0) min: 1.0.
	envelopes do: [:e |
		(e isKindOf: VolumeEnvelope) ifTrue: [e scale: vol]].
	self initialVolume: vol.

]

{ #category : #playing }
AbstractSound >> millisecondsSinceStart [

	^ mSecsSinceStart
]

{ #category : #'sound generation' }
AbstractSound >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Mix the given number of samples with the samples already in the given buffer starting at the given index. Assume that the buffer size is at least (index + count) - 1. The leftVol and rightVol parameters determine the volume of the sound in each channel, where 0 is silence and ScaleFactor is full volume."

	self subclassResponsibility.

]

{ #category : #initialization }
AbstractSound >> nameOrNumberToPitch: aStringOrNumber [
	"Answer the pitch in cycles/second for the given pitch specification. The specification can be either a numeric pitch or pitch name such as 'c4'."

	aStringOrNumber isNumber
		ifTrue: [^ aStringOrNumber asFloat]
		ifFalse: [^ AbstractSound pitchForName: aStringOrNumber]

]

{ #category : #'sampling rates' }
AbstractSound >> originalSamplingRate [
	"For sampled sounds, answer the sampling rate used to record the stored samples. For other sounds, this is the same as the playback sampling rate."

	^ SoundPlayer samplingRate

]

{ #category : #playing }
AbstractSound >> pause [
	"Pause this sound. It can be resumed from this point, or reset and resumed to start from the beginning."

	SoundPlayer pauseSound: self.
]

{ #category : #playing }
AbstractSound >> play [
	"Play this sound to the sound output port in real time."

	SoundPlayer playSound: self.
]

{ #category : #playing }
AbstractSound >> playAndWaitUntilDone [
	"Play this sound to the sound ouput port and wait until it has finished playing before returning."

	SoundPlayer playSound: self.
	[self samplesRemaining > 0] whileTrue.
	(Delay forMilliseconds: 2 * SoundPlayer bufferMSecs) wait.  "ensure last buffer has been output"

]

{ #category : #playing }
AbstractSound >> playChromaticRunFrom: startPitch to: endPitch [
	"Play a fast chromatic run between the given pitches. Useful for auditioning a sound."

	(AbstractSound chromaticRunFrom: startPitch to: endPitch on: self) play.

]

{ #category : #playing }
AbstractSound >> playSampleCount: n into: aSoundBuffer startingAt: startIndex [
	"Mix the next n samples of this sound into the given buffer starting at the given index. Update the receiver's control parameters periodically."

	| fullVol samplesBetweenControlUpdates pastEnd i remainingSamples count |
	fullVol := AbstractSound scaleFactor.
	samplesBetweenControlUpdates := self samplingRate // self controlRate.
	pastEnd := startIndex + n.  "index just after the last sample"
	i := startIndex.
	[i < pastEnd] whileTrue: [
		remainingSamples := self samplesRemaining.
		remainingSamples <= 0 ifTrue: [^ self].
		count := pastEnd - i.
		samplesUntilNextControl < count ifTrue: [count := samplesUntilNextControl].
		remainingSamples < count ifTrue: [count := remainingSamples].
		self mixSampleCount: count into: aSoundBuffer startingAt: i leftVol: fullVol rightVol: fullVol.
		samplesUntilNextControl := samplesUntilNextControl - count.
		samplesUntilNextControl <= 0 ifTrue: [
			self doControl.
			samplesUntilNextControl := samplesBetweenControlUpdates].
		i := i + count].

]

{ #category : #playing }
AbstractSound >> playSilently [
	"Compute the samples of this sound without outputting them. Used for performance analysis."

	| bufSize buf |
	self reset.
	bufSize := self samplingRate // 10.
	buf := SoundBuffer newStereoSampleCount: bufSize.
	[self samplesRemaining > 0] whileTrue: [
		buf primFill: 0.
		self playSampleCount: bufSize into: buf startingAt: 1].

]

{ #category : #playing }
AbstractSound >> playSilentlyUntil: startTime [
	"Compute the samples of this sound without outputting them. Used to fast foward to a particular starting time. The start time is given in seconds."

	| buf startSample nextSample samplesRemaining n |
	self reset.
	buf := SoundBuffer newStereoSampleCount: (self samplingRate // 10).
	startSample := (startTime * self samplingRate) asInteger.
	nextSample := 1.
	[self samplesRemaining > 0] whileTrue: [
		nextSample >= startSample ifTrue: [^ self].
		samplesRemaining := startSample - nextSample.
		samplesRemaining > buf stereoSampleCount
			ifTrue: [n := buf stereoSampleCount]
			ifFalse: [n := samplesRemaining].
		self playSampleCount: n into: buf startingAt: 1.
		nextSample := nextSample + n].

]

{ #category : #copying }
AbstractSound >> postCopy [
	"A sound should copy all of the state needed to play itself, allowing two copies of a sound to play at the same time. These semantics require a recursive copy but only down to the level of immutable data. For example, a SampledSound need not copy its sample buffer. Subclasses overriding this method should include a resend to super."

	super postCopy.
	self copyEnvelopes

]

{ #category : #envelopes }
AbstractSound >> removeAllEnvelopes [
	"Remove all envelopes from my envelopes list."

	envelopes := #().

]

{ #category : #envelopes }
AbstractSound >> removeEnvelope: anEnvelope [
	"Remove the given envelope from my envelopes list."

	envelopes := envelopes copyWithout: anEnvelope.

]

{ #category : #'sound generation' }
AbstractSound >> reset [
	"Reset my internal state for a replay. Methods that override this method should do super reset."

	mSecsSinceStart := 0.
	samplesUntilNextControl := 0.
	envelopes size > 0 ifTrue: [
		1 to: envelopes size do: [:i | (envelopes at: i) reset]].

]

{ #category : #playing }
AbstractSound >> resumePlaying [
	"Resume playing this sound from where it last stopped."

	SoundPlayer resumePlaying: self.

]

{ #category : #playing }
AbstractSound >> samples [
	"Answer a monophonic sample buffer containing my samples. The left and write channels are merged."
	"Warning: This may require a lot of memory!"

	^ (self computeSamplesForSeconds: self duration) mergeStereo

]

{ #category : #'sound generation' }
AbstractSound >> samplesRemaining [
	"Answer the number of samples remaining until the end of this sound. A sound with an indefinite ending time should answer some large integer such as 1000000."

	^ 1000000

]

{ #category : #'sampling rates' }
AbstractSound >> samplingRate [
	"Answer the sampling rate in samples per second."

	^ SoundPlayer samplingRate

]

{ #category : #initialization }
AbstractSound >> setPitch: pitchNameOrNumber dur: d loudness: l [
	"Initialize my envelopes for the given parameters. Subclasses overriding this method should include a resend to super."

	| p |
	p := self nameOrNumberToPitch: pitchNameOrNumber.
	envelopes do: [:e |
		e volume: l.
		e centerPitch: p].
	self initialVolume: l.
	self duration: d.

]

{ #category : #initialization }
AbstractSound >> soundForMidiKey: midiKey dur: d loudness: l [
	"Answer an initialized sound object (a copy of the receiver) that generates a note for the given MIDI key (in the range 0..127), duration (in seconds), and loudness (in the range 0.0 to 1.0)."

	^ self copy
		setPitch: (AbstractSound pitchForMIDIKey: midiKey)
		dur: d
		loudness: l

]

{ #category : #initialization }
AbstractSound >> soundForPitch: pitchNameOrNumber dur: d loudness: l [
	"Answer an initialized sound object (a copy of the receiver) that generates a note of the given pitch, duration, and loudness. Pitch may be a numeric pitch or a string pitch name such as 'c4'. Duration is in seconds and loudness is in the range 0.0 to 1.0."

	^ self copy setPitch: pitchNameOrNumber dur: d loudness: l

]

{ #category : #copying }
AbstractSound >> sounds [
	"Allows simple sounds to behave as, eg, sequential sounds"

	^ Array with: self
]

{ #category : #'sound generation' }
AbstractSound >> stopAfterMSecs: mSecs [
	"Terminate this sound this note after the given number of milliseconds. This default implementation does nothing."

]

{ #category : #'sound generation' }
AbstractSound >> stopGracefully [
	"End this note with a graceful decay. If the note has envelopes, determine the decay time from its envelopes."

	| decayInMs env |
	envelopes isEmpty
		ifTrue: [
			self adjustVolumeTo: 0 overMSecs: 10.
			decayInMs := 10]
		ifFalse: [
			env := envelopes first.
			decayInMs := env attackTime + env decayTime].
	self duration: (mSecsSinceStart + decayInMs) / 1000.0.
	self stopAfterMSecs: decayInMs.

]

{ #category : #'file i/o' }
AbstractSound >> storeAIFFOnFileNamed: fileName [
	"Store this sound as a AIFF file of the given name."

	| f |
	f := (FileStream fileNamed: fileName) binary.
	[ self storeAIFFSamplesOn: f ]
		ensure: [ f close ]

]

{ #category : #'file i/o' }
AbstractSound >> storeAIFFSamplesOn: aBinaryStream [
	"Store this sound as a 16-bit AIFF file at the current SoundPlayer sampling rate. Store both channels if self isStereo is true; otherwise, store the left channel only as a mono sound."

	| samplesToStore channelCount dataByteCount |
	samplesToStore := (self duration * self samplingRate) ceiling.
	channelCount := self isStereo ifTrue: [2] ifFalse: [1].
	dataByteCount := samplesToStore * channelCount * 2.

	"write AIFF file header:"
	aBinaryStream nextPutAll: 'FORM' asByteArray.
	aBinaryStream nextInt32Put: ((7 * 4) + 18) + dataByteCount.
	aBinaryStream nextPutAll: 'AIFF' asByteArray.
	aBinaryStream nextPutAll: 'COMM' asByteArray.
	aBinaryStream nextInt32Put: 18.
	aBinaryStream nextNumber: 2 put: channelCount.
	aBinaryStream nextInt32Put: samplesToStore.
	aBinaryStream nextNumber: 2 put: 16.  "bits/sample"
	self storeExtendedFloat: self samplingRate on: aBinaryStream.
	aBinaryStream nextPutAll: 'SSND' asByteArray.
	aBinaryStream nextInt32Put: dataByteCount + 8.
	aBinaryStream nextInt32Put: 0.
	aBinaryStream nextInt32Put: 0.

	"write data:"
	self storeSampleCount: samplesToStore bigEndian: true on: aBinaryStream.

]

{ #category : #'file i/o' }
AbstractSound >> storeExtendedFloat: aNumber on: aBinaryStream [
	"Store an Apple extended-precision 80-bit floating point number on the given stream."
	"Details: I could not find the specification for this format, so constants were determined empirically based on assumption of 1-bit sign, 15-bit exponent, 64-bit mantissa. This format does not seem to have an implicit one before the mantissa as some float formats do."

	| n isNeg exp mantissa |
	n := aNumber asFloat.
	isNeg := false.
	n < 0.0 ifTrue: [
		n := 0.0 - n.
		isNeg := true].
	exp := (n log: 2.0) ceiling.
	mantissa := (n * (2 raisedTo: 64 - exp)) truncated.
	exp := exp + 16r4000 - 2.  "not sure why the -2 is needed..."
	isNeg ifTrue: [exp := exp bitOr: 16r8000].  "set sign bit"
	aBinaryStream nextPut: ((exp bitShift: -8) bitAnd: 16rFF).
	aBinaryStream nextPut: (exp bitAnd: 16rFF).
	8 to: 1 by: -1 do: [:i | aBinaryStream nextPut: (mantissa digitAt: i)].

]

{ #category : #'sound generation' }
AbstractSound >> storeSample: sample in: aSoundBuffer at: sliceIndex leftVol: leftVol rightVol: rightVol [
	"This method is provided for documentation. To gain 10% more speed when running sound generation in Smalltalk, this method is hand-inlined into all sound generation methods that use it."

	| i s |
		leftVol > 0 ifTrue: [
			i := (2 * sliceIndex) - 1.
			s := (aSoundBuffer at: i) + ((sample * leftVol) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].
		rightVol > 0 ifTrue: [
			i := 2 * sliceIndex.
			s := (aSoundBuffer at: i) + ((sample * rightVol) // ScaleFactor).
			s >  32767 ifTrue: [s :=  32767].  "clipping!"
			s < -32767 ifTrue: [s := -32767].  "clipping!"
			aSoundBuffer at: i put: s].

]

{ #category : #'file i/o' }
AbstractSound >> storeSampleCount: samplesToStore bigEndian: bigEndianFlag on: aBinaryStream [
	"Store my samples on the given stream at the current SoundPlayer sampling rate. If bigFlag is true, then each 16-bit sample is stored most-significant byte first (AIFF files), otherwise it is stored least-significant byte first (WAV files). If self isStereo is true, both channels are stored, creating a stereo file. Otherwise, only the left channel is stored, creating a mono file."

	| bufSize stereoBuffer reverseBytes |
	self reset.
	bufSize := (2 * self samplingRate rounded) min: samplesToStore.  "two second buffer"
	stereoBuffer := SoundBuffer newStereoSampleCount: bufSize.
	reverseBytes := bigEndianFlag ~= (SmalltalkImage current isBigEndian).

	'Storing audio...'
		displayProgressAt: Sensor cursorPoint
		from: 0 to: samplesToStore during: [:bar | | remaining out |
			remaining := samplesToStore.
			[remaining > 0] whileTrue: [
				bar value: samplesToStore - remaining.
				stereoBuffer primFill: 0.  "clear the buffer"
				self playSampleCount: (bufSize min: remaining) into: stereoBuffer startingAt: 1.
				out := self isStereo
						ifTrue: [stereoBuffer]
						ifFalse: [stereoBuffer extractLeftChannel].
				reverseBytes ifTrue: [out reverseEndianness].
				(aBinaryStream isKindOf: StandardFileStream)
					ifTrue: [  "optimization for files: write sound buffer directly to file"
						aBinaryStream next: (out size // 2) putAll: out startingAt: 1]  "size in words"
					ifFalse: [  "for non-file streams:"
						1 to: out monoSampleCount do: [:i | aBinaryStream int16: (out at: i)]].
				remaining := remaining - bufSize]].

]

{ #category : #'file i/o' }
AbstractSound >> storeSunAudioOnFileNamed: fileName [
	"Store this sound as an uncompressed Sun audio file of the given name."

	| f |
	f := (FileStream fileNamed: fileName) binary.
	[ self storeSunAudioSamplesOn: f]
		ensure: [ f close ]
]

{ #category : #'file i/o' }
AbstractSound >> storeSunAudioSamplesOn: aBinaryStream [
	"Store this sound as a 16-bit Sun audio file at the current SoundPlayer sampling rate. Store both channels if self isStereo is true; otherwise, store the left channel only as a mono sound."


	| samplesToStore channelCount dataByteCount |
	samplesToStore := (self duration * self samplingRate) ceiling.
	channelCount := self isStereo ifTrue: [2] ifFalse: [1].
	dataByteCount := samplesToStore * channelCount * 2.

	"write Sun audio file header"
	channelCount := self isStereo ifTrue: [2] ifFalse: [1].
	aBinaryStream nextPutAll: '.snd' asByteArray.
	aBinaryStream uint32: 24.	"header size in bytes"
	aBinaryStream uint32: dataByteCount.
	aBinaryStream uint32: 3.	"format: 16-bit linear"
	aBinaryStream uint32: self samplingRate truncated.
	aBinaryStream uint32: channelCount.

	"write data:"
	self storeSampleCount: samplesToStore bigEndian: true on: aBinaryStream.

]

{ #category : #'file i/o' }
AbstractSound >> storeWAVOnFileNamed: fileName [
	"Store this sound as a 16-bit Windows WAV file of the given name."

	| f |
	f := (FileStream fileNamed: fileName) binary.
	[ self storeWAVSamplesOn: f ]
		ensure: [ f close ]
]

{ #category : #'file i/o' }
AbstractSound >> storeWAVSamplesOn: aBinaryStream [
	"Store this sound as a 16-bit Windows WAV file at the current SoundPlayer sampling rate. Store both channels if self isStereo is true; otherwise, store the left channel only as a mono sound."

	| samplesToStore channelCount dataByteCount samplesPerSec bytesPerSec |
	samplesToStore := (self duration * self samplingRate) ceiling.
	channelCount := self isStereo ifTrue: [2] ifFalse: [1].
	dataByteCount := samplesToStore * channelCount * 2.
	samplesPerSec := self samplingRate rounded.
	bytesPerSec := samplesPerSec * channelCount * 2.

	"file header"
	aBinaryStream
		nextPutAll: 'RIFF' asByteArray;
		nextLittleEndianNumber: 4 put: dataByteCount + 36;	"total length of all chunks"
		nextPutAll: 'WAVE' asByteArray.

	"format chunk"
	aBinaryStream
		nextPutAll: 'fmt ' asByteArray;
		nextLittleEndianNumber: 4 put: 16;	"length of this chunk"
		nextLittleEndianNumber: 2 put: 1;	"format tag"
		nextLittleEndianNumber: 2 put: channelCount;
		nextLittleEndianNumber: 4 put: samplesPerSec;
		nextLittleEndianNumber: 4 put: bytesPerSec;
		nextLittleEndianNumber: 2 put: 4;	"alignment"
		nextLittleEndianNumber: 2 put: 16.	"bits per sample"

	"data chunk"
	aBinaryStream
		nextPutAll: 'data' asByteArray;
		nextLittleEndianNumber: 4 put: dataByteCount.  "length of this chunk"

	self storeSampleCount: samplesToStore bigEndian: false on: aBinaryStream.

]

{ #category : #'sound generation' }
AbstractSound >> updateVolume [
	"Increment the volume envelope of this sound. To avoid clicks, the volume envelope must be interpolated at the sampling rate, rather than just at the control rate like other envelopes. At the control rate, the volume envelope computes the slope and next target volume volume for the current segment of the envelope (i.e., it sets the rate of change for the volume parameter). When that target volume is reached, incrementing is stopped until a new increment is set."
	"This method is provided for documentation. To gain 10% more speed when running sound generation in Smalltalk, it is hand-inlined into all sound generation methods that use it."

		scaledVolIncr ~= 0 ifTrue: [
			scaledVol := scaledVol + scaledVolIncr.
			((scaledVolIncr > 0 and: [scaledVol >= scaledVolLimit]) or:
			 [scaledVolIncr < 0 and: [scaledVol <= scaledVolLimit]])
				ifTrue: [  "reached the limit; stop incrementing"
					scaledVol := scaledVolLimit.
					scaledVolIncr := 0]].

]

{ #category : #volume }
AbstractSound >> volumeEnvelopeScaledTo: scalePoint [
	"Return a collection of values representing my volume envelope scaled by the given point. The scale point's x component is pixels/second and its y component is the number of pixels for full volume."

	self error: 'not yet implemented'.

]
