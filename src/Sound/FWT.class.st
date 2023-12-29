"
This class implements the Fast Wavelet Transform.  It follows Mac Cody's article in Dr. Dobb's Journal, April 1992.  See also... 
	http://www.dfw.net/~mcody/fwt/fwt.html

Notable features of his implementation include...
1.  The ability to generate a large family of wavelets (including the Haar (alpha=beta) and Daubechies) from two parameters, alpha and beta, which range between -pi and pi.
2.  All data arrays have 5 elements added on to allow for convolution overrun with filters up to 6 in length (the max for this implementation).
3.  After a forward transform, the detail coefficients of the deomposition are found in transform at: 2*i, for i = 1, 2, ... nLevels;  and the approximation coefficients are in transform at: (2*nLevels-1).  these together comprise the complete wavelet transform.

The following changes from cody's listings should also be noted...
1.  The three DotProduct routines have been merged into one.
2.  The four routines WaveletDecomposition, DecomposeBranches, WaveletReconstruction, ReconstructBranches have all been merged into transformForward:.
3.  All indexing follows the Smalltalk 1-to-N convention, naturally.
"
Class {
	#name : 'FWT',
	#superclass : 'Object',
	#instVars : [
		'alpha',
		'beta',
		'coeffs',
		'h',
		'g',
		'hTilde',
		'gTilde',
		'samples',
		'nSamples',
		'nLevels',
		'transform'
	],
	#category : 'Sound-Core',
	#package : 'Sound',
	#tag : 'Core'
}

{ #category : 'access' }
FWT >> coeffs [
	"Return all coefficients needed to reconstruct the original samples"
	| header csize strm |
	header := Array with: nSamples with: nLevels with: alpha with: beta.
	csize := header size.
	1 to: nLevels do: [:i | csize := csize + (transform at: i*2) size].
	csize := csize + (transform at: nLevels*2-1) size.
	coeffs := Array new: csize.
	strm := WriteStream on: coeffs.
	strm nextPutAll: header.
	1 to: nLevels do: [:i | strm nextPutAll: (transform at: i*2)].
	strm nextPutAll: (transform at: nLevels*2-1).
	^ coeffs
]

{ #category : 'access' }
FWT >> coeffs: coeffArray [
	"Initialize this instance from the given coeff array (including header)."
	| header strm |
	strm := ReadStream on: coeffArray.
	header := strm next: 4.
	self nSamples: header first nLevels: header second.
	self setAlpha: header third beta: header fourth.
	1 to: nLevels do: [:i | transform at: i*2 put: (strm next: (transform at: i*2) size)].
	transform at: nLevels*2-1 put: (strm next: (transform at: nLevels*2-1) size).
	strm atEnd ifFalse: [self error: 'Data size error'].

]

{ #category : 'computation' }
FWT >> convolveAndDec: inData dataLen: inLen filter: filter out: outData [
	"convolve the input sequence with the filter and decimate by two"
	| filtLen offset outi dotp |
	filtLen := filter size.
	outi := 1.
	1 to: inLen+9 by: 2 do:
		[:i | 
		i < filtLen
		ifTrue:
			[dotp := self dotpData: inData endIndex: i filter: filter
						start: 1 stop: i inc: 1]
		ifFalse:
			[i > (inLen+5)
			ifTrue:
				[offset := i - (inLen+5).
				dotp := self dotpData: inData endIndex: inLen+5 filter: filter
						start: 1+offset stop: filtLen inc: 1]
			ifFalse:
				[dotp := self dotpData: inData endIndex: i filter: filter
						start: 1 stop: filtLen inc: 1]].
		outData at: outi put: dotp.
		outi := outi + 1]
]

{ #category : 'computation' }
FWT >> convolveAndInt: inData dataLen: inLen filter: filter sumOutput:
sumOutput into: outData [
	"insert zeros between each element of the input sequence and
	   convolve with the filter to interpolate the data"
	| outi filtLen oddTerm evenTerm j |
	outi := 1.
	filtLen := filter size.

	"every other dot product interpolates the data"
	filtLen // 2 to: inLen + filtLen - 2 do:
		[:i |
		oddTerm := self dotpData: inData endIndex: i filter: filter
									start: 2 stop: filter size inc: 2.
		evenTerm := self dotpData: inData endIndex: i+1 filter: filter
									start: 1 stop: filter size inc: 2.
		sumOutput
			ifTrue:
				["summation with previous convolution if true"
				outData at: outi put: (outData at: outi) + oddTerm.
				outData at: outi+1 put: (outData at: outi+1) + evenTerm]
			ifFalse:
				["first convolution of pair if false"
				outData at: outi put: oddTerm.
				outData at: outi+1 put: evenTerm].
		outi := outi + 2].

	"Ought to be able to fit this last term into the above loop."
	j := inLen + filtLen - 1.
	oddTerm := self dotpData: inData endIndex: j filter: filter
									start: 2 stop: filter size inc: 2.
	sumOutput
		ifTrue: [outData at: outi put: (outData at: outi) + oddTerm]
		ifFalse: [outData at: outi put: oddTerm].

]

{ #category : 'computation' }
FWT >> dotpData: data endIndex: endIndex filter: filter start: start stop: stop inc: inc [
	| sum i j |
	sum := 0.0.
	j := endIndex.
	i := start.
	[i <= stop] whileTrue:
		[sum := sum + ((data at: j) * (filter at: i)).
		i := i + inc.
		j := j - 1].
	^ sum
]

{ #category : 'testing' }
FWT >> meanSquareError: otherData [
	"Return the mean-square error between the current sample array and
	some other data, presumably to evaluate a compression scheme."
	| topSum bottomSum pointDiff |
	topSum := bottomSum := 0.0.
	1 to: nSamples do:
		[:i |  pointDiff := (samples at: i) - (otherData at: i).
		topSum := topSum + (pointDiff * pointDiff).
		bottomSum := bottomSum + ((otherData at: i) * (otherData at: i))].
	^ topSum / bottomSum
]

{ #category : 'initialization' }
FWT >> nSamples: n nLevels: nLevs [
	"Initialize a wavelet transform."
	"Note the sample array size must be N + 5, where N is a multiple of 2^nLevels"
	| dyadSize |
	(n // (1 bitShift: nLevs)) > 0 ifFalse: [self error: 'Data size error'].
	(n \\ (1 bitShift: nLevs)) = 0 ifFalse: [self error: 'Data size error'].
	nSamples := n.
	samples := Array new: n + 5.
	nLevels := nLevs.
	transform := Array new: nLevels*2.  "Transformed data is stored as a tree of coeffs"
	dyadSize := nSamples.
	1 to: nLevels do:
		[:i |  dyadSize := dyadSize // 2.
		transform at: 2*i-1 put: (Array new: dyadSize + 5).
		transform at: 2*i put: (Array new: dyadSize + 5)]
]

{ #category : 'access' }
FWT >> samples [
	^ samples copyFrom: 1 to: nSamples
]

{ #category : 'access' }
FWT >> samples: anArray [
	1 to: anArray size do:
		[:i | samples at: i put: (anArray at: i)].
	nSamples+1 to: nSamples+5 do:
		[:i | samples at: i put: 0.0]
]

{ #category : 'initialization' }
FWT >> setAlpha: alph beta: bet [
	"Set alpha and beta, compute wavelet coeefs, and derive hFilter and lFilter"
	| tcosa tcosb tsina tsinb |
	alpha := alph.
	beta := bet.

	"WaveletCoeffs..."
	"precalculate cosine of alpha and sine of beta"
	tcosa := alpha cos.
	tcosb := beta cos.
	tsina := alpha sin.
	tsinb := beta sin.
	coeffs := Array new: 6.
	
	"calculate first two wavelet coefficients a := a(-2) and b := a(-1)"
	coeffs at: 1 put: ((1.0 + tcosa + tsina) * (1.0 - tcosb - tsinb)
					+ (2.0 * tsinb * tcosa)) / 4.0.
	coeffs at: 2 put: ((1.0 - tcosa + tsina) * (1.0 + tcosb - tsinb)
					- (2.0 * tsinb * tcosa)) / 4.0.

	"precalculate cosine and sine of alpha minus beta"
	tcosa := (alpha - beta) cos.
	tsina := (alpha - beta) sin.

	"calculate last four wavelet coefficients c := a(0), d := a(1), e := a(2), and f := a(3)"
	coeffs at: 3 put: (1.0 + tcosa + tsina) / 2.0.
	coeffs at: 4 put: (1.0 + tcosa - tsina) / 2.0.
	coeffs at: 5 put: 1.0 - (coeffs at: 1) - (coeffs at: 3).
	coeffs at: 6 put: 1.0 - (coeffs at: 2) - (coeffs at: 4).

	"MakeFiltersFromCoeffs..."
	"Select the non-zero wavelet coefficients"
	coeffs := coeffs copyFrom: (coeffs findFirst: [:c | c abs > 1.0e-14])
						to: (coeffs findLast: [:c | c abs > 1.0e-14]).

	"Form the low pass and high pass filters for decomposition"
	hTilde := coeffs reversed collect: [:c | c / 2.0].
	gTilde := coeffs collect: [:c | c / 2.0].
	1 to: gTilde size by: 2 do:
		[:i | gTilde at: i put: (gTilde at: i) negated].

	"Form the low pass and high pass filters for reconstruction"
	h := coeffs copy.
	g := coeffs reversed.
	2 to: g size by: 2 do:
		[:i | g at: i put: (g at: i) negated]

]

{ #category : 'computation' }
FWT >> transformForward: forward [
	| inData inLen outData |
	forward
	ifTrue:
		["first InData is input signal, following are intermediate approx coefficients"
		inData := samples.  inLen := nSamples.
		1 to: nLevels do:
			[:i |
			self convolveAndDec: inData dataLen: inLen
					filter: hTilde out: (transform at: 2*i-1).
			self convolveAndDec: inData dataLen: inLen
					filter: gTilde out: (transform at: 2*i).
			inData := transform at: 2*i-1.  inLen := inLen // 2]]
	ifFalse:
		[inLen := nSamples >> nLevels.
		"all but last outData are next higher intermediate approximations,
		last is final reconstruction of samples"
		nLevels to: 1 by: -1 do:
			[:i |
			outData := i = 1 ifTrue: [samples]
						ifFalse: [transform at: 2*(i-1)-1].
			self convolveAndInt: (transform at: 2*i-1) dataLen: inLen
					filter: h sumOutput: false into: outData.
			self convolveAndInt: (transform at: 2*i) dataLen: inLen
					filter: g sumOutput: true into: outData.
			inLen := inLen * 2]]

]
