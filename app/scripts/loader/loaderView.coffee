module.exports = class LoaderView extends Backbone.View
  initialize: ->
    @model.on "change:stage", @setStage

    classes = ["prev", "current", "next"]

    @stages = for i in [0...3]
      (($ '<div class="stage"></div>').addClass classes[i]).appendTo @$el

  setStage: (model, stage) =>
    prev = @stages.shift()
    current = @stages[0]
    next = @stages[1]

    next.text stage

    (prev.removeClass "prev").addClass "next"
    (current.removeClass "current").addClass "prev"
    (next.removeClass "next").addClass "current"

    @stages.push prev

  render: ->
    @$el.showDialogue()
