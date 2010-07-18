Class {
	#name : #PopUpChoiceMorph,
	#superclass : #StringMorph,
	#instVars : [
		'target',
		'actionSelector',
		'arguments',
		'getItemsSelector',
		'getItemsArgs',
		'choiceArgs'
	],
	#category : #SoundMorphicUserInterface
}

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> actionSelector [

	^ actionSelector

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> actionSelector: aSymbolOrString [

	(nil = aSymbolOrString or:
	 ['nil' = aSymbolOrString or:
	 [aSymbolOrString isEmpty]])
		ifTrue: [^ actionSelector := nil].

	actionSelector := aSymbolOrString asSymbol.

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> arguments [

	^ arguments

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> arguments: aCollection [

	arguments := aCollection asArray copy.

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> getItemsArgs [

	^ getItemsArgs

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> getItemsArgs: aCollection [

	getItemsArgs := aCollection asArray copy.

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> getItemsSelector [

	^ getItemsSelector

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> getItemsSelector: aSymbolOrString [

	(nil = aSymbolOrString or:
	 ['nil' = aSymbolOrString or:
	 [aSymbolOrString isEmpty]])
		ifTrue: [^ getItemsSelector := nil].

	getItemsSelector := aSymbolOrString asSymbol.

]

{ #category : #'event handling' }
PopUpChoiceMorph >> handlesMouseDown: evt [

	^ true

]

{ #category : #initialization }
PopUpChoiceMorph >> initialize [
"initialize the state of the receiver"
	super initialize.
""
	self contents: 'PopUpChoice of Colors'.
	target := Color.
	actionSelector := nil.
	arguments := EmptyArray.
	getItemsSelector := #colorNames.
	getItemsArgs := EmptyArray
]

{ #category : #'event handling' }
PopUpChoiceMorph >> mouseDown: evt [ 
	| items menu selectedItem |
	(target isNil or: [getItemsSelector isNil]) ifTrue: [^self].
	items := target perform: getItemsSelector withArguments: getItemsArgs.
	menu := CustomMenu new.
	items do: [:item | menu add: item action: item].
	selectedItem := menu startUp.
	selectedItem ifNil: [^self].
	self contentsClipped: selectedItem.	"Client can override this if necess"
	actionSelector ifNotNil: 
			[target perform: actionSelector
				withArguments: (arguments copyWith: selectedItem)]
]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> target [

	^ target

]

{ #category : #'as yet unclassified' }
PopUpChoiceMorph >> target: anObject [

	target := anObject

]

{ #category : #copying }
PopUpChoiceMorph >> veryDeepFixupWith: deepCopier [
	"If target and arguments fields were weakly copied, fix them here.  If they were in the tree being copied, fix them up, otherwise point to the originals!!"

super veryDeepFixupWith: deepCopier.
target := deepCopier references at: target ifAbsent: [target].
arguments := arguments collect: [:each |
	deepCopier references at: each ifAbsent: [each]].
getItemsArgs := getItemsArgs collect: [:each |
	deepCopier references at: each ifAbsent: [each]].
choiceArgs ifNotNil: [choiceArgs := choiceArgs collect: [:each |
	deepCopier references at: each ifAbsent: [each]]].
]

{ #category : #copying }
PopUpChoiceMorph >> veryDeepInner: deepCopier [
	"Copy all of my instance variables.  Some need to be not copied at all, but shared.  	Warning!!  Every instance variable defined in this class must be handled.  We must also implement veryDeepFixupWith:.  See DeepCopier class comment."

super veryDeepInner: deepCopier.
"target := target.		Weakly copied"
"actionSelector := actionSelector.		a Symbol"
"arguments := arguments.		All weakly copied"
"getItemsSelector := getItemsSelector.		a Symbol"
"getItemsArgs := getItemsArgs.		All weakly copied"
"choiceSelector := choiceSelector.		a Symbol"
choiceArgs := choiceArgs.		"All weakly copied"
     
]
