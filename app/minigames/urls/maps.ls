out$, require, module <- require.register 'minigames/urls/maps'

export main-map = {
  map-url: '/content/bg-tiles/url-minigame/map'
  nodes:
    phb: [1014 1235 'to Ponyhead\nBay' -50 -210]
    flee: [1439 989 'to Flee' -185 -110]
    drudshire: [1266 665 'to Drudshire' -70 20]
    bulbous: [863 444 'to Bulbous\nIsland' -70 15]
    shackerton: [602 849 'to Shackerton\nby-the-Sea' 70 -55]
    junction-phb: [1027 965]
    junction-flee: [1240 831]
    junction-drudshire: [1266 752]
    junction-bulbous: [857 545]
    junction-shackerton: [871 852]
  paths: [
    [\phb \junction-phb [1047 1172] [1027 965]]
    [\flee \junction-flee [1239 1002] [1313 863]]
    [\drudshire \junction-drudshire [1271 719] [1266 752]]
    [\bulbous \junction-bulbous [830 488] [857 545]]
    [\shackerton \junction-shackerton [602 849] [774 792]]
    [\junction-phb \junction-flee [1137 966] [1157 832]]
    [\junction-flee \junction-drudshire [1240 831] [1263 785]]
    [\junction-drudshire \junction-bulbous [1097 718] [1045 459]]
    [\junction-bulbous \junction-shackerton [935 731] [843 771]]
    [\junction-shackerton \junction-phb [871 852] [972 938]]
  ]
}

export bulbous = {
  map-url: '/content/bg-tiles/url-minigame/bulbous-island'
  start: x: 1000, y: 1700 #Arca start point
  rects: [
    [400 300 570 148] #x y width height
    [1030 300 570 148]
    [870 300 260 75]
    [400 348 115 1100]
    [1482 348 118 1100]
    [415 1350 555 600]
    [1030 1350 552 600]
    [545 1170 425 150]
    [545 480 425 78]
    [545 508 145 712]
    [1030 1170 422 150]
    [1030 480 422 78]
    [1285 508 167 712]
    [710 578 260 72]
    [710 600 105 470]
    [710 1020 260 130]
    [835 670 135 330]
    [1030 670 132 330]
    [1030 578 235 72]
    [1030 1020 235 130]
    [1183 600 82 470]
  ]
}

export drudshire = {
  map-url: '/content/bg-tiles/url-minigame/drudshire'
  start: x: 1000, y: 1700
  rects: [[0,100,835,190],[895,100,1200,190]]
}
