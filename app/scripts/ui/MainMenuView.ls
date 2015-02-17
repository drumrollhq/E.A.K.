require! {
  'user'
}

module.exports = class MainMenuView extends Backbone.View
  events:
    'click .new-game': \newGame

  initialize: ({app}) ->
    @app = app

    @$resume-button = @$ \button.resume
    @$resume-button-caption = @$resume-button.find \.caption
    @$load-button = @$ \.load-game

    @listen-to @collection, 'change add remove', @render
    @render!

  render: ->
    console.log \render @collection.length
    switch
    | @collection.length is 0 => @render-no-saves!
    | @collection.length is 1 => @render-one-save!
    | otherwise => @render-all-saves!

  render-no-saves: ->
    @hide-resume!
    @hide-load!

  render-one-save: ->
    @show-resume @collection.latest!
    @hide-load!

  render-all-saves: ->
    @show-resume @collection.latest!
    @show-load!

  hide-resume: ->
    @$resume-button.add-class \hidden

  show-resume: (save-game) ->
    @$resume-button.remove-class \hidden
    @$resume-button-caption.text save-game.display-name!

  hide-load: ->
    @$load-button.add-class \hidden

  show-load: ->
    @$load-button.remove-class \hidden

  new-game: ->
    @$el.hide-dialogue!
    @app.show-loader!

    user.new-game start: <[cutscene intro]>
      .then (game) ~>
        console.log 'done' game.to-json!
        # @app.load 'cutscene' 'intro'
      .catch (err) ~>
        @app.error "Error starting new game: #{error-message err}"
