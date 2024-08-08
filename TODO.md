#  Todo & Outline


##  Guideline: 
 -   Function first, then appearance


##  Feature Todo List:

Keyboard:

+   Lock button: press event, change appearance, comm with kb
        
+   MultiPress: re-implement hitTest, pick 'radius' of touch, key only store Note
    
    extract audio fcall to AudioEngine, (cancelled) kb access Note and call AudioEngine
    
+   Keymap class: store Notes & Color using coord(indep of Arr), generate from formula
    
-   (maybe)Kb Arrangement class: store layout & size, store axial vector, can calculate
        positions & sizes, type finite/inf
    
    (maybe)Kb 2d panning zooming, constraints, inertia
    
+   receive Keymap
    
    change LockButton to Notification scheme - why?
    
    draw key color
    
    
Control panel:

    Sound Bank chooser: choose file, read presets in file, form a list
    
    Preset picker: pick and store preset id, create Preset obj, send to AudioEngine
    
-   Keymap picker: add a 'choose file...' segment, when selected pop up file chooser (.ltn)
    
+   Keymap picker: builtin keymaps
    
-   (maybe)Kb Arrangement picker: pick between Luma and InfHex (for now)
    
    Master Vol slider: store val, comm with AudioEngine
    
+   Pitch Bend: store val, spring back, comm with AudioEngine


Tuning:
    
-   create 31edo sf2
    
    
AudioEngine:

    control volume, pitch bend, preset change
    

(maybe) extract all Default settings to Settings class


##  Art Design Todo List:

Keyboard:

2   Key: programmatically draw keys, design key shape and shadow, key glow color, key press
        animation?
        
    LockButton: auto hide(1. click to show 2. pause to show, play to hide), animation
        
Control panel:

  · steal picker menu & slider & scroller from FL
    OR fit in Apple aesthetics?
  · background img
        




use random access collection where element == key to store keys;

class TouchKeyMap

class KeyCollection
- add func keySpan(inRect:)-> touched(at: forRadius:)->Set<Keys>

+ use keyPressed: [UITouch: Set<Key>] to store pressed keys


use attach style with audioengine


migrate audio parameters update to AudioEngine, figure out a way to write #Selector from outer class


Prioritized:

31edo

load .ltn {
setup multiple channel stuff - figure out why tf channels dont work
auto scan file { icloud?, get file names, filter }
read file line by line
parse
}




+doing 31edo {
+   refract: audio call to audioengine
+   new state 'edo' of audioengine, only 12, 31 now
    when in 31, audioengine decide channel and determine pitchbend {
+       calculate it maybe do a lazy generated lookup
    }
+   set bitchbend control to change global pitchbend instead of chan0
    
+   then generalize to any edo
}

+ add tuning info to keymap instead of hardcode


solutions: - solved!!
1. use core audio
+. use multiple synths
3. just figure out the frickin channels
4. dont use midi at all - find another synth method
5. manual send noteOn noteOff - may work


bugs:
+. lockbutton note do not end
+. set keymap note do not end
3. in invalid preset new tuning do not apply - how to recreate?
4. switch preset app freeze - how to recreate?

