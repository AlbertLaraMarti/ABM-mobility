breed [pedestrians pedestrian]
breed [obstacles obstacle]

globals [
  meanspeed
  speedsd
  meanspacing
  spacingsd
  real-density
  collisions.turtle-turtle
  ;collisions.turtle-patch
]

patches-own [
  type-patch
  collision-time
]

pedestrians-own [
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

to setup-null
  ca
  reset-ticks
  resize-world 0 24 0 24
  set-patch-size 20
  ask patches [
    set pcolor 7
    ifelse pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pycor or pycor = max-pycor [
      set type-patch "portal" ] [
      set type-patch "street" ]
  ]
  if obstacle-density > 0 [
    while [count obstacles * (obstacle-diam ^ 2 * pi / 4) / count patches * 100 <= obstacle-density] [
      ask one-of patches with [not any? patches in-radius (obstacle-diam / 2 + .5) with [type-patch = "lava"]] [
        sprout-obstacles 1 [
          set shape "circle"
          set size obstacle-diam
          set color green - 1
        ]
        ask patches in-radius (obstacle-diam / 2) [set type-patch "lava"]
      ]
    ]
    set real-density count obstacles * (obstacle-diam ^ 2 * pi / 4) / count patches * 100
  ]
  ask n-of #-pedestrians patches with [type-patch != "lava"] [
    sprout-pedestrians 1 [
      set shape "circle"
      set size 0.4
      set speed-max random-normal desired-speed speed-sd
      set speedx 0 set speedy 0 set accx 0 set accy 0
    ]
  ]
  ask pedestrians [
    set color scale-color red speed-max max [speed-max] of pedestrians min [speed-max] of pedestrians
    if heading-choice = "crossflow" [set hd one-of [0 90 180 270]]
    if heading-choice = "angle-determined" [set hd random 359]
    if heading-choice = "counterflow" [set hd one-of [90 270]]
  ]
  set collisions.turtle-turtle 0
  ;set collisions.turtle-patch 0
  ask pedestrians [
    set traveled-length 0
    set collision-list turtle-set []
  ]
  if collision-labels? [ask pedestrians [set collision-count 0 set label collision-count set label-color 95]]
  check-stats
end

to check-stats
  set meanspeed mean [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
  set speedsd sqrt variance [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
  set meanspacing mean [mean sublist sort [distance myself] of pedestrians 1 min(list 10 #-pedestrians)] of pedestrians
  set spacingsd sqrt variance [mean sublist sort [distance myself] of pedestrians 1 min(list 10 #-pedestrians)] of pedestrians
  ask pedestrians [set traveled-length traveled-length + sqrt ((speedx * dt) ^ 2 + (speedy * dt) ^ 2)]
  ask pedestrians [
    let closest min-one-of pedestrians with [not (self = myself)] [distance myself]
    if distance closest < size and not member? closest collision-list [
      set collisions.turtle-turtle collisions.turtle-turtle + 1
      set collision-count collision-count + 1
      ask patch-here [set pcolor yellow set collision-time 20]
      set collision-list (turtle-set collision-list closest)
      ask closest [set collision-list (turtle-set collision-list myself)]
    ]
    set collision-list (turtle-set collision-list with [distance myself <= (size + 0.5)])
    if collision-labels? [set label collision-count set label-color 95]
  ]
end

to go-null
  ask pedestrians [set-acc]
  ask pedestrians [
    set speedx speedx + dt * accx
    set speedy speedy + dt * accy
    set xcor xcor + speedx * dt
    set ycor ycor + speedy * dt
    set heading atan speedx speedy
  ]
  check-stats
  ;if any? patches with [pcolor = yellow] [stop]
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
           (1 + sqrt(speedx ^ 2 + speedy ^ 2)) * sum [U (distance myself - (size / 2 + [size] of myself / 2)) * sin(towards myself) * (1 - cos(towards myself - [heading] of myself))] of turtles in-radius 10 with [not (self = myself)]
  set accy (speed-max * cos hd - speedy) / tau +
           (1 + sqrt(speedx ^ 2 + speedy ^ 2)) * sum [U (distance myself - (size / 2 + [size] of myself / 2)) * cos(towards myself) * (1 - cos(towards myself - [heading] of myself))] of turtles in-radius 10 with [not (self = myself)]
end

to-report U [dist]
  report A * exp((- dist) / B)
end
@#$#@#$#@
GRAPHICS-WINDOW
340
26
848
535
-1
-1
20.0
1
10
1
1
1
0
1
1
1
0
24
0
24
1
1
1
ticks
30.0

BUTTON
31
33
327
66
Setup
setup-null
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

SLIDER
174
116
326
149
obstacle-diam
obstacle-diam
1
10
3.0
1
1
m
HORIZONTAL

SLIDER
174
149
326
182
obstacle-density
obstacle-density
0
25
1.0
1
1
%
HORIZONTAL

BUTTON
31
67
231
100
Go
go-null
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

MONITOR
873
33
1012
78
Real obst. density [%]
real-density
3
1
11

CHOOSER
31
115
161
160
heading-choice
heading-choice
"crossflow" "angle-determined" "counterflow"
2

BUTTON
234
67
327
100
Go once
go-null
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
31
193
161
226
#-pedestrians
#-pedestrians
2
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
32
338
162
371
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
32
372
162
405
speed-sd
speed-sd
0
.6
0.26
.01
1
m/s
HORIZONTAL

SLIDER
174
210
327
243
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
174
243
327
276
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
174
276
327
309
B
B
.1
.5
0.2
.05
1
m
HORIZONTAL

TEXTBOX
343
540
838
579
The world represents a 25 x 25 m public space.\nColoring of pedestrians is represented according its desired speed (black = max / white = min).
10
0.0
1

SLIDER
33
258
162
291
dt
dt
.01
.2
0.05
.01
1
s
HORIZONTAL

MONITOR
1036
33
1118
78
Time
ticks * dt
3
1
11

MONITOR
871
121
969
166
Mean spacing [m]
meanspacing
3
1
11

MONITOR
869
299
976
344
Mean speed [m/s]
meanspeed
3
1
11

MONITOR
869
345
976
390
Speed sd [m/s]
speedsd
3
1
11

MONITOR
871
167
969
212
Spacing sd [m]
spacingsd
3
1
11

PLOT
987
92
1276
242
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
987
269
1275
419
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
867
519
986
564
Collisions turtle-turtle
collisions.turtle-turtle
3
1
11

PLOT
987
444
1275
594
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
"Turtle - Turtle" 1.0 0 -2674135 true "" "plot collisions.turtle-turtle"

MONITOR
1275
329
1382
374
Max speed [m/s]
max [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
3
1
11

MONITOR
1275
374
1382
419
Min speed [m/s]
min [sqrt(speedx ^ 2 + speedy ^ 2)] of pedestrians
3
1
11

SWITCH
340
598
494
631
Shut-down-yellow?
Shut-down-yellow?
0
1
-1000

SWITCH
340
567
494
600
Collision-labels?
Collision-labels?
0
1
-1000

@#$#@#$#@
# ODD

## 1. PROPÒSIT I PATRONS

El propòsit 

## 2. ENTITATS, VARIABLES D'ESTAT I ESCALES

## 3. VISIÓ GENERAL DEL PROCÉS I PROGRAMACIÓ

## 4. CONCEPTES DE DISSENY

### Principis bàsics

### Emergència

### Adaptació

### Objectius

### Aprenentatge

### Predicció

### Percepció

### Interacció

### Estocasticitat

### Col·lectius

### Observació

## 5. INICIALITZACIÓ

## 6. DADES D'ENTRADA

## 7. SUB-MODELS

# INFO TEMPLATE NL


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
  <experiment name="Crossflow_speed-spacing_variance_#pedestrians" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 30</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Counterflow_collisions_variance_#pedestrians" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>collisions.turtle-turtle</metric>
    <metric>ticks * dt</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Counterflow_speed-spacing_variance_#pedestrians" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 30</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Crossflow_collisions_variance_#pedestrians" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>collisions.turtle-turtle</metric>
    <metric>ticks * dt</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Crossflow_speed-spacing_obstacles_#pedestrians" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 50</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-sd">
      <value value="0.26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="obstacle-density" first="2" step="2" last="20"/>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Counterflow_speed-spacing_obstacles_#pedestrians" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 50</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-sd">
      <value value="0.26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="obstacle-density" first="2" step="2" last="20"/>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Crossflow_speed-spacing_obstacles_#pedestrians (1)" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 50</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-sd">
      <value value="0.26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="obstacle-density" first="2" step="2" last="20"/>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Counterflow_collisions-speed-spacing_filter.obstacles_SD_#pedestrians-50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="2" step="2" last="48"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Counterflow_collisions-speed-spacing_filter.obstacles_SD_#pedestrians+50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Crossflow_collisions-speed-spacing_filter.obstacles_SD_#pedestrians-50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="2" step="2" last="48"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Crossflow_collisions-speed-spacing_filter.obstacles_SD_#pedestrians+50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Counterflow_collisions-speed-spacing_no-obstacles_SD_#pedestrians-50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="2" step="2" last="48"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Counterflow_collisions-speed-spacing_no-obstacles_SD_#pedestrians+50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Crossflow_collisions-speed-spacing_no-obstacles_SD_#pedestrians-50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="2" step="2" last="48"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Crossflow_collisions-speed-spacing_no-obstacles_SD_#pedestrians+50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle-density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    <enumeratedValueSet variable="obstacles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="general_01" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <metric>collisions.turtle-turtle</metric>
    <enumeratedValueSet variable="obstacle-diam">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="speed-sd" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="obstacles?">
        <value value="false"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="obstacle-density">
        <value value="0"/>
      </enumeratedValueSet>
      <steppedValueSet variable="#-pedestrians" first="2" step="2" last="48"/>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="obstacles?">
        <value value="false"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="obstacle-density">
        <value value="0"/>
      </enumeratedValueSet>
      <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="obstacles?">
        <value value="true"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="obstacle-density">
        <value value="5"/>
        <value value="10"/>
        <value value="15"/>
        <value value="20"/>
      </enumeratedValueSet>
      <steppedValueSet variable="#-pedestrians" first="2" step="2" last="48"/>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="obstacles?">
        <value value="true"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="obstacle-density">
        <value value="5"/>
        <value value="10"/>
        <value value="15"/>
        <value value="20"/>
      </enumeratedValueSet>
      <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    </subExperiment>
  </experiment>
  <experiment name="obstacle_size" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 10] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 70</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <metric>collisions.turtle-turtle</metric>
    <steppedValueSet variable="obstacle-diam" first="2" step="1" last="10"/>
    <enumeratedValueSet variable="speed-sd">
      <value value="0.26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;left or right&quot;"/>
      <value value="&quot;border to border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="obstacles?">
        <value value="false"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="obstacle-density">
        <value value="0"/>
      </enumeratedValueSet>
      <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="obstacles?">
        <value value="true"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="obstacle-density">
        <value value="5"/>
        <value value="10"/>
        <value value="15"/>
        <value value="20"/>
      </enumeratedValueSet>
      <steppedValueSet variable="#-pedestrians" first="10" step="10" last="200"/>
    </subExperiment>
  </experiment>
  <experiment name="general_02" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 30] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 90</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <metric>collisions.turtle-turtle</metric>
    <metric>real-density</metric>
    <steppedValueSet variable="obstacle-diam" first="2" step="2" last="10"/>
    <steppedValueSet variable="speed-sd" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;counterflow&quot;"/>
      <value value="&quot;crossflow&quot;"/>
      <value value="&quot;angle-determined&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
    <subExperiment>
      <steppedValueSet variable="obstacle-density" first="0" step="5" last="20"/>
      <steppedValueSet variable="#-pedestrians" first="5" step="5" last="45"/>
    </subExperiment>
    <subExperiment>
      <steppedValueSet variable="obstacle-density" first="0" step="5" last="20"/>
      <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    </subExperiment>
  </experiment>
  <experiment name="general_02 (v2)" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-null
while [ticks * dt &lt; 30] [go-null]
set collisions.turtle-turtle 0</setup>
    <go>go-null</go>
    <exitCondition>ticks * dt = 90</exitCondition>
    <metric>meanspacing</metric>
    <metric>spacingsd</metric>
    <metric>meanspeed</metric>
    <metric>speedsd</metric>
    <metric>collisions.turtle-turtle</metric>
    <metric>real-density</metric>
    <steppedValueSet variable="obstacle-diam" first="2" step="2" last="10"/>
    <steppedValueSet variable="speed-sd" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="B">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heading-choice">
      <value value="&quot;counterflow&quot;"/>
      <value value="&quot;crossflow&quot;"/>
      <value value="&quot;angle-determined&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tau">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desired-speed">
      <value value="1.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="A">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="obstacle-density" first="0" step="5" last="20"/>
    <subExperiment>
      <steppedValueSet variable="#-pedestrians" first="5" step="5" last="45"/>
    </subExperiment>
    <subExperiment>
      <steppedValueSet variable="#-pedestrians" first="50" step="10" last="200"/>
    </subExperiment>
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
