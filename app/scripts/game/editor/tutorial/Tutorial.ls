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
    @track = get-track @track-name
    @audio-node = context.create-media-element-source @track

    time = 0
    @steps = for el in $el.find 'step' .get!
      step = new Step time, $ el
      time = step.end
      step

    @duration = time

  attach: (editor-view) ->
    console.log 'attach' this
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

  detach: ->
    @media.pause!
    @audio-node.disconnect!
    @media.destroy!
    tracks.blur!
    @view.remove!
    @media = null

  get-active-step-index: ->
    unless @media? then return
    time = @media.current-time!
    for step, i in @steps => if step.end > time then return i

  play-pause: ->
    unless @media? then return
    if @media.paused! then @media.play! else @media.pause!

  play-step: (i) ->
    unless @media? then return
    @media
      ..current-time @steps[i].start
      ..play!

