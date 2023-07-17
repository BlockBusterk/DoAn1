Extensions [gis]

globals [
  landcover
  amenity

  roads
  buildings
  timeGBFS
  timeA*
  timeUCS
  timeBFS
  timeDFS
]

breed [vertices vertex]
breed [commuters commuter]

patches-own[
  center?

]

vertices-own [
  entrance?

  visited?
  hvalue

  cost-gbfs
  cost-a-star
  cost-ucs
  cost-bfs
  cost-dfs
  pre-vertice-pointer
]

commuters-own [
  path-gbfs
  path-a-star
  path-ucs
  path-bfs
  path-dfs
  destination
  path-cost-gbfs
  path-cost-a-star
  path-cost-ucs
  path-cost-bfs
  path-cost-dfs
]

to setup
  ca

  import-scenes
  import-buildings
  import-roads

 import-scenes
  import-buildings
  import-roads

  import-scenes
  import-buildings
  import-roads

  set-entrances
  set timeGBFS 0
  set timeUCS 0
  set timeA* 0
  set timeBFS 0
  set timeDFS 0

end

to import-scenes
  if map-type = "ThuDuc_HCM"[
    set landcover gis:load-dataset "map/1/landcover-polygon.shp"
    set amenity gis:load-dataset "map/1/amenity_polygons-polygon.shp"
  ]
   if map-type = "Quan2_HCM"[
    set landcover gis:load-dataset "map/2/landcover-polygon.shp"
    set amenity gis:load-dataset "map/2/amenity_polygons-polygon.shp"
  ]
  if map-type = "QuanHoangMai_HaNoi"[
    set landcover gis:load-dataset "map/3/landcover-polygon.shp"
    set amenity gis:load-dataset "map/3/amenity_polygons-polygon.shp"
  ]
  if map-type = "Florida_America"[
    set landcover gis:load-dataset "map/4/landcover-polygon.shp"
    set amenity gis:load-dataset "map/4/amenity_polygons-polygon.shp"
  ]
  if map-type = "ChangChun_China"[
    set landcover gis:load-dataset "map/5/landcover-polygon.shp"
    set amenity gis:load-dataset "map/5/amenity_polygons-polygon.shp"
  ]
  gis:set-drawing-color 33 gis:fill landcover 3
  gis:set-drawing-color 133 gis:fill amenity 1

end

to import-buildings
  if map-type = "ThuDuc_HCM"[
    set buildings gis:load-dataset "map/1/buildings-polygon.shp"
  ]
 if map-type = "Quan2_HCM"[
    set buildings gis:load-dataset "map/2/buildings-polygon.shp"
  ]
   if map-type = "QuanHoangMai_HaNoi"[
    set buildings gis:load-dataset "map/3/buildings-polygon.shp"
  ]
   if map-type = "Florida_America"[
    set buildings gis:load-dataset "map/4/buildings-polygon.shp"
  ]
   if map-type = "ChangChun_China"[
    set buildings gis:load-dataset "map/5/buildings-polygon.shp"
  ]

  gis:set-drawing-color gray gis:fill buildings 1
  gis:set-world-envelope gis:envelope-of buildings

  foreach gis:feature-list-of buildings [
    building ->
    let center gis:location-of gis:centroid-of building
    ask patch item 0 center item 1 center [
      set center? true
    ]
  ]
end

to import-roads
  if map-type = "ThuDuc_HCM"[
    set roads gis:load-dataset "map/1/roads-line.shp"
  ]
  if map-type = "Quan2_HCM"[
    set roads gis:load-dataset "map/2/roads-line.shp"
  ]
  if map-type = "QuanHoangMai_HaNoi"[
    set roads gis:load-dataset "map/3/roads-line.shp"
  ]
  if map-type = "Florida_America"[
    set roads gis:load-dataset "map/4/roads-line.shp"
  ]
  if map-type = "ChangChun_China"[
    set roads gis:load-dataset "map/5/roads-line.shp"
  ]

  foreach gis:feature-list-of roads [
    road-feature ->
    foreach gis:vertex-lists-of road-feature [
      v ->
      let pre-node-pointer nobody

      foreach v [
        node ->
        let location gis:location-of node
        if not empty? location [
          create-vertices 1 [
            set shape "star"
            set size 0.3
            set color brown
            setxy item 0 location item 1 location
            if pre-node-pointer != nobody [
              create-link-with pre-node-pointer
            ]
            set pre-node-pointer self
          ]
        ]
      ]
    ]
  ]
  delete-duplicates
  delete-not-connected

  reset-entire-path
end

to delete-duplicates
  ask vertices [
    if count vertices-here > 1[
      ask other vertices-here [
        ask myself [
          create-links-with other [link-neighbors] of myself
        ]
        die
      ]
    ]
  ]

end

to delete-not-connected
  ask vertices [set visited? false]
  ask one-of vertices [set visited? true]
  repeat 500 [
    ask vertices with [ visited? = true] [
      ask link-neighbors [
        set visited? true
      ]
    ]
  ]
  ask vertices with [ visited? = false][die]
end

to set-entrances
  ask patches with [center? = true][
    let entrance min-one-of vertices [distance myself]
    ask entrance [
      set entrance? true
      set shape "star"
      set size 0.8
      set color turquoise
    ]
  ]
end

to generate-commuters
  ask commuters [
    if destination != nobody [
      ask destination [
        set shape "star"
        set size 0.8
        set color red
      ]
    ]
  ]
  ask commuters[die]

  ;;create the commuter agents
  create-commuters 1 [
    set color white
    set size 1.2
    set shape "person"
    set destination nobody
    set path-gbfs []
    set path-a-star []
    set path-ucs []
    set path-bfs []
    set path-dfs []
    let mynode one-of vertices with [ center? != true ]
    move-to mynode
    watch-me
  ]
    reset-ticks

end

to generate-destination
  ask commuters [
    if destination != nobody [
      ask destination [
        set shape "star"
        set size 0.8
        set color red
      ]
    ]

    set destination one-of vertices with [ entrance? = true ]
    ask destination [
      set size 1.5
      set color yellow
      set shape "house"
      watch-me
    ]

  ]
end

to clear-path
  ask commuters[
    set path-gbfs []
    set path-a-star []
    set path-ucs []
    set path-bfs []
    set path-dfs []

    set path-cost-gbfs 0
    set path-cost-a-star 0
    set path-cost-ucs 0
    set path-cost-bfs 0
    set path-cost-dfs 0
  ]
  set timeGBFS 0
  set timeUCS 0
  set timeA* 0
  set timeBFS 0
  set timeDFS 0
  clear-plot

  reset-entire-path
end

to reset-entire-path

  ask links [set thickness 0.2 set color 23]
end
to list-plots
  repeat 2[
    generate-commuters
    generate-destination
    reset-perspective
    gbfs
    reset-perspective
    a-star
    reset-perspective
    ucs
    reset-perspective
    bfs
    reset-perspective
    dfs
    let rd random-float 1.0
    export-view (word "e:/Year3HK2/ĐoAn1/plots/" map-type"_"(remove ":" date-and-time) ".png")
    export-all-plots (word "e:/Year3HK2/ĐoAn1/plots/"map-type"_"(remove ":" date-and-time) ".csv")
    wait 3
    clear-path
  ]
end

to export-file
  let f number-file-export
  repeat f[
    generate-commuters
    generate-destination
    reset-perspective
    gbfs
    reset-perspective
    a-star
    reset-perspective
    ucs
    reset-perspective
    bfs
    reset-perspective
    dfs
    let rd random-float 1.0
    export-view (word "e:/Year3HK2/ĐoAn1/plots/" map-type"_"(remove ":" date-and-time) ".png")
    export-all-plots (word "e:/Year3HK2/ĐoAn1/plots/" map-type"_"(remove ":" date-and-time) ".csv")
    wait 3
    clear-path
  ]
end
to go
  ask commuters [
    let path []
    if search-strategy = "GBFS" [ set path path-gbfs ]
    if search-strategy = "A*" [ set path path-a-star ]
    if search-strategy = "UCS" [ set path path-ucs ]
    if search-strategy = "BFS" [ set path path-bfs ]
    if search-strategy = "DFS" [ set path path-dfs ]

    if not empty? path [
      let pre-vertice nobody
      let next-vertice first path
      let i 0
      foreach path [
        v ->
        move-to v
        watch-me
        if i != 0 [
          set next-vertice v
          ask link [who] of pre-vertice [who] of next-vertice  [set color orange set thickness 0.1]
        ]
        set pre-vertice next-vertice
        set i (i + 1)

        ;print the process of going to goal
        display
        wait delay
      ]
      reset-entire-path
    ]
  ]
end

to gbfs
  reset-ticks
  ask commuters [
    let cmter self
    let des-of-cmter [destination] of cmter

    if destination != nobody [
      ;reset path of commuter
      set path-gbfs []

      let frontier []
      ask vertices [
        set visited? false
        set hvalue [distance des-of-cmter] of self
      ]

      ;root is vertex that at the same patch with commuter
      let root one-of vertices-here

      ;push root to frontier
      ask root [
        set pre-vertice-pointer nobody
        set cost-gbfs 0
      ]
      set frontier lput root frontier

      let foundGoal? false
      while [not empty? frontier and foundGoal? = false] [
        ;vertex which h is minimum is first chosen
        set frontier sort-by [[v1 v2] -> [hvalue] of v1 < [hvalue] of v2] frontier
        let current-vertice first frontier
        ask current-vertice [set visited? true watch-me]
        set frontier but-first frontier
        set timeGBFS timeGBFS + 1
        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          if not visited? and not member? self frontier and foundGoal? = false [
            set cost-gbfs ([cost-gbfs] of current-vertice + distance current-vertice)
            set pre-vertice-pointer current-vertice
            set frontier lput self frontier

            ;set link along path to another color
            ask link [who] of current-vertice [who] of self  [set color yellow set thickness 0.3]

            ;print path-find process sequentially
            wait delay
            display
          ]

          if self = des-of-cmter [
            set current-vertice self

            ;push all vertex lead to destination to path of commuter
            ask cmter[
              set path-cost-gbfs 0
            ]
            while [current-vertice != root] [
              ask cmter[
                set path-cost-gbfs path-cost-gbfs + [cost-gbfs] of current-vertice
                set path-gbfs fput current-vertice path-gbfs
                set current-vertice [pre-vertice-pointer] of current-vertice

                ;set link along path to another color
                ask link [who] of current-vertice [who] of first path-gbfs  [set color yellow + 4 set thickness 0.3]

                ;print path-find process sequentially
                wait delay
                display
              ]
            ]
            ask cmter[
              set path-gbfs fput root path-gbfs
            ]
            set foundGoal? true
            stop
          ]
        ]
      ]
    ]
  ]
  tick
end

to a-star
  reset-ticks
  ask commuters [
    let cmter self
    let des-of-cmter [destination] of cmter

    if destination != nobody [
      ;reset path of commuter
      set path-a-star []

      let frontier []
      ask vertices [
        set visited? false
        set hvalue [distance des-of-cmter] of self
      ]

      ;root is vertex that at the same patch with commuter
      let root one-of vertices-here

      ;push root to frontier
      ask root [
        set pre-vertice-pointer nobody
        set cost-a-star 0
      ]
      set frontier lput root frontier

      while [not empty? frontier] [
        ;vertex which h + g is minimum is first chosen
        set frontier sort-by [[v1 v2] -> ([hvalue] of v1 + [cost-a-star] of v1) < ([hvalue] of v2 + [cost-a-star] of v2)]  frontier
        let current-vertice first frontier
        ask current-vertice [set visited? true watch-me]
        set frontier but-first frontier
        set timeA* timeA* + 1
        if current-vertice = destination [
          set path-cost-a-star 0
          ;push all vertex lead to destination to path of commuter
          while [current-vertice != root] [
            set path-cost-a-star path-cost-a-star + [cost-a-star] of current-vertice
            set path-a-star fput current-vertice path-a-star
            set current-vertice [pre-vertice-pointer] of current-vertice

            ;set link along path to another color
            ask link [who] of current-vertice [who] of first path-a-star  [set color violet + 4 set thickness 0.3]

            ;print path-find process sequentially
            wait delay
            display
          ]
          set path-a-star fput root path-a-star
          stop
        ]

        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          if not visited? [
            set pre-vertice-pointer current-vertice
            ;path cost of "self"
            set cost-a-star ([cost-a-star] of current-vertice + distance current-vertice)

            let change-frontier? false
            foreach frontier [
              v ->
              if v = self [
                set change-frontier? true
                ;if current vertex in frontier had path cost greater than successor "self", we would change current path cost to path cost of "self"
                if ([cost-a-star] of self + hvalue) < ([cost-a-star] of v + [hvalue] of v) [
                  ask v [set cost-a-star [cost-a-star] of myself]
                ]
              ]
            ]
            if change-frontier? = false [
              set frontier lput self frontier
              ask link [who] of current-vertice [who] of self  [set color violet set thickness 0.3]

              ;print path-find process sequentially
              wait delay
              display
            ]
          ]
        ]
      ]
    ]
  ]
  tick
end

to ucs
  reset-ticks
  ask commuters [
    let cmter self

    if destination != nobody [
      ;reset path of commuter
      set path-ucs []

      let frontier []
      ask vertices [ set visited? false ]

      ;root is vertex that at the same patch with commuter
      let root one-of vertices-here

      ;push root to frontier
      ask root [
        set pre-vertice-pointer nobody
        set cost-ucs 0
      ]
      set frontier lput root frontier

      while [not empty? frontier] [
        ;vertex which g is minimum is first chosen
        set frontier sort-by [[v1 v2] -> [cost-ucs] of v1 < [cost-ucs] of v2]  frontier
        let current-vertice first frontier
        ask current-vertice [set visited? true watch-me]
        set frontier but-first frontier
        set timeUCS timeUCS + 1
        if current-vertice = destination [
          set path-cost-ucs 0
          ;push all vertex lead to destination to path of commuter
          while [current-vertice != root] [
            set path-cost-ucs path-cost-ucs + [cost-ucs] of current-vertice
            set path-ucs fput current-vertice path-ucs
            set current-vertice [pre-vertice-pointer] of current-vertice

            ;set link along path to another color
            ask link [who] of current-vertice [who] of first path-ucs  [set color blue + 4 set thickness 0.3]

            ;print path-find process sequentially
            wait delay
            display
          ]
          set path-ucs fput root path-ucs
          stop
        ]

        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          if not visited? [
            set pre-vertice-pointer current-vertice
            ;path cost of "self"
            set cost-ucs ([cost-ucs] of current-vertice + distance current-vertice)

            let change-frontier? false
            foreach frontier [
              v ->
              if v = self [
                set change-frontier? true
                ;if current vertex in frontier had path cost greater than successor "self", we would change current path cost to path cost of "self"
                if [cost-ucs] of self < [cost-ucs] of v [
                  ask v [set cost-ucs [cost-ucs] of myself]
                ]
              ]
            ]
            if change-frontier? = false [
              set frontier lput self frontier

              ;set link along path to another color
              ask link [who] of current-vertice [who] of self  [set color blue set thickness 0.3]

              ;print path-find process sequentially
              wait delay
              display
            ]
          ]
        ]
      ]
    ]
  ]
  tick
end

to bfs
  reset-ticks
  ask commuters [
    if destination != nobody [
      let cmter self
      let des-of-cmter [destination] of cmter

      ;reset path of commuter
      set path-bfs []

      let frontier []
      ask vertices [
        set visited? false
      ]

      ;root is vertex that at the same patch with commuter
      let root one-of vertices-here

      ;push root to frontier
      ask root [
        set pre-vertice-pointer nobody
        set cost-bfs 0
      ]
      set frontier lput root frontier

      let foundGoal? false
      while [not empty? frontier and foundGoal? = false] [

        ;vertex which at front of frontier is first chosen
        let current-vertice first frontier
        ask current-vertice [set visited? true watch-me]
        set frontier but-first frontier
        set timeBFS timeBFS + 1
        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          if not visited? and not member? self frontier and foundGoal? = false[
            set cost-bfs ([cost-bfs] of current-vertice + distance current-vertice)
            set pre-vertice-pointer current-vertice
            set frontier lput self frontier

            ;set link along path to another color
            ask link [who] of current-vertice [who] of self  [set color green set thickness 0.3]

            ;print path-find process sequentially
            wait delay
            display
          ]

          ;we stop the process whenever the successor is goal
          if self = des-of-cmter [
            set current-vertice self

            ;push all vertex lead to destination to path of commuter
            ask cmter[
              set path-cost-bfs 0
            ]
            while [current-vertice != root] [
              ask cmter[
                set path-cost-bfs path-cost-bfs + [cost-bfs] of current-vertice
                set path-bfs fput current-vertice path-bfs
                set current-vertice [pre-vertice-pointer] of current-vertice

                ;set link along path to another color
                ask link [who] of current-vertice [who] of first path-bfs  [set color green + 4 set thickness 0.3]

                ;print path-find process sequentially
                wait delay
                display
              ]
            ]
            ask cmter[
              set path-bfs fput root path-bfs
            ]
            set foundGoal? true
            stop
          ]
        ]
      ]
    ]
  ]
  tick
end

to dfs
  reset-ticks
  ask commuters [
    if destination != nobody [
      let cmter self
      let des-of-cmter [destination] of cmter

      ;reset path of commuter
      set path-dfs []

      let frontier []
      ask vertices [
        set visited? false
      ]

      ;root is vertex that at the same patch with commuter
      let root one-of vertices-here

      ;push root to frontier
      ask root [
        set pre-vertice-pointer nobody
        set cost-dfs 0
      ]
      set frontier lput root frontier

      let foundGoal? false
      while [not empty? frontier and foundGoal? = false] [

        ;vertex which at front of frontier is first chosen
        let current-vertice first frontier
        ask current-vertice [set visited? true watch-me]
        set frontier but-first frontier
        set timeDFS timeDFS + 1
        ;push successors which were not in the extended-state to frontier
        ask [link-neighbors] of current-vertice[
          if not visited? and foundGoal? = false [
            set cost-dfs ([cost-dfs] of current-vertice + distance current-vertice)
            set pre-vertice-pointer current-vertice
            set frontier fput self frontier

            ;set link along path to another color
            ask link [who] of current-vertice [who] of self  [set color pink set thickness 0.3]

            ;print path-find process sequentially
            wait delay
            display
          ]

          ;we stop the process whenever the successor is goal
          if self = des-of-cmter [
            set current-vertice self

            ;push all vertex lead to destination to path of commuter
            ask cmter[
              set path-cost-dfs 0
            ]
            while [current-vertice != root] [
              ask cmter[
                set path-cost-dfs path-cost-dfs + [cost-dfs] of current-vertice
                set path-dfs fput current-vertice path-dfs
                set current-vertice [pre-vertice-pointer] of current-vertice

                ;set link along path to another color
                ask link [who] of current-vertice [who] of first path-dfs  [set color pink + 4 set thickness 0.3]

                ;print path-find process sequentially
                show "find root"
                wait delay
                display
              ]
            ]
            ask cmter[
              set path-dfs fput root path-dfs
            ]
            set foundGoal? true
            stop
          ]
        ]
      ]
    ]
  ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
592
10
1492
560
-1
-1
14.63
1
10
1
1
1
0
0
0
1
-30
30
-18
18
0
0
1
ticks
30.0

CHOOSER
6
17
171
62
map-type
map-type
"ThuDuc_HCM" "Quan2_HCM" "QuanHoangMai_HaNoi" "Florida_America" "ChangChun_China"
4

BUTTON
189
19
283
52
Create Map
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
77
281
110
delay
delay
0.1
1
0.1
0.1
1
seconds
HORIZONTAL

BUTTON
0
124
141
157
focus
watch one-of commuters
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
163
127
298
160
unfocus
reset-perspective
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
1
169
143
202
generate commuters
generate-commuters
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
161
169
301
202
generate destination
generate-destination
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
1
227
134
260
Find path by GBFS
reset-perspective\ngbfs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
165
223
299
268
Path cost GBFS
[path-cost-gbfs] of one-of commuters
17
1
11

TEXTBOX
6
264
156
282
Path color: yellow
10
0.0
1

BUTTON
2
287
134
320
Find path by A*
reset-perspective\na-star
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
5
328
155
346
Path color: violet
10
0.0
1

BUTTON
2
351
135
384
Find path by UCS
reset-perspective\nucs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
5
390
155
408
Path color: blue\n
10
0.0
1

BUTTON
1
410
135
443
Find path by BFS
reset-perspective\nbfs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
3
449
153
467
Path color: green
10
0.0
1

BUTTON
0
469
134
502
Find path by DFS
reset-perspective\ndfs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
3
507
153
525
Path color: pink
10
0.0
1

MONITOR
165
288
299
333
Path cost A*
[path-cost-a-star] of one-of commuters
17
1
11

MONITOR
164
348
298
393
Path cost UCS
[path-cost-ucs] of one-of commuters
17
1
11

MONITOR
162
409
300
454
Path cost BFS
[path-cost-bfs] of one-of commuters
17
1
11

MONITOR
162
470
301
515
Path cost DFS
[path-cost-dfs] of one-of commuters
17
1
11

BUTTON
2
535
96
568
Reset roads
clear-path
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
319
533
439
566
Go to destination
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
151
523
289
568
search-strategy
search-strategy
"GBFS" "A*" "UCS" "BFS" "DFS"
4

PLOT
315
24
579
416
plot
Time
Cost
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"GBFS" 1.0 0 -1184463 true "" "plotxy timeGBFS [path-cost-gbfs] of one-of commuters"
"A*" 1.0 0 -10141563 true "" "plotxy timeA*  [path-cost-a-star] of one-of commuters"
"UCS" 1.0 0 -13345367 true "" "plotxy timeUCS [path-cost-ucs] of one-of commuters"
"BFS" 1.0 0 -13840069 true "" "plotxy timeBFS  [path-cost-bfs] of one-of commuters"
"DFS" 1.0 0 -2064490 true "" "plotxy timeDFS [path-cost-dfs] of one-of commuters"

SLIDER
315
456
487
489
number-file-export
number-file-export
1
10
1.0
1
1
NIL
HORIZONTAL

BUTTON
500
457
585
490
NIL
export-file
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
NetLogo 6.3.0
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
