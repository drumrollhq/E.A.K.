require! {
  'game/tutorial/TutorialComponent'
}

module.exports = class Tutorial extends Backbone.DeepModel
  attach: (editor-view) ->
    @editor-view = editor-view
    # @component = ReactDOM.render (React.create-element TutorialComponent, model: this),
    #   (@editor-view.$ '.editor-tutorial' .get 0)

  create-step: (id) ->
    if @get "steps.#{id}" then return
    step = {}
    @set "steps.#id", step
