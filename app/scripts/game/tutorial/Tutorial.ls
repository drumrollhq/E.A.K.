require! {
  'game/tutorial/TutorialComponent'
}

module.exports = class Tutorial extends Backbone.Model
  attach: (editor-view) ->
    @editor-view = editor-view
    @component = React.render (React.create-element TutorialComponent, model: this),
      (@editor-view.$ '.editor-tutorial' .get 0)
