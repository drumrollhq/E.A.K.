require! {
  'audio/context'
  'audio/Track'
  'audio/tracks'
  'game/editor/tutorial/Step'
  'game/editor/tutorial/TutorialView'
}

add-track-events = (track, steps, view, editor) ->
  for step in steps
    step.set-view view, editor
    track.code step
    step.add-track-events track

get-track = (name) ->
  $ '<audio></audio>'
    .attr {
      src: "#{name}.#{context.format}"
      preload: \auto
    }
    .get 0

audio-track = new Track 'tutorials'

module.exports = class Tutorial
  ($el) ->
    @track-name = $el.attr 'track' or throw new Error 'You must specify a track'
    @has-help = ($el.attr 'has-help')?
    @track = get-track @track-name
    @audio-node = context.create-media-element-source @track

    time = 0
    @steps = for el in $el.find 'step' .get!
      step = new Step time, $ el
      time = step.end
      step

    @duration = time

    @_extras-revealed = 0

  attach: (editor-view) ->
    $el = editor-view.$ '.editor-tutorial'
      ..empty!

    @media = Popcorn @track
    @media.on 'ended' ~> @ended = true
    @media.on 'play' ~> tracks.focus 'tutorials'
    @media.on 'pause' ~> tracks.blur!
    @audio-node.connect audio-track.node

    @view = new TutorialView el: $el, tutorial: this

    step = @get-active-step-index!
    if step? and not @ended then @play-step step

    add-track-events @media, @steps, @view, editor-view

    @setup-condition-checker editor-view
    @check-step-conditions (editor-view.model.get 'html'), editor-view
    editor-view.model.on 'change:html', (model, code) ~> @check-step-conditions code, editor-view

    editor-view.on 'show-extra' ~>
      @_extras-revealed++
      code = editor-view.model.get 'html'
      @check-step-conditions code, editor-view

  detach: ->
    @media.pause!
    @audio-node.disconnect!
    @media.destroy!
    tracks.blur!
    @view.remove!
    @media = null

  setup-condition-checker: (editor-view) ->
    $ = -> editor-view.render-el.find.apply editor-view.render-el, Array.prototype.slice.apply arguments
    @_cond-checker = []
    prev = []

    check = ($, i, step, code) ~~>
      allowed = step.allowed code, $, @_extras-revealed
      if prev[i] is allowed then return else prev[i] = allowed

      @view.set-step-allowed i, allowed
      step.set-allowed allowed

    for let step, i in @steps
      @_cond-checker[i] = _.throttle check($, i, step), 250

  check-step-conditions: (code, editor-view) ->
    for step, i in @steps => @_cond-checker[i] code

  get-active-step-index: ->
    unless @media? then return
    time = @media.current-time!
    for step, i in @steps => if step.end > time then return i

  play-pause: ->
    unless @media? then return
    if @media.paused! and not @steps[@get-active-step-index!].waiting
      @media.play!
    else
      @media.pause!

  play-step: (i) ->
    unless @media? then return
    @media
      ..current-time @steps[i].start
      ..play!

