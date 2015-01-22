require! 'translations'

template = """
  <h2>#{translations.cutscene.loading}</h2>
  <div class="stages"></div>
  <div class="bar">
    <div></div>
  </div>
  <p class="progress">0%</p>
"""

messages = translations.loading.messages

module.exports = class LoaderView extends Backbone.View
  tag-name: \div
  class-name: 'loader dialogue'

  initialize: ->
    unless @el.parent-node? then @$el.html template

    classes = <[ prev current next ]>

    $stage-container = @$ \.stages

    @stages = for class-name in classes
      $ '<div class="stage"></div>' .add-class class-name .append-to $stage-container

    @set-stage translations.loading.start

    @$progress-bar = @$ '.bar div'
    @$percent = @$ '.progress'
    @$progress-els = @$ '.progress, .bar'
    @$spinner = @$ '.loading-spinner-player'

    @displaying-progress = yes

    @model ?= new Backbone.Model
    @listen-to @model, \change:progress, @update-progress
    @update-progress @model, @model.get \progress
    @rotate-stages!

  set-stage: (stage) ~>
    prev = @stages.shift!
    [current, next] = @stages

    next.text stage

    prev.remove-class \prev .add-class \next
    current.remove-class \current .add-class \prev
    next.remove-class \next .add-class \current

    @stages.push prev

  rotate-stages: ->
    @int = set-interval ~>
      @set-stage messages[Math.floor Math.random! * messages.length]
    , 1500

  stop-stages: -> clear-interval int

  show: ->
    @$el.show-dialogue!
    set-timeout @force-spinner-repaint, 10

  hide: ->
    @$el.hide-dialogue!

  # Chrome has a strange bug where animations do not play on the spinner.
  # Forcing a repaint fixes this.
  force-spinner-repaint: ~>
    @$spinner
      ..css 'display' 'none'
      ..width!
      ..css 'display' 'block'

  remove: ->
    @stop-stages!
    super!

  update-progress: (model, progress) ~>
    if not progress? and @displaying-progress
      @$progress-els.css display: \none
      @displaying-progress = no
    else if progress? and not @displaying-progress
      @$progress-els.css display: \block
      @displaying-progress = yes

    @$progress-bar.width progress + '%'
    @$percent.text (Math.round progress) + '%'

  hide-progress: ->
    @$progress-els.css display: \none

  render: -> @$el.show-dialogue!
