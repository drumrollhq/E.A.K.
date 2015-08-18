out$, require, module <- require.register 'minigames/urls/maps'

export towns = {
  bulbous: [745 190]
  shackerton: [895 1275]
}

export main-map = {
  map-url: '/content/bg-tiles/url-minigame/map'
  nodes:
    shackerton: [1014 1235 'shackerton-by-sea.com' 'to Shackerton\nBy-Sea' -50 -210]
    flee: [1439 989 'flee.net' 'to Flee' -185 -110]
    drudshire: [1266 665 'drudshire.com' 'to Drudshire' -70 20]
    bulbous: [863 444 'bulbous-island.com' 'to Bulbous\nIsland' -70 15]
    phb: [602 849 'ponyhead-bay.com' 'to Ponyhead\nBay' 70 -55]
    junction-shackerton: [1027 965 'shackerton-by-sea.com']
    junction-flee: [1240 831 'flee.net']
    junction-drudshire: [1266 752 'drudshire.com']
    junction-bulbous: [857 545 'bulbous-island.com']
    junction-phb: [871 852 'ponyhead-bay.com']
  paths: [
    [\shackerton \junction-shackerton [1047 1172] [1027 965]]
    [\flee \junction-flee [1239 1002] [1313 863]]
    [\drudshire \junction-drudshire [1271 719] [1266 752]]
    [\bulbous \junction-bulbous [830 488] [857 545]]
    [\phb \junction-phb [602 849] [774 792]]
    [\junction-shackerton \junction-flee [1137 966] [1157 832]]
    [\junction-flee \junction-drudshire [1240 831] [1263 785]]
    [\junction-drudshire \junction-bulbous [1097 718] [1045 459]]
    [\junction-bulbous \junction-phb [935 731] [843 771]]
    [\junction-phb \junction-shackerton [871 852] [972 938]]
  ]
}

export bulbous = {
  map-url: '/content/bg-tiles/url-minigame/bulbous-island'
  start: x: 1000, y: 1700 #Arca start point
  scale: 0.13
  rects: [
    [350 300 600 200]
    [1050 300 600 200]
    [875 300 250 100 \enter:onions-r-us]
    [350 400 75 1125]
    [1575 400 75 1125]
    [350 1450 600 500]
    [1050 1450 600 500]
    [475 1250 475 150]
    [475 550 475 150]
    [475 550 250 850]
    [1050 1250 475 150]
    [1050 550 475 150]
    [1275 550 250 850]
    [775 750 200 125]
    [775 750 125 450]
    [775 1075 200 125]
    [925 900 150 150]
    [1025 750 200 125]
    [1025 1075 200 125]
    [1100 750 125 450]
    [925 1775 150 50 \exit]

    # Walk-through-able rectangles
    [475 1375 250 100 \path:hospital]
    [1275 1375 250 100 \path:school]
    [875 850 250 250 \path:fountain]
    [700 750 100 125 \path:onion-farm]
    [925 375 150 200 \path:onions-r-us]
  ]

  buildings:
    onions-r-us:
      map-url: '/content/bg-tiles/url-minigame/onions-r-us'
      position: x: 750, y: 50
      start: x: 1000, y: 1400
      scale: 1/4
      player-scale: 0.8
      rects: [
        [0 1650 2000 125 \exit]
        [0 1300 820 400]
        [1180 1300 820 400]
        [0 1250 750 100]
        [1250 1250 750 100]
        [0 0 700 1300]
        [1305 0 700 1300]
        [0 0 2000 625]
        [810 730 130 480]
        [1055 730 130 480]
        [500 1150 1000 800 \path:onions-r-us]
        [500 700 260 450 \path:onions-r-us/red-onions]
        [760 700 240 450 \path:onions-r-us/white-onions]
        [1000 700 240 450 \path:onions-r-us/yellow-onions]
        [1240 700 240 450 \path:onions-r-us/spring-onions]
        [600 625 800 75 \path:onions-r-us/pickled-onions]
      ]
}

export drudshire = {
  map-url: '/content/bg-tiles/url-minigame/drudshire'
  start: x: 1000, y: 1700
  scale: 0.12
  rects: [[0,100,835,190],[895,100,1200,190]]
}

export shackerton = {
  map-url: '/content/bg-tiles/url-minigame/shackerton'
  start: x: 1040, y: 168 #Arca start point
  scale: 0.1
  rects: [
    [0,0,1000,200] #0
    [1075,0,1000,200]#1
    [0,150,200,1450]#2
    [250,245,350,380]#3
    [625,245,375,380]#4
    [1075,245,300,355]#5
    [1425,150,1000,450]#6
    [250,600,150,675]#7
    [350,900,250,375]#8
    [425,650,400,225]#9
    [850,600,150,675]#10
    [625,900,250,375]#11
    [1075,625,300,275]#12
    [1425,625,325,275]#13
    [1775,575,1000,400]#14
    [1075,925,300,350]#15
    [1425,925,375,450]#16
    [225,1325,275,225]#17
    [175,1575,375,50]#18
    [525,1325,475,300]#19
    [950,1600,175,50]#20
    [1075,1325,400,300]#21
    [975, 0, 100, 75 \exit]
    [400,625,450,275 \path:ristorante-del-amore]
    [1375,600,400,325 \path:love-park]
    [200,1275,325,300 \path:public-toilets]
    [1000, 1375, 200, 200 \path:loveboat]
  ]
}