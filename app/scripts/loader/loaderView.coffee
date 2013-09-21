template = require "loader/template"

module.exports = class LoaderView extends Backbone.View
  tagName: "div"
  className: "loader dialogue"

  initialize: ->
    if @el.parentNode is null
      @$el.html template()

    classes = ["prev", "current", "next"]

    $stageContainer = @$ ".stages"

    @stages = for classname in classes
      (($ '<div class="stage"></div>').addClass classname).appendTo $stageContainer

    @listenTo @model, "change:stage", @setStage

    @setStage @model, @model.get "stage"

    @$progressBar = @$ ".bar div"
    @$percent = @$ ".progress"
    @$progressEls = @$ ".progress, .bar"

    @displayingProgress = yes

    @listenTo @model, "change:progress", @updateProgress

    @updateProgress @model, @model.get "progress"

  setStage: (model, stage) =>
    prev = @stages.shift()
    current = @stages[0]
    next = @stages[1]

    next.text stage

    (prev.removeClass "prev").addClass "next"
    (current.removeClass "current").addClass "prev"
    (next.removeClass "next").addClass "current"

    @stages.push prev

  updateProgress: (model, progress) =>
    if progress is null and @displayingProgress
      @$progressEls.css "display", "none"
      @displayingProgress = no
    else if progress isnt null and not @displayingProgress
      @$progressEls.css "display", "block"
      @displayingProgress = yes

    @$progressBar.width progress + "%"
    @$percent.text (Math.round progress) + "%"

  render: ->
    @$el.showDialogue()
