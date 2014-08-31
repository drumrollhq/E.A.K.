require! {
  'game/editor/tutorial/template'
}

module.exports = class TutorialView extends Backbone.View
  initialize: ({@tutorial}) ->
    console.log this
    @render!

  render: ->
    @{tutorial} |> template |> @$el.html

  remove: ->
    @$el.empty!
    @stop-listening!
    @undelegate-events!
