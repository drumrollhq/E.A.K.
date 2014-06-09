require! {
  'channels'
  'logger'
}

follow-ons = {
  intro: '#/play/levels/index.html'
}

const vw = 960px
const vh = 720px
const v-aspect = vh / vw

template = (name) -> """
  <video controls>
    <source src="/cutscenes/#{name}.webm" type="video/webm">
    <source src="/cutscenes/#{name}.mp4" type="video/mp4">
  </video>
  <a href="#{follow-ons[name]}" class="skip">Skip &rarr;</a>
"""

module.exports = class CutScene extends Backbone.View
  tag-name: 'div'
  class-name: 'cut-scene'
  events:
    'tap .skip': 'triggerSkip'

  initialize: ({name}) ->
    @subs = []
    @name = name
    @subs[*] = channels.window-size.subscribe @resize
    @subs[*] = channels.game-commands.filter ( .command is \stop ) .subscribe @finish

  render: ->
    @name |> template |> @$el.html
    @$video = @$el.find 'video'
    @video = @$video.get 0
    @resize!

    @start-video!

  remove: ->
    for sub in @subs => sub.unsubscribe!
    super!

  start-video: ~>
    @$video.on 'ended' @finish
    @video.play!

  finish: ~>
    @trigger 'finish'
    @remove!
    window.location.href = follow-ons[@name]

  trigger-skip: ~> @trigger 'skip'

  resize: ~>
    w = @$el.width!
    h = @$el.height!

    aspect = h / w
    if aspect > v-aspect
      if w > vw
        @natural-resize w, h
      else
        @scaled-resize w / vw, w, h

    else
      if h > vh
        @natural-resize w, h
      else
        @scaled-resize h / vh, w, h

  natural-resize: (w, h) ~>
    @$video.css {
      width: vw
      height: vh
      top: (h - vh) / 2
      left: (w - vw) / 2
    }

  scaled-resize: (scale, w, h) ~>
    @$video.css {
      width: scale * vw
      height: scale * vh
      top: (h - scale * vh) / 2
      left: (w - scale * vw) / 2
    }
