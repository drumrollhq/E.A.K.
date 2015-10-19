require! {
  'assets'
  'audio/tracks'
  'lib/channels'
  'translations'
}

const vw = 1280px
const vh = 720px
const v-aspect = vh / vw
const sleep-timeout = 3000ms

template = ({video, subtitles}) -> """
  <div class="cutscene-vid">
    <video controls>
      <source src="#video.webm?_v=#{EAKVERSION}" type="video/webm">
      <source src="#video.mp4?_v=#{EAKVERSION}" type="video/mp4">
      <track kind="captions" src="#{assets.load-asset "/#EAK_LANG/#subtitles", \url, 'text/vtt'}">
    </video>
  </div>
  <button class="btn skip">#{translations.cutscene.skip} &rarr;</button>
"""

$util = $ '<div></div>'

module.exports = class CutScene extends Backbone.View
  tag-name: \div
  class-name: \cut-scene
  events:
    'click .skip': 'triggerSkip'
    'mousemove': 'wakeup'

  initialize: ({@name, @video, @subtitles, @next}) ->
    console.log arguments
    @subs = []

  load: ->
    @render!
    Promise.resolve!

  save-defaults: -> {
    type: \cutscene
    url: @name
    state: {}
  }

  start: ->
    @attach!
    @resize!
    @setup-video!
    @wakeup!

  cleanup: ->
    @remove!
    @trigger \cleanup

  render: ->
    @$el.html template this

    @$video-cont = @$el.find '.cutscene-vid'
    @$skip = @$el.find '.skip'
    @$video = @$video-cont.find 'video'
    if @$video.length > 0
      @popcorn = @$video .get 0 |> Popcorn
      @popcorn.media.text-tracks.onaddtrack = (e) ~>
        e.track.mode = \showing

  attach: ->
    @$el.append-to document.body
    @subs[*] = channels.window-size.subscribe @resize
    @subs[*] = channels.game-commands.filter ( .command is \stop ) .subscribe @finish

  setup-video: ~>
    @popcorn.on 'ended' @finish
    @popcorn.play!
    tracks.focus \cutscene, 0.4

  finish: ~>
    @trigger \finish
    @trigger \next @next
    tracks.blur!

  trigger-skip: ~>
    @trigger \skip
    @finish!

  wakeup: ->
    if @_sleep-timeout then clear-timeout @_sleep-timeout
    @_sleep-timeout = set-timeout @sleep, sleep-timeout
    if @asleep then @_wakeup!

  _wakeup: ->
    @asleep = false
    @$skip.remove-class 'asleep'

  sleep: ~>
    @asleep = true
    @$skip.add-class 'asleep'

  resize: ~>
    w = @$el.width!
    h = @$el.height!

    aspect = h / w
    if aspect > v-aspect
      @scaled-resize w / vw, w, h
    else
      @scaled-resize h / vh, w, h

  scaled-resize: (scale, w, h) ~>
    @$video-cont.css {
      width: scale * vw
      height: scale * vh
      top: (h - scale * vh) / 2
      left: (w - scale * vw) / 2
    }

    @$skip.css {
      top: 15 + (h - scale * vh) / 2
      left: 15 + (w - scale * vw) / 2
    }
