;;--;;--;;--;;--;;--;;--;;
;  
;   Copyright 2014  
;   Mind, Matter & Media Lab, Vanderbilt University.
;   This is a source file for the ViMAP open source project.
;   Principal Investigator: Pratim Sengupta 
;   Lead Developer: Mason Wright
;  
;   Simulations powered by NetLogo. 
;   The copyright information for NetLogo can be found here: 
;   https://ccl.northwestern.edu/netlogo/docs/copyright.html  
;   
;;--;;--;;--;;--;;--;;--;; 


breed [wabbits wabbit]
breed [blocks block]
breed [sensors sensor]
breed [agent-kinds agent-kind]
breed [args arg]
breed [flowers flower]
breed [birds bird]
breed [measurepoints measurepoint]
breed [deads dead]

measurepoints-own 
[ 
  tagentkind
  tcolor
  tcycles
  t-energy-avg
  t-population
  t-proboscis-avg
  t-watched-energy
  measurepoint-creator
]

patches-own [
  is-ant-nest
  is-depleted
  is-flying-ant-nest
]

flowers-own
[
  has-nectar
  is-long
  old-color
  countdown
]

wabbits-own 
[
  pen-was-down ;; if true, the pen was down before the wabbit wrapped around the screen. Only used for wrapping around (so you can
               ;; put the pen back down after the turtle wraps around, if and only if it was down before.
  agent-kind-string
  flag-counter ;; counts the number of flags/markers that have been dropped so far in the run
  
  energy
  is-long-beak
  forward-distance
  distfromlast
  NAN
  odistfromlast
  paint-color
  has-food
  bonus-speed
  secret-number
  repeat-num
  initial-x
  initial-y
  previous-x
  previous-y
  
]

deads-own
[countdown]

birds-own
[
    bird-index ;; used to prevent all birds from turning to face the same butterfly (the one with maximal color-distance from flower-color).
               ;; birds are immortal and indexed from 1-n. the bird with index i would turn to face the butterfly with ith-greatest 
               ;; color-distance from flower-color
]

agent-kinds-own 
[
  name
  methods-list
  primitives-list
]
args-own
[
  arg-type
  default-value
  max-value
  min-value
  enum-list
]

blocks-own  
[
  ; the name that will appear on the block
  block-name 
  arg-list
  is-observer
  is-basic
  is-set-update
  display-name
  return-type ; "int", "real", "boolean", or uninitialized to mean none
  label-after-arg ; label after first argument, for example, for infix blocks like "x + y", where "+" is a label
  category   ; the name of the block's category, from categories-list (if any)
]

sensors-own
[
  sensor-name
  sensor-type
]

globals
[
  future-x ;; tells what the wabbit's x-coordinate would be if it went forward the given distance
  
  number-of-steps
  x-for-draw ;; used for drawing numbers
  y-for-draw ;; used for drawing numbers
  color-for-draw
  
  ;;NEEDED FOR MEASURE LINKING
  measure-points
  
  eat-radius
  
  first-flag
  second-flag
  flag-distance
  
  wabbits-list
  wabbit-kind-list
  blocks-list ;; list of blocks used to populate the toolbars / palettes in Java construction-world
  sensors-list ;; list of sensors for Java construction-world
  agent-kind-list ;; list of agent-kind in the model (breeds)
  predicate-list
  chart-data-name-list
  comp-int-left-vars
  comp-vars-left-vars
  comp-vars-right-vars
  
  can-highlight-agents
  
  ; list of category names for blocks
  categories-list
  
  current-window-max-size
  current-window
  this-cycle-current
  
  measure-option-string-lists
  measure-option-command-list
  
  var-name-list
  
  flower-color
  reproduction-rate
  
  short-flower-label
  long-flower-label
                       
  last-cycle
  
  dead-duration
  butterfly-size
  baby-size
  
  flower-count
  flower-layout ; "random", "cluster", "long-short", or "long-short-both"
  
  called-set-name
]

;;;;;;;;;;;;;;;;;;;;;

to setup ;; sets up the screen
  clear-all
  set-defaults
  clear-drawing
  color-background-patches
  
  ;;NEEDED FOR MEASURE LINKING
  set measure-points []
  
  make-other-stuff
  make-observer
  create-chart-data-name-list
  create-agent-kind-list
  create-blocks-list
  create-sensors-list
  create-predicate-list
  create-comp-int-list
  create-comp-vars-lists
  create-categories-list
  create-measure-option-string-lists
  create-measure-option-command-list
  create-var-name-list
  
  highlight-animation
  prepare-change-energy
  prepare-lose-energy-forward-dist
  prepare-set-speed
  prepare-drink-nectar
  prepare-set-butterfly-color
  prepare-watch-random-butterfly
  prepare-set-flower-count
  prepare-set-flowers
  prepare-face-food-if-hungry
  prepare-random-turn
  prepare-die
  prepare-go-forward
  prepare-make-same-color-baby
  prepare-make-similar-color-baby
  prepare-set-proboscis
  
  reset-ticks    ;; creates ticks and initializes them to 0
end

to create-labels
  create-turtles 1
  [
     setxy -15 -20
     set color green
     set size 0
  ]
  set short-flower-label max-one-of turtles [who]
  
  create-turtles 1
  [
     setxy -15 -23
     set color green
     set size 0
  ]
  set long-flower-label max-one-of turtles [who]
  
  update-labels
end

to update-labels
  ask short-flower-label
  [set label (word "Short Flowers: " short-flowers)]
  ask long-flower-label
  [set label (word "Long Flowers: " long-flowers)]
end

to-report short-flowers
  report count flowers with [not is-long]
end

to-report long-flowers
  report count flowers with [is-long]
end

to create-var-name-list
  set var-name-list
  [
    "avg butterfly energy" 
    "butterfly population" 
    "avg proboscis length"
    "watched butterfly energy"
  ]
end

to setup-cycle
end

to takedown-cycle
  cycle-ended
  place-measure-point
  
  if not any? wabbits with [agent-kind-string = "butterflies"]
  [set last-cycle true]
end

to create-categories-list
  set categories-list [ "Control" "Movement" "Drawing" "Sensors" ]
end

to create-chart-data-name-list
  set chart-data-name-list []
end

to cycle-ended
  bird-cycle
  ask wabbits with [agent-kind-string = "butterflies"]
  [
    ; set energy energy - 1
    set label energy
    
    if energy <= 0
    [java-die]
    
    if size < butterfly-size
    [set size size + 0.1]
  ]
  
  ask flowers
  [
    if countdown != 0
    [
      set countdown countdown - 1
      if countdown = 0
      [
        get-nectar
      ]
    ]
  ]
  
  ask deads
  [
    set countdown countdown - 1
    if countdown < 0
    [die]
  ]
end

to bird-cycle
  ask birds
  [
    let chase false
    let target nobody
    if any? wabbits with [agent-kind-string = "butterflies"]
    [
      ; face the "bird-index"th greatest butterfly by color-distance from flower-color
      let butterflies sort-by [[new-color-distance] of ?1 > [new-color-distance] of ?2] (wabbits with [agent-kind-string = "butterflies"])
      
      ifelse length butterflies > bird-index - 1
      [set target item (bird-index - 1) butterflies]
      [set target last butterflies]
      
      let dist [new-color-distance] of target
     ; this is the old, more lenient code
     ; ifelse dist > 220
     ; [set chase true]
     ; [
     ;   ifelse dist > 180 and random 10 < 7
     ;   [set chase true]
     ;   [
     ;     ifelse dist > 140 and random 10 < 5
     ;     [set chase true]
     ;     [
     ;       if dist > 100 and random 10 < 2
     ;       [set chase true] 
     ;     ]
     ;   ]
     ; ]      
      
      ifelse dist > 180
      [set chase true]
      [
        ifelse dist > 140 and random 10 < 7
        [set chase true]
        [
          ifelse dist > 100 and random 10 < 5
          [set chase true]
          [
            ifelse dist > 60 and random 10 < 3
            [set chase true]
            [
              if dist > 40 and random 10 < 2
              [set chase true]
            ]
          ]
        ]
      ]
      
      ifelse chase
      [face target]
      [
        if random 10 < 3
        [
          right random 10
          left 10
        ]
      ]
    ]
    
    forward 3
    
    if chase
    [
      let nearby-radius 3
      if distance target <= nearby-radius
      [
        ask target
        [die]
      ]
    ]
  ]
end

to create-predicate-list
  set predicate-list ["nectar-here" "can-reproduce" "no-energy"]
end

; similar to create-predicate-list
to create-comp-int-list
  set comp-int-left-vars ["heading"]
end

; similar to create-predicate-list
to create-comp-vars-lists
  set comp-vars-left-vars ["heading"]
  set comp-vars-right-vars ["heading"]
end

to-report java-no-energy [aWho]
  if not any? wabbits with [who = aWho]
  [report false]
  if [agent-kind-string] of wabbit aWho != "butterflies"
  [report true]
  
  let result false
  ask wabbit aWho
  [set result energy <= 0]
  report result
end

to-report java-can-reproduce [aWho]  
  if not any? wabbits with [who = aWho]
  [report false]
  if [agent-kind-string] of wabbit aWho != "butterflies"
  [report false]
  
  let min-energy 5
  let result false
  ask wabbit aWho
  [set result energy > min-energy]
  report result
end

to-report java-heading [aWho]
  let result 0
  ask turtle aWho
  [set result heading]
  report result
end

to-report java-nectar-here [aWho]
  if not any? wabbits with [who = aWho]
  [report false]
  if [agent-kind-string] of wabbit aWho != "butterflies"
  [report false]
  
  let result false
  ask wabbit aWho
  [
    if any? flowers in-radius eat-radius with [has-nectar and not is-long]
    [set result true]
    
    if is-long-beak and any? flowers in-radius eat-radius with [has-nectar]
    [set result true]
  ]
  
  report result
end

to-report java-true [aWho]
  report true
end

to-report java-false [aWho]
  report false
end

to-report java-color-red [aWho]
  report [color] of turtle aWho = red
end

to-report java-past-halfway [aWho]
  report [xcor] of turtle aWho > 200
end

to reset
setup
end

to create-sensors-list
  set sensors-list []
end

to create-blocks-list
  set blocks-list []
  ask blocks [ht]
  ask args [ht]
end

to-report get-agent-kinds-as-csv
  let retn ""
  foreach agent-kind-list
  [
   set retn (word retn ([name] of ?) "," )
  ]
  report butlast retn
end

to-report get-list-as-csv [list-name]
  let result ""
  if length list-name = 0
  [report result]
  
  foreach list-name
  [
   set result (word result ? "," )
  ]
  report butlast result
end

to create-measure-option-string-lists
  set measure-option-string-lists []
  
  let tlist []
  set tlist lput "Average Energy" tlist
  set tlist lput "of Butterflies" tlist
  set measure-option-string-lists lput tlist measure-option-string-lists
  
  set tlist []
  set tlist lput "Total Number" tlist
  set tlist lput "of Butterflies" tlist
  set measure-option-string-lists lput tlist measure-option-string-lists
  
  set tlist []
  set tlist lput "Average" tlist 
  set tlist lput "Proboscis" tlist
  set tlist lput "Length" tlist
  set measure-option-string-lists lput tlist measure-option-string-lists
  
  set tlist []
  set tlist lput "Energy" tlist
  set tlist lput "of Watched" tlist
  set tlist lput "Butterfly" tlist
  set measure-option-string-lists lput tlist measure-option-string-lists
end

to create-measure-option-command-list
  set measure-option-command-list []
  set measure-option-command-list lput "set graph-type \"horizontal-lineup-height\" set ind-var-index 3 set dep-var-index 4 graph" measure-option-command-list
  set measure-option-command-list lput "set graph-type \"horizontal-lineup-height\" set ind-var-index 3 set dep-var-index 5 graph" measure-option-command-list
  set measure-option-command-list lput "set graph-type \"horizontal-lineup-height\" set ind-var-index 3 set dep-var-index 6 graph" measure-option-command-list
  set measure-option-command-list lput "set graph-type \"horizontal-lineup-height\" set ind-var-index 3 set dep-var-index 7 graph" measure-option-command-list
end

; graph-index is the index of the graph in measure-option-command-list and other lists
to highlight-agents-for-graph [graph-index a-agent-type]
  unhighlight-agents
end

to unhighlight-agents
end

; possibly remove.
; indirection primitive to take the place of "ask".
; does not throw an error if turtle a-who does not exist.
; example usage:
;    instead of:
;     ask turtle 1000 [forward 5] ; throws error if no turtle 1000
;    use:
;    do 1000 "forward 5" ; does nothing if no turtle 1000
to do [a-who command]
  if turtle a-who != nobody
  [
    ask turtle a-who
    [run command]
  ]
end

to highlight-animation
  unhighlight-agents
end

to-report random-color
  report rgb (random 256) (random 256) (random 256)
end

; deprecated. use new-color-distance instead.
; butterfly reporter
;to-report color-distance
;  let red-dist abs ((item 0 color) - (item 0 flower-color))
;  let green-dist abs ((item 1 color) - (item 1 flower-color))
;  let blue-dist abs ((item 2 color) - (item 2 flower-color))
;  report (red-dist + green-dist + blue-dist) / 3
;end

;***************************Create Vimap Block*****************************************
to prepare-set-speed
   create-blocks 1
  [
    set block-name "set-speed"
    set arg-list []
    hatch-args 1
    [
       set arg-type "int"
       set default-value 1
       set max-value 5
       set min-value 1
    ]
    set arg-list lput max-one-of args [who] arg-list
    set is-observer false
    set is-basic false
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "set-speed" primitives-list]
    
end
;define the function
to java-set-speed [value]
  set forward-distance value
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-lose-energy-forward-dist
  create-blocks 1
  [
    set block-name "lose-energy-forward-dist"
    set arg-list []
    set is-observer false
    set is-basic false
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "lose-energy-forward-dist" primitives-list]
    
end
;define the function
to java-lose-energy-forward-dist
  set energy energy - forward-distance
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-change-energy
  create-blocks 1
  [
    set block-name "change-energy"
    set arg-list []
    hatch-args 1
    [
      set arg-type "enum"
      set enum-list ["plus" "minus"]
    ]
    set arg-list lput max-one-of args [who] arg-list
    hatch-args 1
    [
       set arg-type "int"
       set default-value 1
       ; set max-value 5 ; this value is used without the lose-energy-forward-dist block
       set max-value 15
       set min-value 1
    ]
    set arg-list lput max-one-of args [who] arg-list
    set is-observer false
    set is-basic false
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "change-energy" primitives-list]
    
end
;define the function
to java-change-energy [operator-name change-value]
  if operator-name = "plus"
  [set energy energy + change-value]
  if operator-name = "minus"
  [set energy energy - change-value]
end
;**************************************************************************************

; butterfly procedure
;to java-lose-energy
;  set energy energy - 1
;end

; butterfly procedure
;to java-get-energy
;  set energy energy + 5
;end

; butterfly procedure

;***************************Create Vimap Block*****************************************
to prepare-drink-nectar
   create-blocks 1
  [
    set block-name "drink-nectar"
    set is-observer false
    set arg-list []
    set is-basic false
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "drink-nectar" primitives-list]
    
end
;define the function
to java-drink-nectar
  ; let gain-from-eat 2
  
  ifelse is-long-beak
  [
    if any? flowers in-radius eat-radius with [has-nectar]
    [
      let target min-one-of flowers with [has-nectar] [distance myself]
      ask target
      [lose-nectar]
      ; set energy energy + gain-from-eat
    ]
  ]
  [
    if any? flowers in-radius eat-radius with [has-nectar and not is-long]
    [
      let target min-one-of flowers with [has-nectar and not is-long] [distance myself]
      ask target
      [lose-nectar]
      ; set energy energy + gain-from-eat
    ]
  ]
end
;**************************************************************************************


; flower procedure
to lose-nectar
  if has-nectar
  [
    set old-color color
    set has-nectar false
    reduce-rgb-color
    set countdown 2
  ]
end

; flower procedure
to get-nectar
  if not has-nectar
  [
    set has-nectar true
    set color old-color
  ]
end

to reduce-rgb-color
  let r reduce-color-value item 0 color
  let g reduce-color-value item 1 color
  let b reduce-color-value item 2 color
  set color rgb r g b
end

to-report reduce-color-value [value]
  let delta 40
  let result 0
  if value - delta > 0
  [set result value - delta]
  report result
end
;***************************Create Vimap Block*****************************************
to prepare-random-turn
create-blocks 1
  [
    set block-name "random-turn"
    set is-observer false
    set is-basic true
    set arg-list []
    set category "Movement"
    ; other variables not applicable
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "random-turn" primitives-list]   
end
;define the function
to java-random-turn
  let max-turn 30
  right ((random (max-turn + 1)) - max-turn / 2)
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-die
create-blocks 1
  [
    set block-name "die"
    set is-observer false
    set is-basic true
    set arg-list []
    ; other variables not applicable
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "die" primitives-list]
end
;define the function
to java-die
  let long-beak is-long-beak
  
  hatch-deads 1
  [
    ifelse long-beak
    [set shape "butterfly-long"]
    [set shape "butterfly"]
    set color black
    set countdown dead-duration
  ]
  
  die
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-go-forward
create-blocks 1
  [
    set block-name "go-forward"
    set is-observer false
    set is-basic true
    set arg-list []
    set category "Movement"
    ; other variables not applicable
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "go-forward" primitives-list]
    
end
;define the function
to java-go-forward
  jump forward-distance
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-face-food-if-hungry
create-blocks 1
    [
    set block-name "face-food-if-hungry"
    set is-observer false
    set is-basic false
    set arg-list []
    set category "Movement"
    ; other variables not applicable
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "face-food-if-hungry" primitives-list]
    
end
;define the function
; butterfly primitive
to java-face-food-if-hungry
  ;let hungry-energy random 12 ; this value was used before butterflies lost energy proportional to their speed
  let hungry-energy random 36 ; use if butterflies lose their speed in energy each tick
  if energy <= hungry-energy
  [
    ifelse is-long-beak
    [
      if any? flowers with [has-nectar]
      [face min-one-of flowers with [has-nectar] [distance myself]]
    ]
    [
      if any? flowers with [has-nectar and not is-long]
      [face min-one-of flowers with [has-nectar and not is-long] [distance myself]]
    ]
  ]
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-set-butterfly-color
    create-blocks 1
  [
    set block-name "set-butterfly-color"
    set is-observer false
    set is-basic true
    set arg-list []
    hatch-args 1
    [
      set arg-type "enum"
      set enum-list ["red" "blue" "random"]
    ]
    set arg-list lput max-one-of args [who] arg-list
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "observer"]   
 [set primitives-list lput "set-butterfly-color" primitives-list]
    
end
;define the function
to java-set-butterfly-color [a-color]
  if a-color = "red"
  [
    ask wabbits with [agent-kind-string = "butterflies"]
    [set color rgb 255 0 0]
  ]
  if a-color = "blue"
  [
    ask wabbits with [agent-kind-string = "butterflies"]
    [set color rgb 0 0 255]
  ]
  if a-color = "random"
  [
    ask wabbits with [agent-kind-string = "butterflies"]
    [
      set color random-color
    ]
  ]
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-set-proboscis
create-blocks 1
  [
    set block-name "set-proboscis"
    set is-observer false
    set is-basic false
    set arg-list []
    hatch-args 1
    [
      set arg-type "enum"
      set enum-list ["long" "short" "either"]
    ]
    set arg-list lput max-one-of args [who] arg-list
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "observer"]   
 [set primitives-list lput "set-proboscis" primitives-list]
    
end
;define the function
to java-set-proboscis [proboscis]
  if proboscis = "long"
  [
    ask wabbits with [agent-kind-string = "butterflies"]
    [
      set is-long-beak true
      set shape "butterfly-long"
    ]
  ]
  if proboscis = "short"
  [
    ask wabbits with [agent-kind-string = "butterflies"]
    [
      set is-long-beak false
      set shape "butterfly"
    ]
  ]
  if proboscis = "either"
  [
    ask wabbits with [agent-kind-string = "butterflies"]
    [
      set is-long-beak false
      set shape "butterfly"
    ]
    ask n-of (count wabbits with [agent-kind-string = "butterflies"] / 2) wabbits with [agent-kind-string = "butterflies"]
    [
      set is-long-beak true
      set shape "butterfly-long"
    ]
  ]
end
;**************************************************************************************

to update-flowers
  ask flowers
  [die]
  
  create-flowers flower-count
  [
    setxy random-xcor random-ycor
    set color flower-color
    set old-color color
    set size 6
    set shape "flower"
    set is-long false
    set has-nectar true
    set countdown 0
  ]  
  
  update-flower-layout
end

to update-flower-layout
  if flower-layout = "random"
  [
    ask flowers
    [
      setxy random-xcor random-ycor
      set is-long true
      set shape "flower-long"
    ]
    ask n-of (count flowers / 2) flowers
    [
      set is-long false
      set shape "flower"
    ]
  ]
  
  if flower-layout = "cluster"
  [
    ; cluster in upper-right quadrant of screen
    ask flowers
    [
      set xcor random max-pxcor
      set ycor random max-pycor
      set is-long true
      set shape "flower-long"
    ]
    ask n-of (count flowers / 2) flowers
    [
      set is-long false
      set shape "flower"
    ]
  ]
  if flower-layout = "long-short"
  [
    ask flowers
    [
      set xcor random max-pxcor
      set ycor random max-pycor
      set is-long true
      set shape "flower-long"
    ]
    ask n-of (count flowers / 2) flowers
    [
      set xcor -1 * xcor
      set ycor -1 * ycor
      set is-long false
      set shape "flower"
    ]
  ]
  if flower-layout = "long-short-both"
  [
    ; layout: upper 2/3 of left third, middle 2/3 of middle third, lower 2/3 of right third
    let lefts n-of (count flowers / 3) flowers
    let centers n-of (count flowers / 3) flowers with [not member? self lefts]
    let rights flowers with [not member? self lefts and not member? self centers]
    
    let left-third-max-xcor min-pxcor + (world-width / 3)
    let right-third-min-xcor min-pxcor + (world-width * 2 / 3)
    let top-third-min-ycor min-pycor + (world-height * 2 / 3)
    let middle-third-min-ycor min-pycor + (world-height / 3)
    
    ask lefts
    [
      set xcor min-pxcor + random (world-width / 3)
      set ycor top-third-min-ycor + random (world-height / 3)
      set is-long true
      set shape "flower-long"
    ]
    ask centers
    [
      set xcor left-third-max-xcor + random (world-width / 3)
      set ycor middle-third-min-ycor + random (world-height / 3)
      set is-long false
      set shape "flower"
    ]
    ask rights
    [
      set xcor right-third-min-xcor + random (world-width / 3)
      set ycor min-pycor + random (world-height / 3)
      set is-long true
      set shape "flower-long"
    ]
    ask n-of (count rights / 2) rights
    [
      set is-long false
      set shape "flower"
    ]
  ]
  
  update-labels
end

;***************************Create Vimap Block*****************************************
to prepare-set-flower-count
   create-blocks 1
  [
    set block-name "set-flower-count"
    set arg-list []
    set is-basic false
    hatch-args 1
    [
       set arg-type "int"
       set default-value 10
       set max-value 15
       set min-value 8
    ]
    set arg-list lput max-one-of args [who] arg-list
    set is-observer true
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "observer"]   
 [set primitives-list lput "set-flower-count" primitives-list]
    
end
;define the function
to java-set-flower-count [value]
  set flower-count value
  update-flowers
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-set-flowers
 create-blocks 1
  [
    set block-name "set-flowers"
    set is-observer false
    set is-basic false
    set arg-list []
    hatch-args 1
    [
      set arg-type "enum"
      set enum-list ["random" "cluster" "long-short" "long-short-both"]
    ]
    set arg-list lput max-one-of args [who] arg-list
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "observer"]   
 [set primitives-list lput "set-flowers" primitives-list]
    
end
;define the function
; layout could be "random", "cluster", "long-short", or "long-short-both"
to java-set-flowers [layout]
  set flower-layout layout
  update-flower-layout
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-watch-random-butterfly
   create-blocks 1
  [
    set block-name "watch-random-butterfly"
    set is-observer true
    set is-basic false
    set arg-list []
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "observer"]   
 [set primitives-list lput "watch-random-butterfly" primitives-list]
    
end
;define the function
to java-watch-random-butterfly
clear-drawing
if any? wabbits with [agent-kind-string = "butterflies"]
[
  watch one-of wabbits with [agent-kind-string = "butterflies"]
  ask subject
  [pen-down]
]
end
;**************************************************************************************

;***************************Create Vimap Block*****************************************
to prepare-make-similar-color-baby
  create-blocks 1
  [
    set block-name "make-similar-color-baby"
    set is-observer false
    set is-basic false
    set arg-list []
    set category "Movement"
    ; other variables not applicable
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "make-similar-color-baby" primitives-list]
    
end
;define the function
; butterfly primitive
to java-make-similar-color-baby
  if random 100 < reproduction-rate
  [
    let my-color color
    let my-beak is-long-beak
    let my-forward-distance forward-distance
    hatch-wabbits 1
    [
      set agent-kind-string "butterflies"
      set color new-shifted-color my-color
      set is-long-beak my-beak
      set size baby-size
      set forward-distance my-forward-distance
      pen-up
    ]
  ]
end
;**************************************************************************************

to-report new-shifted-color [start-color]
  let result shifted-color start-color 80
  while [rgb-to-delta-e start-color result > 40]
    [show rgb-to-delta-e start-color result set result shifted-color start-color 40]
  report result
end

; do not use directly; is based on non-uniform RGB color model.
; call through new-shifted-color [start-color].
to-report shifted-color [my-old-color delta-max]
  let new-red shifted-color-element (item 0 my-old-color) delta-max
  let new-green shifted-color-element (item 1 my-old-color) delta-max
  let new-blue shifted-color-element (item 2 my-old-color) delta-max
  report rgb new-red new-green new-blue
end  

to-report shifted-color-element [old-color-element delta-max]
  let result old-color-element + (random (delta-max + 1)) - delta-max / 2
  set result min (list 255 result)
  set result max (list 0 result)
  report result
end

;***************************Create Vimap Block*****************************************
to prepare-make-same-color-baby
 create-blocks 1
  [
    set block-name "make-same-color-baby"
    set is-observer false
    set is-basic false
    set arg-list []
    set category "Movement"
    ; other variables not applicable
  ]
  set blocks-list lput max-one-of blocks [who] blocks-list
 ;Add it to the named agents' primitives list
 ask agent-kinds with [name = "butterflies"]   
 [set primitives-list lput "make-same-color-baby" primitives-list]
    
end
;define the function
; butterfly primitive
to java-make-same-color-baby
  if random 100 < reproduction-rate
  [
    let my-color color
    let my-beak is-long-beak
    let my-forward-distance forward-distance
    hatch-wabbits 1
    [
      set agent-kind-string "butterflies"
      set color my-color
      set is-long-beak my-beak
      set size baby-size
      set forward-distance my-forward-distance
      pen-up
    ]
  ]
end
;**************************************************************************************

to create-agent-kind-list
  set agent-kind-list [] 
  
    ;;;;; PUT AGENT TYPE DEFINITIONS HERE: ;;;;;
    
  
  create-agent-kinds 1
  [
    set name "butterflies"
    
    set methods-list []
    set methods-list lput "go" methods-list
     set methods-list lput "setup" methods-list
    
    set primitives-list []
;    set primitives-list lput "change-energy" primitives-list
;    set primitives-list lput "lose-energy-forward-dist" primitives-list
;    set primitives-list lput "set-speed" primitives-list
;    set primitives-list lput "drink-nectar" primitives-list
;    set primitives-list lput "face-food-if-hungry" primitives-list
;    set primitives-list lput "random-turn" primitives-list
;    set primitives-list lput "die" primitives-list
;    set primitives-list lput "go-forward" primitives-list
;    set primitives-list lput "make-same-color-baby" primitives-list
;    set primitives-list lput "make-similar-color-baby" primitives-list
  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
 
 create-agent-kinds 1
  [
    set name "observer"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []
   ; set primitives-list lput "set-flowers" primitives-list
    ;set primitives-list lput "set-flower-count" primitives-list 
    ;set primitives-list lput "set-proboscis" primitives-list 
    ;set primitives-list lput "set-butterfly-color" primitives-list 
    ;set primitives-list lput "watch-random-butterfly" primitives-list
  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
   create-agent-kinds 1
  [
    set name "ant"
    
    set methods-list []
    set methods-list lput "go" methods-list
    set methods-list lput "setup" methods-list
    
    
    set primitives-list []
;    
  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
  
  create-agent-kinds 1
  [
    set name "flying-ant"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
   create-agent-kinds 1
  [
    set name "pollinator"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
  create-agent-kinds 1
  [
    set name "queen-ant"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
  create-agent-kinds 1
  [
    set name "queen-flying-ant"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list

create-agent-kinds 1
  [
    set name "spider"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
  create-agent-kinds 1
  [
    set name "frog"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
  create-agent-kinds 1
  [
    set name "snake"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
  create-agent-kinds 1
  [
    set name "bird"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

          
  ]
  set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
  
  create-agent-kinds 1
  [
    set name "unicorn"
    
    set methods-list []
    set methods-list lput "setup" methods-list
    set methods-list lput "go" methods-list
    
    set primitives-list []

     
  ]
 set agent-kind-list lput max-one-of agent-kinds [who] agent-kind-list
   
  ;;;;; END OF AGENT TYPE DEFINITIONS ;;;;;
  ask agent-kinds [ht]
end

to create-wabbits-list
  set wabbits-list sort [who] of wabbits
end

to create-wabbit-kind-list
  create-wabbits-list
  set wabbit-kind-list []
  
  foreach wabbits-list
  [
    set wabbit-kind-list lput [agent-kind-string] of turtle ? wabbit-kind-list
  ]
end

to-report mean-butterfly-energy
  let result 0
  ask wabbits with [agent-kind-string = "butterflies"]
  [set result result + energy]
  report result / count wabbits with [agent-kind-string = "butterflies"]
end

;;NEEDED FOR MEASURE LINKING
to place-measure-point
  create-measurepoints 1
  [
    set measure-points lput self measure-points 
    set tcycles count measurepoints - 1
    ifelse any? wabbits with [agent-kind-string = "butterflies"]
    [
      set t-energy-avg mean-butterfly-energy
      set t-proboscis-avg (count wabbits with [agent-kind-string = "butterflies" and is-long-beak]) / (count wabbits with [agent-kind-string = "butterflies"])
    ]
    [
      set t-energy-avg 0
      set t-proboscis-avg 0
    ]
    
    ifelse subject = nobody
    [set t-watched-energy 0]
    [set t-watched-energy [energy] of subject]

    
    set t-population (count wabbits with [agent-kind-string = "butterflies"])
    set tagentkind "butterflies"
    set measurepoint-creator "butterflies"
    ht
  ]
end

to-report turtle-property [who-number property]
  let result [runresult property] of turtle who-number
  report result
end

to-report primitive-list-length [agent-name]
  let current-agent-kind one-of agent-kinds with [name = agent-name]
  let result 0
  ask current-agent-kind
  [set result length primitives-list]
  report result
end

to-report primitive-list-item [agent-name item-number]
  let current-agent-kind one-of agent-kinds with [name = agent-name]
  let result ""
  ask current-agent-kind
  [set result item item-number primitives-list]
  report result
end

to-report arg-list-length [block-index]
  report length [ arg-list ] of item block-index blocks-list
end

to-report property-of-arg-for-block [arg-index block-index property]
  report [runresult property] of [item arg-index arg-list] of item block-index blocks-list
end

to-report method-list-length [agent-name]
  let current-agent-kind one-of agent-kinds with [name = agent-name]
  let result 0
  ask current-agent-kind
  [set result length methods-list]
  report result
end

to-report method-list-item [agent-name item-number]
  let current-agent-kind one-of agent-kinds with [name = agent-name]
  let result ""
  ask current-agent-kind
  [set result item item-number methods-list]
  report result
end

to-report list-length [list-name]
  report length list-name
end

to-report java-is-using-repeat
  report true
end

to-report java-is-image-computation
  report false
end

to-report java-is-repeat-var
  report false
end

to-report list-item [list-name index]
  report item index list-name
end

to-report list-item-property [list-name index property]
  report [runresult property] of item index list-name ; runresult converts the String variable into its NetLogo code equivalent (a property name)
end

to set-defaults
  set number-of-steps 0
  set flower-color random-color
  
  ;old value for use with lenient birds
  ;set reproduction-rate 5
  set reproduction-rate 8
  
  set eat-radius 3
  
  set current-window-max-size 20
  set current-window []
  
  set can-highlight-agents false
  set last-cycle false
  
  set dead-duration 3
  set baby-size 2.5
  set butterfly-size 5
  set flower-count 10
  set flower-layout "random"
end

to color-background-patches
  ask patches
  [set pcolor green - 1]
end

to make-observer
  create-wabbits 10
        [setxy random-xcor random-ycor
        set heading random 360
        set color red
        set shape "ant"
        set size 3
        set energy 100
        set agent-kind-string "ant"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
  create-wabbits 10
        [setxy random-xcor random-ycor
        set heading random 360
        set color blue
        set shape "flying-ant1"
        set size 3
        set energy 100
        set agent-kind-string "flying-ant"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
       create-wabbits 1
        [setxy 25 25
        set heading 90
        set color blue
        set paint-color color
        set size 4
        set shape "bug"
        set agent-kind-string "pollinator"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
     create-wabbits 1
        [setxy -25 -25
        set heading 90
        set color blue
        set paint-color color
        set size 4
        set shape "bug"
        set agent-kind-string "pollinator"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
      create-wabbits 1
        [setxy 25 -25
        set heading 90
        set color yellow
        set size 4
        set paint-color color
        set shape "squirrel"
        set agent-kind-string "pollinator"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
       create-wabbits 1
        [setxy 0 0
        set heading 90
        set color red
        set size 8
        set paint-color color
        set shape "ant"
        set agent-kind-string "queen-ant"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
          ask patches with [distancexy 0 0 < 4]
  [
    set is-ant-nest true
    set pcolor brown
  ]
        
      create-wabbits 1
        [setxy -40 -40
        set heading 90
        set color red
        set size 8
        set paint-color color
        set shape "flying-ant1"
        set agent-kind-string "queen-flying-ant"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
          ask patches with [distancexy -40 -40 < 4]
  [
    set is-flying-ant-nest true
    set pcolor brown
  ]
        
   create-wabbits 1
        [setxy random-xcor random-ycor
        set heading random 360
        set color grey
        set shape "spider"
        set size 6
        set energy 100
        set agent-kind-string "spider"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
create-wabbits 1
        [setxy random-xcor random-ycor
        set heading random 360
        set color grey
        set shape "frog"
        set size 7
        set energy 100
        set agent-kind-string "frog"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
create-wabbits 1
        [setxy random-xcor random-ycor
        set heading random 360
        set color grey
        set shape "snake"
        set size 8
        set energy 100
        set agent-kind-string "snake"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
  create-wabbits 1
        [setxy random-xcor random-ycor
        set heading random 360
        set color grey
        set shape "bird"
        set size 9
        set energy 100
        set agent-kind-string "bird"
        set distfromlast NaN
        set odistfromlast NaN
       ]
        
  create-wabbits 1
        [setxy random-xcor random-ycor
        set heading random 360
        set color grey
        set shape "unicorn"
        set size 10
        set energy 100
        set agent-kind-string "unicorn"
        set distfromlast NaN
        set odistfromlast NaN
        show-turtle
       ]
        
        ask wabbits
       [
        set pen-size 5
        
        set has-food false
        ; pen is up now
        set pen-was-down false 
        set bonus-speed 2
        set flag-counter 0
        set label energy
        show label
        
        set secret-number random 101    ;SECRET NUMBER
        set repeat-num random 5 + 2     ;REPEAT NUMBER
        
        set initial-x xcor
        set initial-y ycor
        set previous-x ""
        set previous-y ""
        ;if agent-kind-string != "queen-ant" or agent-kind-string != "pollinator" [set size 3]
       ]
  
  end
to make-other-stuff
  create-wabbits 12
  [
    setxy random-xcor random-ycor
    set agent-kind-string "butterflies"
    set size butterfly-size
    set color random-color
    ; set energy 10 + random 10 ; this value is used without the lose-energy-forward-dist block
    set energy 20 + random 10
    set label energy
    set is-long-beak false
    set shape "butterfly"
    set forward-distance 3
  ]
  create-wabbits 1
  [
    set agent-kind-string "observer"
    ht
  ]
  ask wabbits
  [
    set pen-was-down false ;; i.e., pen is up now
  ]
  
  create-birds 1
  [
    set bird-index 1
  ]
  create-birds 1
  [
    set bird-index 2
  ]
  ask birds
  [
    setxy random-xcor random-ycor
    set size 9
    set shape "bird side"
    set color blue
  ]

  create-labels
  update-flowers
end

to-report get-measures
  let result []
  foreach measure-points 
  [
    ask ? 
    [ 
      let datarep (list who red "\"butterflies\"" tcycles t-energy-avg t-population t-proboscis-avg t-watched-energy)
      set result lput datarep result
    ]
  ]
  report result
end

to-report get-measures-for [my-agent-kind]
  let result []
  let relevant-measures measurepoints
  let relevant-list sort relevant-measures
  foreach relevant-list 
  [
    ask ?
    [ 
      let datarep (list who red "\"butterflies\"" tcycles t-energy-avg t-population t-proboscis-avg t-watched-energy) 
      set result lput datarep result 
    ]
  ]
  report result
end

to-report get-measures-for-filtered [an-agent-kind a-measurepoint-creator]
  let result []
  ; let relevant-measures measurepoints with [ tagentkind = an-agent-kind and measurepoint-creator = a-measurepoint-creator ]
  let relevant-measures measurepoints
  let relevant-list sort relevant-measures
  foreach relevant-list 
  [
    ask ? 
    [ 
      let datarep (list who red "\"butterflies\"" (length result + 1) t-energy-avg t-population t-proboscis-avg t-watched-energy) 
      set result lput datarep result 
    ]
  ]
  report result
end

; a-color an rgb color, with each value from 0-255
; reports a list (x y z)
; reference: http://www.easyrgb.com/index.php?X=MATH&H=02#text2
to-report xyz-from-rgb [a-color]
  let r (item 0 a-color) / 255
  let g (item 1 a-color) / 255
  let b (item 2 a-color) / 255
  
  ifelse r > 0.4045
  [set r ((r + 0.055) / 1.055) ^ 2.4]
  [set r r / 12.92]

  ifelse g > 0.4045
  [set g ((g + 0.055) / 1.055) ^ 2.4]
  [set g g / 12.92]

  ifelse b > 0.4045
  [set b ((b + 0.055) / 1.055) ^ 2.4]
  [set b b / 12.92]
  
  set r r * 100
  set g g * 100
  set b b * 100

  ; Observer = 2 degrees, Illuminant = D65
  let x r * 0.4124 + g * 0.3576 + b * 0.1805
  let y r * 0.2126 + g * 0.7152 + b * 0.0722
  let z r * 0.0193 + g * 0.1192 + b * 0.9505
  
  report (list x y z)
end

; a-list a CIEXYZ list
; reports a CIELAB color as a list of L, a, b
; reference: http://www.easyrgb.com/index.php?X=MATH&H=07#text7
to-report lab-from-xyz [a-list]
  ; Observer= 2 degrees, Illuminant= D65
  let ref-x 95.047
  let ref-y 100.000
  let ref-z 108.883
  
  let x (item 0 a-list) / ref-x
  let y (item 1 a-list) / ref-y
  let z (item 2 a-list) / ref-z
  
  ifelse x > 0.008856
  [set x x ^ (1 / 3)]
  [set x (7.787 * x) + (16 / 116)]
  
  ifelse y > 0.008856
  [set y y ^ (1 / 3)]
  [set y (7.787 * y) + (16 / 116)]
  
  ifelse z > 0.008856
  [set z z ^ (1 / 3)]
  [set z (7.787 * z) + (16 / 116)]

  let l (116 * y) - 16
  let a 500 * (x - y)
  let b 200 * (y - z)

  report (list l a b)
end

; reports the CIE76 delta-E between two colors in CIELAB color space,
; given as lists of l, a, b coordinates.
; reference: http://en.wikipedia.org/wiki/Color_difference
to-report lab-to-delta-e [lab-color-a lab-color-b]
  report sqrt((item 0 lab-color-a - item 0 lab-color-b) ^ 2 + 
    (item 1 lab-color-a - item 1 lab-color-b) ^ 2 +
    (item 2 lab-color-a - item 2 lab-color-b) ^ 2)
end

; measures color distance from flower color using CIE76 algorithm
; reference: http://en.wikipedia.org/wiki/Color_difference
to-report new-color-distance
  report rgb-to-delta-e color flower-color
end

; reports the perceived color differene between two rgb colors, by
; converting the colors to CIEXYZ and then CIELAB color space,
; then taking the Euclidean distance between them in CIELAB space,
; which is the same as the CIE76 color difference metric.
to-report rgb-to-delta-e [rgb-color-a rgb-color-b]
  report lab-to-delta-e (lab-from-xyz 
    (xyz-from-rgb rgb-color-a)) 
    (lab-from-xyz (xyz-from-rgb rgb-color-b))
end
@#$#@#$#@
GRAPHICS-WINDOW
10
10
428
449
25
25
8.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -16777216 true false 78 58 99 116 139 123 137 128 95 119
Polygon -16777216 true false 48 103 90 147 129 147 130 151 86 151
Polygon -16777216 true false 65 224 92 171 134 160 135 164 95 175
Polygon -16777216 true false 235 222 210 170 163 162 161 166 208 174
Polygon -16777216 true false 249 107 211 147 168 147 168 150 213 150

ant-has-food
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -16777216 true false 78 58 99 116 139 123 137 128 95 119
Polygon -16777216 true false 48 103 90 147 129 147 130 151 86 151
Polygon -16777216 true false 65 224 92 171 134 160 135 164 95 175
Polygon -16777216 true false 235 222 210 170 163 162 161 166 208 174
Polygon -16777216 true false 249 107 211 147 168 147 168 150 213 150
Circle -1184463 true false 138 21 23

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird
true
0
Polygon -955883 true false 135 195 150 165
Circle -11221820 true false 86 86 127
Circle -13791810 true false 195 150 30
Polygon -13345367 true false 210 150 195 150 255 120 225 165 255 165 210 180 225 225 195 180
Circle -13791810 true false 195 150 30
Circle -11221820 true false 90 45 60
Polygon -6459832 true false 135 210 135 240 120 225 135 255 150 210 135 210
Polygon -6459832 true false 150 210 180 255 195 225 180 240 165 210 150 210
Polygon -13791810 true false 90 135 60 120 30 105 45 150 90 165 90 135
Polygon -13791810 true false 195 105 210 60 240 105 210 120 195 105
Polygon -13345367 true false 135 60 150 30 180 75 150 90
Polygon -6459832 true false 120 45 90 30 90 75
Circle -1 true false 105 45 30
Circle -16777216 true false 103 51 18

bird side
true
0
Polygon -7500403 true true 180 0 210 45 210 75 180 105 180 150 165 240 180 285 165 285 150 300 150 240 135 195 105 255 105 210 90 150 105 90 120 60 165 45
Circle -16777216 true false 188 38 14

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

butterfly-long
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60
Polygon -7500403 true true 135 105 150 15 165 105 135 105

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower-long
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 177 70 38
Circle -7500403 true true 70 25 38
Circle -7500403 true true 55 70 38
Circle -7500403 true true 115 10 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Circle -7500403 true true 160 25 38
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flying-ant1
true
13
Polygon -2674135 true false 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -2674135 true false 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -2674135 true false 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 80 254 107 201 149 190 150 194 110 205
Polygon -16777216 true false 235 252 210 200 163 192 161 196 208 204
Polygon -11221820 true false 135 135 75 75 45 75 15 120 30 150 135 165
Polygon -11221820 true false 165 135 225 75 255 75 285 120 270 150 165 165

flying-ant2
true
13
Polygon -2674135 true false 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -2674135 true false 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -2674135 true false 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 80 254 107 201 149 190 150 194 110 205
Polygon -16777216 true false 235 252 210 200 163 192 161 196 208 204
Polygon -11221820 true false 135 165 75 225 45 225 15 180 30 150 135 135
Polygon -11221820 true false 165 165 225 225 255 225 285 180 270 150 165 135

frog
true
0
Circle -14835848 true false 86 116 127
Circle -14835848 true false 96 66 108
Circle -14835848 true false 108 47 41
Circle -14835848 true false 148 48 41
Circle -1 true false 116 53 24
Circle -1 true false 156 53 24
Circle -16777216 true false 124 64 10
Circle -16777216 true false 163 62 10
Polygon -2674135 true false 129 110 142 118 164 118 174 110
Polygon -1184463 true false 88 165 72 155 59 186 72 207 81 225 57 235 58 252 78 254 98 245 109 228
Polygon -1184463 true false 212 169 228 159 241 190 228 211 219 229 243 239 242 256 222 258 202 249 191 232
Polygon -1184463 true false 125 235 106 251 116 255 134 252 138 231 143 202 142 188 123 191
Polygon -1184463 true false 175 235 194 251 184 255 166 252 162 231 157 202 158 188 177 191

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

minus
false
14
Rectangle -1 true false 0 90 300 210

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

plus
false
0
Rectangle -1 true false 105 0 195 300
Rectangle -1 true false 0 105 300 195

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

snake
true
0
Polygon -1184463 true false 66 112 43 109 29 95 27 81 34 68 48 53 69 54 83 68 88 82 90 96 104 97 119 90 145 82 175 82 202 105 214 156 211 187 213 210 226 217 244 224 273 210 273 188 282 174 289 191 288 211 274 233 256 240 237 246 225 245 207 240 193 230 183 214 182 198 185 171 184 157 182 144 179 128 166 120 135 113 120 123 82 125 73 118 66 114
Circle -14835848 true false 77 102 14
Circle -2674135 true false 97 103 14
Circle -14835848 true false 119 96 14
Circle -2674135 true false 143 90 14
Circle -14835848 true false 165 98 14
Circle -2674135 true false 179 109 18
Circle -14835848 true false 189 136 14
Circle -2674135 true false 190 159 14
Circle -14835848 true false 190 182 14
Circle -2674135 true false -61 159 14
Circle -14835848 true false 212 220 14
Circle -2674135 true false 233 225 14
Circle -14835848 true false 258 216 14
Circle -14835848 true false 258 216 14
Circle -2674135 true false 192 205 14
Line -2674135 false 40 67 19 51
Line -2674135 false 19 50 19 38
Line -2674135 false 18 52 8 53
Circle -1 true false 55 62 18
Circle -1 true false 39 79 18
Circle -16777216 true false 56 62 14
Circle -16777216 true false 39 79 14

spider
true
0
Circle -7500403 true true 105 148 92
Circle -7500403 true true 126 109 46
Rectangle -16777216 true false 75 150 90 165
Polygon -16777216 true false 130 167 108 130 108 91 91 91 92 130 119 168 123 156
Polygon -16777216 true false 110 183 75 158 72 119 56 120 59 157 110 194
Polygon -16777216 true false 124 226 85 255 91 287 106 282 104 259 132 238
Polygon -16777216 true false 116 199 68 210 59 245 72 246 77 215 119 204
Polygon -16777216 true false 176 160 188 136 188 95 204 95 202 137 181 172 172 160
Polygon -16777216 true false 192 195 240 152 240 121 219 124 219 151 186 180
Polygon -16777216 true false 186 217 237 223 236 252 215 252 216 233 180 220
Polygon -16777216 true false 175 231 208 253 208 276 183 276 183 257 164 235
Polygon -7500403 true true 133 116 123 95 146 74 133 99
Polygon -7500403 true true 164 110 172 95 154 80 164 114
Circle -16777216 true false 134 116 2
Circle -16777216 true false 132 119 4
Circle -16777216 true false 137 116 4
Circle -16777216 true false 139 123 3
Circle -16777216 true false 154 114 4
Circle -16777216 true false 159 123 6
Circle -16777216 true false 161 113 9
Polygon -2674135 true false 143 202 128 230 173 228 119 180 168 183

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

squirrel
false
0
Polygon -7500403 true true 87 267 106 290 145 292 157 288 175 292 209 292 207 281 190 276 174 277 156 271 154 261 157 245 151 230 156 221 171 209 214 165 231 171 239 171 263 154 281 137 294 136 297 126 295 119 279 117 241 145 242 128 262 132 282 124 288 108 269 88 247 73 226 72 213 76 208 88 190 112 151 107 119 117 84 139 61 175 57 210 65 231 79 253 65 243 46 187 49 157 82 109 115 93 146 83 202 49 231 13 181 12 142 6 95 30 50 39 12 96 0 162 23 250 68 275
Polygon -16777216 true false 237 85 249 84 255 92 246 95
Line -16777216 false 221 82 213 93
Line -16777216 false 253 119 266 124
Line -16777216 false 278 110 278 116
Line -16777216 false 149 229 135 211
Line -16777216 false 134 211 115 207
Line -16777216 false 117 207 106 211
Line -16777216 false 91 268 131 290
Line -16777216 false 220 82 213 79
Line -16777216 false 286 126 294 128
Line -16777216 false 193 284 206 285
Polygon -7500403 false true 15 135 15 180
Polygon -16777216 false false 30 241 8 153 21 104 57 53 153 10 66 57 29 104 17 149 35 239 38 237 41 237 25 148 43 100 77 61 170 12 91 65 53 104 35 151 50 232

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

surprise-shape
true
0
Polygon -1184463 true false 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -955883 true false 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -14835848 true false 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -16777216 true false 78 58 99 116 139 123 137 128 95 119
Polygon -16777216 true false 48 103 90 147 129 147 130 151 86 151
Polygon -16777216 true false 65 224 92 171 134 160 135 164 95 175
Polygon -16777216 true false 235 222 210 170 163 162 161 166 208 174
Polygon -16777216 true false 249 107 211 147 168 147 168 150 213 150
Circle -1 true false 114 69 42
Circle -1 true false 144 69 42
Circle -13791810 true false 128 83 14
Circle -13791810 true false 157 82 16
Polygon -2674135 true false 170 66 167 61 140 60 138 65 170 67
Line -16777216 false 125 107 120 118
Line -16777216 false 134 110 134 120
Line -16777216 false 143 109 144 123
Line -16777216 false 162 109 160 120
Line -16777216 false 168 109 168 123
Line -16777216 false 175 112 180 124
Circle -11221820 true false 132 129 16
Circle -2064490 true false 150 205 14
Circle -2064490 true false 128 220 12
Circle -8630108 true false 148 240 14
Circle -13840069 true false 151 147 16

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

unicorn
true
0
Polygon -1 true false 93 134 70 148 44 155 26 145 27 125 49 109 81 91 91 86 104 84 120 86 129 102 133 126 150 130 204 136 230 134 251 132 256 156 255 215 250 235 239 242 230 233 230 208 232 182 232 178 231 209 215 243 203 244 201 225 218 205 221 195 136 192 131 220 116 255 99 258 86 258 82 248 97 238 114 227 117 203 117 189 116 212 94 222 86 238 91 241 114 227 117 197 118 187 93 174 89 155 83 143
Polygon -8630108 true false 80 93 99 36 104 85
Circle -11221820 true false 64 92 22
Circle -11221820 true false 81 91 24
Polygon -2064490 true false 54 138 66 135 55 151 40 133
Circle -16777216 true false 66 98 12
Circle -16777216 true false 85 98 12
Polygon -5825686 true false 104 85 119 84 133 103 135 118 146 132 148 140 136 154 115 129 113 105 106 92 98 89
Polygon -5825686 true false 98 87 69 89 62 82 80 79
Polygon -5825686 true false 238 131 255 128 276 156 283 184 275 200 262 195 251 169 246 139
Line -2064490 false 100 52 90 59
Line -2064490 false 102 62 86 72
Line -2064490 false 102 70 83 81
Line -16777216 false 67 96 64 89
Line -16777216 false 72 94 72 84
Line -16777216 false 77 93 80 88
Line -16777216 false 90 94 87 85
Line -16777216 false 94 92 98 83
Line -16777216 false 99 96 104 90

unicorn1
true
15
Rectangle -11221820 true false 120 135 210 180
Circle -13840069 true false 60 75 90
Rectangle -2674135 true false 120 180 135 210
Rectangle -2674135 true false 195 180 210 210
Circle -16777216 true false 105 90 30
Circle -16777216 true false 75 105 30
Line -16777216 false 105 150 120 150
Rectangle -11221820 true false 75 105 90 120
Rectangle -11221820 true false 105 90 120 105
Line -6459832 false 210 150 225 180
Line -1184463 false 60 45 75 90

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
