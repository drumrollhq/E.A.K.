require! {
  'ui/templates/save-games': template
  'user'
}

module.exports = class SaveGamesView extends Backbone.View
  events:
    'click .savegame-actions-delete': \delete
    'click .savegame-actions-play': \play
    'keyup .savegame-info-name input': \nameChange
    'change .savegame-info-name input': \nameChange

  initialize: ({app}) ->
    @app = app
    # @listen-to @collection, \change, @render
    @_delayed = {}
    @listen-to @collection, \remove @remove
    @render!
    @$cont = @$ \.games

  delayed: (fn, ns) ->
    ns = "#{fn}::#{ns}"
    if @_delayed[ns] then return that
    fn = @[fn].bind this
    delayed = _.debounce fn, 1500ms
    @_delayed[ns] = delayed

  render: ->
    {games: @collection.to-json!} |> template |> @$el.html

  game-el: (game) ->
    id = game.id or game
    @$ ".savegame[data-game=#{id}]"

  play: (e) ->
    game-id = $ e.target .data \game
    @app.load-game game-id

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

  name-change: (e) ->
    $el = $ e.target
    game = $el.data \game
    (@delayed \_nameChange, game) $el, game

  _name-change: ($el, game) ->
    @update-name game, $el.val!.trim!

  update-name: (game, name) ~>
    game = @collection.get game
    if name is game.get \name then return
    $el = @game-el game
    $el.remove-class \saved .add-class \saving

    game.patch {name}
      .catch (e) ->
        # TODO: don't use alert
        alert error-message e
      .finally ->
        $el.remove-class \saving .add-class \saved
