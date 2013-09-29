module.exports = class AnimationWrapper extends Backbone.View
  start: ~>
    @$el.hide-dialogue!
    @trigger \done
