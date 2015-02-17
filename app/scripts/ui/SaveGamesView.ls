require! {
  'ui/save-games': template
}

module.exports = class SaveGamesView extends Backbone.View
  events:
    'click .savegame-actions-delete': \delete

  initialize: ->
    # @listen-to @collection, \change, @render
    @listen-to @collection, \all, -> console.log.apply console, ['collection event:'].concat arguments
    @listen-to @collection, \remove @remove
    @$cont = @$ \.games
    @render!

  render: ->
    console.log @$cont
    {games: @collection.to-json!} |> template |> @$cont.html

  game-el: (game) ->
    id = game.id or game
    @$ ".savegame[data-game=#{id}]"

  delete: (e) ->
    game-id = $ e.target .data \game
    game = @collection.get game-id
    # TODO: don't use confirm and alert
    if confirm "Are you sure you want to delete #{game.display-name!}?"
      @game-el game .add-class \deleting
      @collection.delete game
        .catch (e) ->
          alert "Couldn't delete game: #{error-message e}"

  remove: (game) ->
    $el = @game-el game
      ..one prefixed.animation-end, -> $el.remove!
      ..add-class \removing
