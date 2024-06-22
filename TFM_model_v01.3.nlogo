breed [edges edge]
breed [pedestrians pedestrian]

globals [
  c ; comptador de portals
  fflist ; llista de combinacions de portals
  meanspeed
  speedsd
  meanspacing
  spacingsd
  map-density
  collisions
  memo-layout ; street layout executat anteriorment, info necessària per saber quan fer setup-layout al behaviorspace
]

turtles-own [
  diam
]

pedestrians-own [
  orig
  dest
  ff-map
  ff-last
  hd
  speed-max
  speedx
  speedy
  accx
  accy
  traveled-length
  collision-list
  collision-count
]

patches-own [
  type-patch
  collision-time
  ff
  id-portal
  ff-01 ff-02 ff-03 ff-04 ff-05 ff-06 ff-07 ff-08 ff-09
  ff-10 ff-12 ff-13 ff-14 ff-15 ff-16 ff-17 ff-18 ff-19
  ff-20 ff-21 ff-23 ff-24 ff-25 ff-26 ff-27 ff-28 ff-29
  ff-30 ff-31 ff-32 ff-34 ff-35 ff-36 ff-37 ff-38 ff-39
  ff-40 ff-41 ff-42 ff-43 ff-45 ff-46 ff-47 ff-48 ff-49
  ff-50 ff-51 ff-52 ff-53 ff-54 ff-56 ff-57 ff-58 ff-59
  ff-60 ff-61 ff-62 ff-63 ff-64 ff-65 ff-67 ff-68 ff-69
  ff-70 ff-71 ff-72 ff-73 ff-74 ff-75 ff-76 ff-78 ff-79
  ff-80 ff-81 ff-82 ff-83 ff-84 ff-85 ff-86 ff-87 ff-89
  ff-90 ff-91 ff-92 ff-93 ff-94 ff-95 ff-96 ff-97 ff-98
]

to setup-layout
  ca
  reset-ticks

  ; crear el mapa, o importar-lo d'imatge i donar-li contrast carrer / no carrer:
  ifelse street-layout = "sample crossroads (choose width)" [
    ; aquest mòdul és per generar un creuament de carrers senzill:
    ; es defineix l'amplada dels carrers en funció de l'slider "street-width":
    ask patches [
      if pycor < (max-pycor / 2 + street-width / 2) and pycor > (max-pycor / 2 - street-width / 2) [ set pcolor 7 ]
      if pxcor < (max-pxcor / 2 + street-width / 2) and pxcor > (max-pxcor / 2 - street-width / 2) [ set pcolor 7 ]
    ]
  ][
    if street-layout = "Eixample - Convencional" [
      ; S'importa la imatge:
      import-pcolors "eixample-convencional.png"]
    if street-layout = "Eixample - Buit" [
      import-pcolors "eixample-buit.png"]
    if street-layout = "Eixample - Eix Verd" [
      import-pcolors "eixample-eix-verd.png"]
    if street-layout = "Ciutat Vella - SM del Mar"[
      import-pcolors "sm-mar-1.png"]
    if street-layout = "Ciutat Vella - Raval"[
      import-pcolors "raval-1.png"]
    if street-layout = "Ciutat Vella - Pl Orwell"[
      import-pcolors "placa-orwell-2.png"]
    if street-layout = "Rambla - Actual"[
      import-pcolors "rambla-actual.png"]
    if street-layout = "Rambla - Buit"[
      import-pcolors "rambla-vianants.png"]
    ; aquí es poden anar posant altres layouts importats d'imatge, cadascun en una iteració "if"
    ;convertir patches grisos a blancs o negres (necessari si el layout és importat d'imatge):
    ask patches with [(pcolor - 9.9) mod 10 = 0] [set pcolor 9.9] ; s'unifiquen tots els patches blancs (color 9.9 "white")
    ask patches with [pcolor mod 10 = 0] [set pcolor 0] ; s'unifiquen tots els patches negres (color 0 "black")
    ask patches with [pcolor != 9.9 and pcolor != 0] [
      ifelse pcolor > 5 and pcolor < 9.9 [set pcolor 9.9] [set pcolor 0]
    ]
    ask patches with [pcolor = 9.9] [set pcolor 7]
  ]
  set memo-layout street-layout

  ; assignar als patches el seu tipus (portal / carrer / no-carrer)
  ask patches [
    if pcolor = black [set type-patch "lava" set ff "NA"]
    if pcolor = 7 [
      ifelse pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pycor or pycor = max-pycor [
        set type-patch "portal" ] [
        set type-patch "street" ]
    ]
  ]

  ; posar un agent "obstacle" a cada patch de frontera entre lava i street:
  ask patches with [type-patch = "lava" and any? neighbors with [type-patch != "lava"]] [
    sprout-edges 1 [
      set shape "square"
      set size 1 set diam 1
      set color black
    ]
  ]

  ; agrupar i numerar els "portals":
  let portals (patch-set patches with [type-patch = "portal"])
  ask patches [set id-portal "NA"]
  set c 0
  while [count portals with [id-portal = "NA"] > 0] [
    ifelse any? portals with [id-portal = c] [
      while [any? portals with [id-portal = "NA" and any? neighbors4 with [id-portal = c]]] [
        ask one-of portals with [id-portal = "NA" and any? neighbors4 with [id-portal = c]] [set id-portal c]
      ]
      set c c + 1
    ] [
      ask one-of portals with [id-portal = "NA"] [set id-portal c]
    ]
  ]
  set c c - 1 ; utilitzarem "c" en altres llocs per saber la quantitat de portals que tenim
  ;ask portals [set plabel id-portal set plabel-color 0]

  ; generar una llista "fflist" amb les combinacions de portals:
  let xff 0 let yff 0
  set fflist []
  while [xff <= c] [
    while [yff <= c] [
      ifelse xff = yff [
        set yff yff + 1
      ][
        set fflist lput (word "ff-" xff yff) fflist
        set yff yff + 1
      ]
    ]
    set yff 0
    set xff xff + 1
  ]
  ;print fflist

  ;executar l'algoritme flood-fill per obtenir els mapes d'alçades:
  output-print "Obtaining ff maps..."
  foreach fflist [i ->
    ask patches with [type-patch = "street" or type-patch = "portal"] [set ff "NA"]
    let origin read-from-string item 3 i
    let destination read-from-string item 4 i
    output-print (word origin " to " destination)
    ask one-of patches with [id-portal = destination] [set ff 0]
    let c1 0
    while [any? patches with [id-portal = origin and ff = "NA"]] [
      ask patches with [ff = c1] [
        ask neighbors with [type-patch != "lava" and ff = "NA"] [
          set ff c1 + 1
        ]
      ]
      set c1 c1 + 1
    ]
    ask patches with [type-patch = "street" and ff != "NA" and any? neighbors with [type-patch = "lava"]] [set ff ff + 1] ; posar-li "sòcol" als mapes de ff, perquè els vianants s'allunyin de les vores i s'evitin aglomeracions:
    run (word "ask patches [set " i " ff]")
    ;ask patches with [type-patch != "lava"] [set pcolor 7]
    ;ask patches with [ff != "NA"] [set pcolor scale-color green ff [ff] of max-one-of patches with [ff != "NA"] [ff] 0]
  ]
  output-print "Done!"
  set map-density count patches with [type-patch != "lava"] / count patches * 100
end

to setup
  reset-ticks
  rp
  ask pedestrians [die]
  set collisions 0 set meanspeed 0 set speedsd 0 set meanspacing 0 set spacingsd 0
  clear-drawing
  clear-all-plots
  ask patches with [type-patch = "street" or type-patch = "portal"] [set pcolor 7]
end

to check-stats
  ask pedestrians [set traveled-length traveled-length + sqrt ((speedx * dt) ^ 2 + (speedy * dt) ^ 2)]
  if count pedestrians > 2 [
    set meanspeed mean [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
    set speedsd sqrt variance [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
    set meanspacing mean [mean sublist sort [distance myself] of pedestrians 1 min(list 10 count pedestrians)] of pedestrians
    set spacingsd sqrt variance [mean sublist sort [distance myself] of pedestrians 1 min(list 10 count pedestrians)] of pedestrians
    ask pedestrians [
      let closest min-one-of pedestrians with [not (self = myself)] [distance myself]
      if distance closest < diam and not member? closest collision-list [
        set collisions collisions + 1
        set collision-count collision-count + 1
        ask patch-here [set pcolor yellow set collision-time 20]
        set collision-list (turtle-set collision-list closest)
        ask closest [set collision-list (turtle-set collision-list myself)]
      ]
      set collision-list (turtle-set collision-list with [distance myself <= (diam + 0.5)])
      if collision-labels? [set label collision-count set label-color 95]
    ]
  ]
end

to add-pedestrian
  ask one-of patches with [type-patch = "portal"] [
    sprout-pedestrians 1 [
      set size 0.6
      set diam 0.4
      set shape "circle"
      set orig patch-here
      let id-orig [id-portal] of orig
      set dest one-of patches with [type-patch = "portal" and id-portal != id-orig and not any? patches in-radius 1 with [type-patch = "lava"]]
      set ff-map (word "ff-" [id-portal] of orig [id-portal] of dest)
      run (word "set hd towards min-one-of neighbors [" ff-map "]")
      set heading hd
      set speed-max random-normal desired-speed speed-sd
      color-pedestrians
      set speedx 0 set speedy 0 set accx 0 set accy 0
      set traveled-length 0
      set collision-list turtle-set []
      ;pen-down
    ]
  ]
end

to color-pedestrians
  set color scale-color
  red
  speed-max
  (desired-speed + speed-sd + .8)
  (desired-speed - speed-sd - .8)
end

to go
  ; fer que el món es vagi omplint gradualment amb vianants en funció de la quantitat final (comptar uns 100 s d'escalfament):
  let ritme round (1200 / #-pedestrians)
  if count pedestrians < #-pedestrians and ticks mod ritme = 0 [add-pedestrian]
  ask pedestrians [
    ; calcular el rumb en funció del mapa flood-fill:
    ;; opció 1 (salta error quan un vianant és empès fora del carrer):
    ;run (word "set hd towards min-one-of neighbors with [" ff-map " = [" ff-map "] of [patch-here] of myself - 1] [distance myself]")
    ;; opció 2 (és bo, però es formen moltes aglomeracions en les cantonades, per la "tossuderia" dels vianants):
    ;run (word "if [" ff-map "] of patch-here != \"NA\" [set ff-last [" ff-map "] of patch-here]")
    ;run (word "set hd towards min-one-of neighbors with [" ff-map " = [ff-last] of myself - 1] [distance myself]")
    ;; opció 3 (més senzill i reprodueix millor els moviments atzarosos dels individus):
    ;run (word "set hd towards one-of neighbors with [" ff-map " = [ff-last] of myself - 1]")
    ;; opció 4 (amb una component més d'atzar):
    ;ifelse random 10 >= 3 [run (word "set hd towards one-of neighbors with [" ff-map " = [ff-last] of myself - 1]")][run (word "set hd towards one-of neighbors with [" ff-map " = [ff-last] of myself]")]
    ;; opció 5 (moure's al patch amb igual o menor ff que tingui menys densitat de població):
    ;run (word "set hd towards min-one-of neighbors with [" ff-map " = [ff-last] of myself - 1 or " ff-map " = [ff-last] of myself] [count pedestrians-here]")
    ;; opció 6 (mirar en un radi i apuntar al patch més baix - hi ha problemes en girs bruscs):
    ;run (word "set hd towards min-one-of patches in-radius 5 [" ff-map "]")
    ;; opció 7 (apuntar cap un dels paches de menor nivell ff) - funciona bé després d'afegir el "sòcol" als mapes ff:
    run (word "set hd towards min-one-of neighbors [" ff-map "]")
    ; calcular la nova acceleració mitjançant el SFM:
    set-acc
  ]
  ask pedestrians [
    ; calcular les velocitats resultants amb les noves acceleracions:
    set speedx speedx + dt * accx
    set speedy speedy + dt * accy
    ; i les noves posicions: (si es surten del mapa, moren)
    let xcor-new xcor + speedx * dt
    let ycor-new ycor + speedy * dt
    ifelse xcor-new < min-pxcor or xcor-new > max-pxcor [die] [set xcor xcor-new]
    ifelse ycor-new < min-pycor or ycor-new > max-pycor [die] [set ycor ycor-new]
    ; calcular la direcció:
    set heading atan speedx speedy
    ; condició per fer desaparèixer el vianant un cop arribi a destí:
    if distance dest < 2 or [id-portal] of patch-here = [id-portal] of dest [die pen-erase]
  ]
  check-stats
  if shut-down-yellow? [
    ask patches with [pcolor = yellow] [
      set collision-time collision-time - 1
      if collision-time = 0 [
        set pcolor 7
      ]
    ]
  ]
  tick
end

to set-acc
  set accx (speed-max * sin hd - speedx) / tau +
           (1 + sqrt(speedx ^ 2 + speedy ^ 2)) * sum [U (distance myself - (diam / 2 + [diam] of myself / 2)) * sin(towards myself) * (1 - cos(towards myself - [heading] of myself))] of turtles in-radius 10 with [not (self = myself)]
  set accy (speed-max * cos hd - speedy) / tau +
           (1 + sqrt(speedx ^ 2 + speedy ^ 2)) * sum [U (distance myself - (diam / 2 + [diam] of myself / 2)) * cos(towards myself) * (1 - cos(towards myself - [heading] of myself))] of turtles in-radius 10 with [not (self = myself)]
end

to-report U [dist]
  report A * exp((- dist) / B)
end

to show-scale-color
  rp
  ask pedestrians [color-pedestrians]
  ask patches with [type-patch = "street" or type-patch = "portal"] [set pcolor 7]
  watch pedestrian read-from-string which-pedestrian?
  let ff-sc [ff-map] of pedestrian read-from-string which-pedestrian?
  run (word "ask patches with ["ff-sc" != \"NA\"] [set pcolor scale-color green "ff-sc" ["ff-sc"] of max-one-of patches with ["ff-sc" != \"NA\"] ["ff-sc"] 0]")
end

to clear-scale-color
  rp
  ask pedestrians [color-pedestrians]
  ask patches with [type-patch = "street" or type-patch = "portal"] [set pcolor 7]
end
@#$#@#$#@
GRAPHICS-WINDOW
420
20
933
534
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
100
0
100
1
1
1
ticks
30.0

BUTTON
4
219
228
252
Setup Layout
setup-layout
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

BUTTON
7
387
142
420
NIL
Go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
592
595
689
628
Show flood-fill map
show-scale-color
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
7
354
204
387
NIL
Setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

OUTPUT
228
142
412
252
10

CHOOSER
4
142
228
187
street-layout
street-layout
"sample crossroads (choose width)" "Eixample - Convencional" "Eixample - Buit" "Eixample - Eix Verd" "Ciutat Vella - SM del Mar" "Ciutat Vella - Raval" "Ciutat Vella - Pl Orwell" "Rambla - Actual" "Rambla - Buit"
2

TEXTBOX
7
18
409
135
--------------------------------------- LAYOUT SETUP ----------------------------------------\nThe world represents a 100 x 100 m surface.\n\nFor the setup of the map:\n 1) Select the \"street-layout\":\n     a) \"sample crossing\" will also require to select the \"street-width\"\n     b) Other configurations don't require further adjustments\n 2) Click on \"setup layout\" and wait until it's completed. After this, it's not necessary to do it again between each model run; use this module only to change the layout.
10
0.0
1

SLIDER
4
187
228
220
street-width
street-width
5
25
20.0
1
1
m
HORIZONTAL

BUTTON
142
387
204
420
Go once
Go
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
1

SLIDER
7
423
204
456
#-pedestrians
#-pedestrians
5
300
5.0
1
1
NIL
HORIZONTAL

SLIDER
7
460
204
493
dt
dt
.01
.2
0.05
.01
1
NIL
HORIZONTAL

SLIDER
233
353
370
386
desired-speed
desired-speed
.5
2.5
1.34
.01
1
m/s
HORIZONTAL

SLIDER
233
386
370
419
speed-sd
speed-sd
0
.6
0.6
.01
1
m/s
HORIZONTAL

SLIDER
233
423
370
456
Tau
Tau
.1
2
0.5
.1
1
s
HORIZONTAL

SLIDER
233
456
370
489
A
A
0
10
3.0
.5
1
m/s²
HORIZONTAL

SLIDER
233
489
370
522
B
B
.1
.5
0.2
.05
1
m
HORIZONTAL

SWITCH
420
535
576
568
Collision-labels?
Collision-labels?
1
1
-1000

SWITCH
420
567
576
600
Shut-down-yellow?
Shut-down-yellow?
0
1
-1000

MONITOR
941
20
1125
65
Transitable portion of land [%]
map-density
2
1
11

MONITOR
1134
20
1235
65
Time [s]
ticks * dt
2
1
11

MONITOR
944
103
1042
148
Mean spacing [m]
meanspacing
3
1
11

MONITOR
942
281
1049
326
Mean speed [m/s]
meanspeed
3
1
11

MONITOR
942
327
1049
372
Speed sd [m/s]
speedsd
3
1
11

MONITOR
944
149
1042
194
Spacing sd [m]
spacingsd
3
1
11

PLOT
1060
74
1349
224
Spacing
NIL
NIL
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"Mean spacing" 1.0 0 -13791810 true "" "plot meanspacing"
"Spacing SD" 1.0 0 -2674135 true "" "plot spacingsd"

PLOT
1060
251
1348
401
Speed
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Mean speed" 1.0 0 -13791810 true "" "plot  meanspeed"
"Speed SD" 1.0 0 -2674135 true "" "plot speedsd"

MONITOR
943
489
1047
534
Collisions
collisions
3
1
11

PLOT
1061
430
1349
580
Collisions
NIL
NIL
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"Turtle - Turtle" 1.0 0 -2674135 true "" "plot collisions"

MONITOR
1348
311
1455
356
Max speed [m/s]
max [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
3
1
11

MONITOR
1348
356
1455
401
Min speed [m/s]
min [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
3
1
11

MONITOR
1244
20
1349
65
# of pedestrians
count pedestrians
17
1
11

TEXTBOX
13
281
407
346
---------------------------------- MODEL SETUP & RUN ------------------------------------\nOnce the layout is loaded, use this module to vary parameters, initialize (Setup) and run (Go) the model.\nColoring of agents is represented according its desired speed (dark = high / clear = low)
10
0.0
1

INPUTBOX
592
535
744
595
which-pedestrian?
625
1
0
String

BUTTON
689
595
744
628
Clear
clear-scale-color
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="prova_1" repetitions="5" runMetricsEveryStep="false">
    <setup>if memo-layout != street-layout [setup-layout]
setup
while [ticks * dt &lt; 100] [go]
set collisions 0 reset-ticks</setup>
    <go>go</go>
    <exitCondition>ticks * dt = 100</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <metric>collisions</metric>
    <enumeratedValueSet variable="which-pedestrian?">
      <value value="&quot;955&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shut-down-yellow?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="street-width">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="street-layout">
      <value value="&quot;Eixample - Convencional&quot;"/>
      <value value="&quot;Eixample - Eix Verd&quot;"/>
      <value value="&quot;Eixample - Buit&quot;"/>
      <value value="&quot;Granollers Centre 1&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="20" step="20" last="200"/>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Collision-labels?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="general_01" repetitions="10" runMetricsEveryStep="false">
    <setup>if memo-layout != street-layout [setup-layout]
setup
while [ticks * dt &lt; 100] [go]
set collisions 0 reset-ticks</setup>
    <go>go</go>
    <exitCondition>ticks * dt = 60</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <metric>collisions</metric>
    <metric>count pedestrians</metric>
    <metric>map-density</metric>
    <enumeratedValueSet variable="street-layout">
      <value value="&quot;Eixample - Convencional&quot;"/>
      <value value="&quot;Eixample - Eix Verd&quot;"/>
      <value value="&quot;Eixample - Buit&quot;"/>
      <value value="&quot;Ciutat Vella - SM del Mar&quot;"/>
      <value value="&quot;Ciutat Vella - Raval&quot;"/>
      <value value="&quot;Ciutat Vella - Pl Orwell&quot;"/>
      <value value="&quot;Rambla - Actual&quot;"/>
      <value value="&quot;Rambla - Buit&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <subExperiment>
      <steppedValueSet variable="#-pedestrians" first="5" step="5" last="45"/>
    </subExperiment>
    <subExperiment>
      <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    </subExperiment>
  </experiment>
  <experiment name="general_01 (5-10-15 repeat)" repetitions="10" runMetricsEveryStep="false">
    <setup>if memo-layout != street-layout [setup-layout]
setup
while [ticks * dt &lt; 100] [go]
set collisions 0 reset-ticks</setup>
    <go>go</go>
    <exitCondition>ticks * dt = 60</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <metric>collisions</metric>
    <metric>count pedestrians</metric>
    <metric>map-density</metric>
    <enumeratedValueSet variable="street-layout">
      <value value="&quot;Eixample - Convencional&quot;"/>
      <value value="&quot;Eixample - Eix Verd&quot;"/>
      <value value="&quot;Eixample - Buit&quot;"/>
      <value value="&quot;Ciutat Vella - SM del Mar&quot;"/>
      <value value="&quot;Ciutat Vella - Raval&quot;"/>
      <value value="&quot;Ciutat Vella - Pl Orwell&quot;"/>
      <value value="&quot;Rambla - Actual&quot;"/>
      <value value="&quot;Rambla - Buit&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="5" step="5" last="15"/>
  </experiment>
</experiments>
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
