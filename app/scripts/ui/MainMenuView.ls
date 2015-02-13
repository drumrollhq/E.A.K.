require! {
  'user'
}

module.exports = class MainMenuView extends Backbone.View
  events:
    'click .new-game': 'newGame'

  initialize: ({app}) ->
    @app = app

  new-game: ->
    @$el.hide-dialogue!
    @app.show-loader!

    user.new-game start: <[cutscene intro]>
      .then (game) ~>
        console.log 'done' game.to-json!
        # @app.load 'cutscene' 'intro'
      .catch (e) ~>
        @app.error 'Error starting new game: ' + (e.response-JSON?.details or e.message or e)
