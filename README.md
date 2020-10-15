# Sound
An old package from Squeak and old versions of Pharo in need for love

## Quick Installation

Load the sound package baseline with the following script: 

```Smalltalk
Metacello new
   baseline: 'Sound';
   repository: 'github://pharo-contributions/Sound';
   load
```

then you have to enable the sound support through the Settings menu, under the Appearance category.

After that the samples in the Sound package are working - this requires some changes on the SDL2 bindings, so you need to use Pharo 9
Once loaded and enabled you might do the following in a playground: 

```Smalltalk
(FMSound lowMajorScaleOn: FMSound bass1) play
```

The most complicated sample is the bach fugue: 

```Smalltalk
AbstractSound stereoBachFugue play
```
