#  Todo & Outline

# this file does not conform to Markdown format and is used by me as plain text file
# viewing this file through a MD previewer will cause confusion

##  Guideline: 
     function first, then appearance

Keyboard:

+   Lock button: press event, change appearance, comm with kb
        
+   MultiPress: re-implement hitTest, pick 'radius' of touch, key only store Note
    
+   extract audio fcall to AudioEngine, (cancelled) kb access Note and call AudioEngine
    
+   Keymap class: store Notes & Color using coord(indep of Arr), generate from formula
    
    (maybe)Kb Arrangement class: store layout & size, store axial vector, can calculate
        positions & sizes, type finite/inf
    
    (maybe)Kb 2d panning zooming, constraints, inertia
    
+   receive Keymap
    
x   change LockButton to Notification scheme - why?
    
+   draw key color
    
    
+## Control panel:

+   Sound Bank chooser: choose file, read presets in file, form a list
    
-   Keymap picker: add a 'choose file...' segment, when selected pop up file chooser (.ltn)

-   (maybe)Kb Arrangement picker: pick between Luma and InfHex (for now)
    
+   Preset picker: pick and store preset id, create Preset obj, send to AudioEngine
    
+   Keymap picker: builtin keymaps
    
+   Master Vol slider: store val, comm with AudioEngine
    
+   Pitch Bend: store val, spring back, comm with AudioEngine


Tuning:
    
+   create 31edo sf2
    
    
AudioEngine:

+   control volume, pitch bend, preset change
    

+   extract all Default settings to Settings class


x##  GUI Design:

Control panel:

  · steal picker menu & slider & scroller from FL
    OR fit in Apple aesthetics?
  · background img
        




+ use keyPressed: [UITouch: Set<Key>] to store pressed keys




+ migrate audio parameters update to AudioEngine, figure out a way to write #Selector from outer class




+ doing 31edo {
+   refract: audio call to audioengine
+   new state 'edo' of audioengine, only 12, 31 now
    when in 31, audioengine decide channel and determine pitchbend {
+       calculate it maybe do a lazy generated lookup
    }
+   set bitchbend control to change global pitchbend instead of chan0
    
+   then generalize to any edo
}

+ add tuning info to keymap instead of hardcode


31edo solutions: - solved!!
1. use core audio
+. use multiple synths
3. just figure out the frickin channels
4. dont use midi at all - find another synth method
5. manual send noteOn noteOff - may work


+## bugs:
+. lockbutton note do not end
+. set keymap note do not end
## 31edo tuning do not apply - when pitchbend changed
4. switch preset app freeze - how to recreate?


Preset class, in which the file url and preset number is stored
can add more info such as preset name


+## solve all Globals use case
keymap: needed by key to display key number
 + user-friendly key notion
pitch: noone need
velocity: keyboard need
preset: AE need


+## toggle multipress

x## warning: (how to recreate?)
no factory...

x## delete TypedNotif, just use post with object

+## init values literals in controlPanel separated

+## change preset related var to optional, init value sent by chooserControl

+## position new controls


+# remember data:
 use special api
 + soundfont file (check existence, if not, use default builtin sf2)
  + figure out why load fail
simple key-value
 + preset number (if soundfont changed, reset to 0)
 + keymap, layout, velocity, multi-press
 - keyboard position
 


MARK: when opening .ltn file and creating keymap object, use postfix to avoid collision

+# use FileManager to read file

+## parallelize soundfont loading, preset loading and key reassigning

+## need? .suitableForBookmarkFile

+## preview soundfont preset name
by scanning file and save that **together with the md5** to a .presetnames file
create new project for testing

+## preset names now depend on filesystem io to deliver between classes which is bad design

+## load preset names and menu index at start

+## soundfont chooser button label corrupted

x# structural rewrite: MVC, separate pure functions
 all init value should be `empty`, initialized by central(either stored value or defaults)
 see how others deal with this

+## control panel: add square-bg cog 'settings' button 

+### re-arrange ControlPanel codes

+## if file exists dont parse sf2

+## audio preset and edo does not init'ed when app start

## animated key press, 0.1s, ease out

+## move initialization to where data is stored!

+## presetIndex_Int unused
+## keyboard code ordering

+## pitch bend slider animation corrupted
 - dont know why certain syntax doesnt work

# settings
## settings & help viewcontroller

+## setting - hide lock button and use uncaught drag as panning indication

## setting - toggle drag note
 - when playing, dismiss the drag



## key color:
use full saturation color in code, multiply by a tint when rendering

## audio issue:
unison keys collide with each other
possible solution: use synth queue, send pitchbend every press



## load .ltn {
setup multiple channel stuff - figure out why tf channels dont work
auto scan file { icloud?, get file names, filter }
read file line by line
parse
}


## labeledcontrol: use recieved `frame` as including label and control, add `pct` var indicating
the percentage the control takes up



## record midi and cord shape



## some notifications still depend on userDefault access to deliver information
which is bad design and (?) costly


+# 1.0 release preparation
 + layout ui for different ratios
 + write help section
 + handle ui design
 + new setting: padding


- add lots of documentations

+ switch keymap keylabel type not applying

+ drag play note released too early

- keyboard add new member: keyLabelType

## re design touchedKeys data structure

+# memory leak

## help section paragraph spacing logic not ideal
