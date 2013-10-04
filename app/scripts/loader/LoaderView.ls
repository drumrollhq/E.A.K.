require! 'loader/template'

module.exports = class LoaderView extends Backbone.View
  tag-name: \div
  class-name: 'loader dialogue'

  initialize: ->
    unless @el.parent-node? then @$el.html template!

    classes = <[ prev current next ]>

    $stage-container = @$ \.stages

    @stages = for class-name in classes
      $ '<div class="stage"></div>' .add-class class-name .append-to $stage-container

    @listen-to @model, \change:stage, @set-stage

    @set-stage @model, @model.get \stage

    @$progress-bar = @$ '.bar div'
    @$percent = @$ '.progress'
    @$progress-els = @$ '.progress .bar'

    @displaying-progress = yes

    @listen-to @model, \change:progress, @update-progress

    @update-progress @model, @model.get \progress

  set-stage: (model, stage) ~>
    prev = @stages.shift!
    [current, next] = @stages

    next.text stage

    prev.remove-class \prev .add-class \next
    current.remove-class \current .add-class \prev
    next.remove-class \next .add-class \current

    @stages.push prev

  update-progress: (model, progress) ~>
    if not progress? and @displaying-progress
      @$progress-els.css display: \none
      @displaying-progress = no
    else if progress? and not @displaying-progress
      @$progress-els.css display: \block
      @displaying-progress = yes

    @$progress-bar.width progress + '%'
    @$percent.text (Math.round progress) + '%'

  render: -> @$el.show-dialogue!
