"
I am a tool for analyzing sound data from a microphone, CD, or other input source in real time. I have several display modes:

	signal		snapshots of the raw signal data as it arrives
	spectrum	frequency spectrum of the signal data as it arrives
	sonogram	scrolling plot of the frequency spectrum over time,
			      where the vertical axis is frequency, the horizontal
				  axis is time, and amount of energy at a given
				  frequency is shown as a grayscale value with
				  larger values being darker

To use this tool, be sure that you have selected the proper sound source using you host OS facilities. Set the desired sampling rate and FFT size (try 22050 samples/sec and an FFT size of 512) then click on the 'start' button. Use the slider to adjust the level so that the yellow level indicator peaks somewhere between the middle and the right edge at the maximum signal level.

SpectrumAnalyzerMorph new openInWorld 

Note that if the level meter peaks hit the right edge, you will get 'clipping', which creates a bunch of spurious high frequency noise in the frequency spectrum. If the display is set to 'signal' mode, you can actually see the tops and bottoms of the waveform being cut off when clipping occurs.

Many machines may not be able to perform spectrum analysis in real time, especially at higher sampling rates and larger FFT sizes. In both 'signal' and 'spectrum' modes, this tool will skip data to try to keep up with real time. However, in 'sonogram' mode it always processes all the data, even if it falls behind. This allows you to get a complete sonogram without dropouts even on a slower machine. However, as the sonogram display falls behind there will be a larger and larger time lag between when a sound is input and when it appears on the display.

The smaller the FFT size, the less frequency resolution you get. The lower the sampling rate, the less total frequency range you get. For an FFT size of N and a sampling rate of R, each of the N/2 'bins' of the frequency spectrum has a frequency resolution of R / N. For example, at a sampleing rate of 22050 samples/second, the total frequency range is 0 to 11025 Hz and an FFT of size 256 would divide this range into 128 bins (the output of an FFT of size N has N/2 bins), each of which covers a frequency band about 86 Hz wide.

To increase time resolution, increase the sampling rate and decrease the FFT size.

"
Class {
	#name : #SpectrumAnalyzerMorph,
	#superclass : #AlignmentMorph,
	#instVars : [
		'soundInput',
		'statusLight',
		'levelMeter',
		'graphMorph',
		'sonogramMorph',
		'fft',
		'displayType'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #private }
SpectrumAnalyzerMorph >> addButtonRow [

	| r |
	r := AlignmentMorph newRow vResizing: #shrinkWrap.
	r addMorphBack: (self buttonName: 'Menu' translated action: #invokeMenu).
	r addMorphBack: (Morph new extent: 4@1; color: Color transparent).
	r addMorphBack: (self buttonName: 'Start' translated action: #start).
	r addMorphBack: (Morph new extent: 4@1; color: Color transparent).
	r addMorphBack: (self buttonName: 'Stop' translated action: #stop).
	r addMorphBack: (Morph new extent: 12@1; color: Color transparent).
	r addMorphBack: self makeStatusLight.
	self addMorphBack: r.

]

{ #category : #private }
SpectrumAnalyzerMorph >> addLevelSlider [

	| levelSlider r |
	levelSlider := SimpleSliderMorph new
		color: color;
		extent: 100@2;
		target: soundInput;
		actionSelector: #recordLevel:;
		adjustToValue: soundInput recordLevel.
	r := AlignmentMorph newRow
		color: color;
		layoutInset: 0;
		wrapCentering: #center; cellPositioning: #leftCenter;
		hResizing: #shrinkWrap;
		vResizing: #rigid;
		height: 24.
	r addMorphBack: (StringMorph contents: '0 ').
	r addMorphBack: levelSlider.
	r addMorphBack: (StringMorph contents: ' 10').
	self addMorphBack: r.

]

{ #category : #private }
SpectrumAnalyzerMorph >> buttonName: aString action: aSymbol [

	^ SimpleButtonMorph new
		target: self;
		label: aString;
		actionSelector: aSymbol

]

{ #category : #initialization }
SpectrumAnalyzerMorph >> defaultBorderWidth [
"answer the default border width for the receiver"
	^ 2
]

{ #category : #'submorphs-add/remove' }
SpectrumAnalyzerMorph >> delete [
	"Turn off recording when this morph is deleted."

	super delete.
	soundInput stopRecording.

]

{ #category : #initialization }
SpectrumAnalyzerMorph >> initialize [
"initialize the state of the receiver"
	super initialize.
""
	self listDirection: #topToBottom.
	soundInput := SoundInputStream new samplingRate: 22050.
	fft := FFT new: 512.
	displayType := 'sonogram'.
	self hResizing: #shrinkWrap.
	self vResizing: #shrinkWrap.
	self addButtonRow.
	self addLevelSlider.
	self addMorphBack: self makeLevelMeter.
	self addMorphBack: (Morph new extent: 10 @ 10;
			 color: Color transparent).
	"spacer"
	self resetDisplay
]

{ #category : #'menu and buttons' }
SpectrumAnalyzerMorph >> invokeMenu [
	"Invoke the settings menu."

	| aMenu |
	aMenu := MenuMorph new target: self.
	aMenu addList:	{
		{'set sampling rate' translated.		#setSamplingRate}.
		{'set FFT size' translated.			#setFFTSize}.
		{'set display type' translated.		#setDisplayType}}.
	aMenu popUpInWorld
]

{ #category : #private }
SpectrumAnalyzerMorph >> makeLevelMeter [

	| outerBox |
	outerBox := BorderedMorph new extent: 125@14; color: Color lightGray.
	levelMeter := Morph new extent: 2@10; color: Color yellow.
	levelMeter position: outerBox topLeft + (2@2).
	outerBox addMorph: levelMeter.
	^ outerBox

]

{ #category : #private }
SpectrumAnalyzerMorph >> makeStatusLight [

	| s |
	statusLight := BorderedMorph new extent: 24@19.
	statusLight color: Color gray.
	s := StringMorph contents: 'On' translated.
	s position: statusLight center - (s extent // 2).
	statusLight addMorph: s.
	^ statusLight

]

{ #category : #private }
SpectrumAnalyzerMorph >> processBuffer: buf [ 
	"Analyze one buffer of data."

	| data |
	data := displayType = 'signal' 
		ifTrue: [buf]
		ifFalse: [fft transformDataFrom: buf startingAt: 1].
	graphMorph ifNotNil: 
			[graphMorph
				data: data;
				changed].
	sonogramMorph ifNotNil: 
			[data := data collect: [:v | v sqrt].	"square root compresses dynamic range"
			data /= 400.0.
			sonogramMorph plotColumn: (data copyFrom: 1 to: data size // 1)]
]

{ #category : #private }
SpectrumAnalyzerMorph >> removeAllDisplays [
	"Remove all currently showing displays."

	sonogramMorph ifNotNil: [sonogramMorph delete].
	graphMorph ifNotNil: [graphMorph delete].
	sonogramMorph := graphMorph := nil.

]

{ #category : #'menu and buttons' }
SpectrumAnalyzerMorph >> resetDisplay [
	"Recreate my display after changing some parameter such as FFT size."

	displayType = 'signal' ifTrue: [self showSignal].
	displayType = 'spectrum' ifTrue: [self showSpectrum].
	displayType = 'sonogram' ifTrue: [self showSonogram].

]

{ #category : #'menu and buttons' }
SpectrumAnalyzerMorph >> setDisplayType [
	"Set the display type."

	|  choices choice on |
	choices := #('signal' 'spectrum' 'sonogram').
	choice := MenuMorph 
				chooseFrom: choices values: choices lines: #() title:  ('display type (currently {1})' translated format:{displayType}).
	choice ifNil: [^ self].
	on := soundInput isRecording.
	self stop.
	displayType := choice.
	self resetDisplay.
	on ifTrue: [self start].


]

{ #category : #'menu and buttons' }
SpectrumAnalyzerMorph >> setFFTSize [
	"Set the size of the FFT used for frequency analysis."

	|  choices choice on  |
	choices := #(128 256 512 1024).
	choice := MenuMorph 
				chooseFrom: choices values: choices lines: #() title:  ('FFT size (currently {1})' translated format:{fft n}).
	choice ifNil: [^ self].	
	on := soundInput isRecording.
	self stop.
	fft := FFT new: choice.
	self resetDisplay.
	on ifTrue: [self start].

]

{ #category : #'menu and buttons' }
SpectrumAnalyzerMorph >> setSamplingRate [
	"Set the sampling rate to be used for incoming sound data."

	| aMenu rate on choices |
	choices := #(11025 22050 44100).
	rate := MenuMorph 
				chooseFrom: choices values: choices lines: #() title: ('Sampling rate (currently {1})' translated format:{soundInput samplingRate}).
	rate ifNil: [^ self].
	on := soundInput isRecording.
	self stop.
	soundInput samplingRate: rate.
	self resetDisplay.
	on ifTrue: [self start].


]

{ #category : #private }
SpectrumAnalyzerMorph >> showSignal [
	"Display the actual signal waveform."

	displayType := 'signal'.
	self removeAllDisplays.
	graphMorph := GraphMorph new.
	graphMorph extent: (400 + (2 * graphMorph borderWidth))@128.
	graphMorph data: (Array new: 100 withAll: 0).
	graphMorph color: (Color r: 0.8 g: 1.0 b: 1.0).
	self addMorphBack: graphMorph.
	self extent: 10@10.  "shrink to minimum size"

]

{ #category : #private }
SpectrumAnalyzerMorph >> showSonogram [
	"Display a sonogram showing the frequency spectrum versus time."

	| zeros h w |
	displayType := 'sonogram'.
	self removeAllDisplays.
	h := fft n // 2.
	h := h min: 512 max: 64.
	w := 400.
	sonogramMorph :=
		SonogramMorph new
			extent: w@h
			minVal: 0.0
			maxVal: 1.0
			scrollDelta: w.
	zeros := Array new: sonogramMorph height withAll: 0.
	sonogramMorph width timesRepeat: [sonogramMorph plotColumn: zeros].
	self addMorphBack: sonogramMorph.
	self extent: 10@10.  "shrink to minimum size"

]

{ #category : #private }
SpectrumAnalyzerMorph >> showSpectrum [
	"Display the frequency spectrum."

	displayType := 'spectrum'.
	self removeAllDisplays.
	graphMorph := GraphMorph new.
	graphMorph extent: ((fft n // 2) + (2 * graphMorph borderWidth))@128.
	graphMorph data: (Array new: fft n // 2 withAll: 0).
	self addMorphBack: graphMorph.
	self extent: 10@10.  "shrink to minimum size"

]

{ #category : #'stepping and presenter' }
SpectrumAnalyzerMorph >> start [
	"Start displaying sound data."

	displayType = 'signal'
		ifTrue: [soundInput bufferSize: graphMorph width - (2 * graphMorph borderWidth)]
		ifFalse: [soundInput bufferSize: fft n].
	soundInput startRecording.

]

{ #category : #'stepping and presenter' }
SpectrumAnalyzerMorph >> step [
	"Update the record light, level meter, and display."

	| w |
	"update the record light and level meter"
	soundInput isRecording
		ifTrue: [statusLight color: Color yellow]
		ifFalse: [statusLight color: Color gray].
	w := ((121 * soundInput meterLevel) // 100) max: 1.
	levelMeter width ~= w ifTrue: [levelMeter width: w].

	"update the display if any data is available"
	self updateDisplay.

]

{ #category : #testing }
SpectrumAnalyzerMorph >> stepTime [

	^ 0

]

{ #category : #'stepping and presenter' }
SpectrumAnalyzerMorph >> stop [
	"Stop displaying sound data."

	soundInput stopRecording.

]

{ #category : #'stepping and presenter' }
SpectrumAnalyzerMorph >> stopStepping [
	"Turn off recording."

	super stopStepping.
	soundInput stopRecording.

]

{ #category : #private }
SpectrumAnalyzerMorph >> updateDisplay [
	"Update the display if any data is available."

	| buf bufCount |
	soundInput bufferCount = 0 ifTrue: [^ self].

	graphMorph ifNotNil: [
		[soundInput bufferCount > 0] whileTrue: [
			"skip to the most recent buffer"
			buf := soundInput nextBufferOrNil].
		^ self processBuffer: buf].

	sonogramMorph ifNotNil: [
		"at small buffer sizes we have to update the sonogram in
		 batches or we may get behind; shoot for 8 updates/second"
		bufCount := (soundInput samplingRate / (8 * soundInput bufferSize)) truncated max: 1.
		[bufCount > 0 and: [soundInput bufferCount > 0]] whileTrue: [
			self processBuffer: (soundInput nextBufferOrNil)]].

]
