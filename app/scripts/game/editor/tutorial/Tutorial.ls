require! {
  'audio/context'
  'game/editor/tutorial/Step'
  'game/editor/tutorial/TutorialView'
}

add-track-events = (track, steps) ->
  for step in steps
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

    @view = new TutorialView el: $el, tutorial: this

  detach: ->
    @view.remove!

