Extension { #name : #ProjectNavigationMorph }

{ #category : #'*sound' }
ProjectNavigationMorph >> buttonSound [

	| myButton m |

	myButton := RectangleMorph new 
		borderWidth: 1;
		cornerStyle: #rounded;
		borderColor: #raised;
		color: self colorForButtons;
		setBalloonText: 'Change sound volume' translated;
		on: #mouseDown send: #soundDownEvt:morph: to: self;
		on: #mouseStillDown send: #soundStillDownEvt:morph: to: self;
		on: #mouseUp send: #soundUpEvt:morph: to: self;
		yourself.

	myButton addMorph: (m := self speakerIcon lock).
	myButton extent: m extent + (myButton borderWidth + 6).
	m position: myButton center - (m extent // 2).
	^myButton

]

{ #category : #'*sound' }
ProjectNavigationMorph >> getSoundVolume [

	^SoundPlayer soundVolume average
]

{ #category : #'*sound' }
ProjectNavigationMorph >> setSoundVolume: x [

	SoundPlayer setVolumeLeft: x volumeRight: x.

]

{ #category : #'*sound' }
ProjectNavigationMorph >> soundDownEvt: a morph: b [

	soundSlider ifNotNil: [soundSlider delete].
	(soundSlider := RectangleMorph new)
		setProperty: #morphicLayerNumber toValue: 1;
		extent: b width @ (b width * 3);
		color: self colorForButtons;
		borderColor: #raised;
		bottomLeft: b boundsInWorld origin.
	soundSlider addMorph: (
		RectangleMorph new
			color: self colorForButtons;
			borderColor: #raised;
			extent: b width @ 8;
			center: soundSlider center x @ 
				(soundSlider bottom - (soundSlider height * self getSoundVolume) asInteger)
	).
	soundSlider openInWorld.
]

{ #category : #'*sound' }
ProjectNavigationMorph >> soundStillDownEvt: evt morph: b [

	| y pct |

	soundSlider ifNil: [^self].
	y := evt hand position y.
	(y between: soundSlider top and: soundSlider bottom) ifTrue: [
		pct := (soundSlider bottom - y) asFloat / soundSlider height.
		self setSoundVolume: pct.
		soundSlider firstSubmorph top: y - 5.
	]. 

]

{ #category : #'*sound' }
ProjectNavigationMorph >> soundUpEvt: a morph: b [

	soundSlider ifNotNil: [soundSlider delete].
	soundSlider := nil.
	Beeper beep 
]

{ #category : #'*sound' }
ProjectNavigationMorph >> speakerIcon [


	^ImageMorph new
			image: (
(Form
	extent: 19@18
	depth: 8
	fromArray: #( 0 0 1493172224 0 0 0 0 1493172224 0 0 0 138 1493172224 0 0 0 35509 2315255808 0 0 0 9090522 2315255808 0 0 0 2327173887 2315255819 0 0 138 3051028442 2315255819 0 0 1505080590 4294957786 2315255808 184549376 0 3053453311 4292532917 1493172224 184549376 0 1505080714 3048584629 1493172224 184549376 0 9079434 3048584629 1493172224 184549376 0 138 2327164341 1493172235 0 0 0 2324346293 1493172235 0 0 0 9079477 1493172224 0 0 0 35466 1493172224 0 0 0 138 0 0 0 0 0 0 0 0 0 0 0 0 0)
	offset: 0@0)
			);
			setBalloonText: 'Quiet';
			on: #mouseUp send: #yourself to: 1
	
]
