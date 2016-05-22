require! 'lib/channels'

channels.parse 'key-press: f' .subscribe ->
  unless stats-showing then show!

stats-showing = false

show = ->
  stats = new Stats!
  stats.dom-element.style <<< position: \absolute, bottom: 0, right: 0
  document.body.append-child stats.dom-element

  channels.pre-frame.subscribe -> stats.begin!
  channels.post-frame.subscribe -> stats.end!
