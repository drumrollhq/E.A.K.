out$, require, module <- require.register 'minigames/urls/maps'

export towns = {
  bulbous: [755 200]
  drudshire: [1165 425]
}

export main-map = {
  map-url: '/content/bg-tiles/url-minigame/map'
  nodes:
    phb: [1014 1235 'ponyhead-bay.com' 'to Ponyhead\nBay' -50 -210]
    flee: [1439 989 'flee.net' 'to Flee' -185 -110]
    drudshire: [1266 665 'drudshire.com' 'to Drudshire' -70 20]
    bulbous: [863 444 'bulbous-island.com' 'to Bulbous\nIsland' -70 15]
    shackerton: [602 849 'shackerton-by-sea.com' 'to Shackerton\nby-Sea' 70 -55]
    junction-phb: [1027 965 'ponyhead-bay.com']
    junction-flee: [1240 831 'flee.net']
    junction-drudshire: [1266 752 'drudshire.com']
    junction-bulbous: [857 545 'bulbous-island.com']
    junction-shackerton: [871 852 'shackerton-by-sea.com']
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
}

export drudshire = {
  map-url: '/content/bg-tiles/url-minigame/drudshire'
  start: x: 1000, y: 1700
  rects: [[0,100,835,190],[895,100,1200,190]]
}
