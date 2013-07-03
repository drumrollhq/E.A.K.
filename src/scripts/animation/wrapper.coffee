module.exports = class AnimationWrapper extends Backbone.View
  start: =>
    @$el.hideDialogue()
    @trigger "done"
