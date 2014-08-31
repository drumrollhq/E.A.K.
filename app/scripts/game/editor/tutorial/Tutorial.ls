require! {
  'audio/context'
  'game/editor/tutorial/Step'
  'game/editor/tutorial/TutorialView'
}

add-track-events = (track, steps, view) ->
  for step in steps
    step.set-view view
    track.code step
    step.add-track-events track

get-track = (name) ->
  $ '<audio></audio>'
    .attr {
      src: "#{name}.#{context.format}"
      preload: \auto
    }
    .get 0

module.exports = class Tutorial
  ($el) ->
    @track-name = $el.attr 'track' or throw new Error 'You must specify a track'
    @track = get-track @track-name

    time = 0
    @steps = for el in $el.find 'step' .get!
      step = new Step time, $ el
      time = step.end
      step

    @duration = time
    console.log this

  attach: (editor-view) ->
    $el = editor-view.$ '.editor-tutorial'
      ..empty!

    @media = Popcorn @track
    @media.on 'ended' ~>
      @ended = true
      console.log 'ended'

    @view = new TutorialView el: $el, tutorial: this

    step = @get-active-step-index!
    console.log @media.current-time!, step, @ended
    if step? and not @ended then @play-step step

    add-track-events @media, @steps, @view

  detach: ->
    @media.pause!
    @media.destroy!
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

