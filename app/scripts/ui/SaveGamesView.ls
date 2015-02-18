require! {
  'ui/save-games': template
}

module.exports = class SaveGamesView extends Backbone.View
  events:
    'click .savegame-actions-delete': \delete
    'keyup .savegame-info-name input': \nameChange
    'change .savegame-info-name input': \nameChange

  initialize: ->
    # @listen-to @collection, \change, @render
    @_delayed = {}
    @listen-to @collection, \all, -> console.log.apply console, ['collection event:'].concat arguments
    @listen-to @collection, \remove @remove
    @$cont = @$ \.games
    @render!

  delayed: (fn, ns) ->
    ns = "#{fn}::#{ns}"
    if @_delayed[ns] then return that
    fn = @[fn].bind this
    delayed = _.debounce fn, 1500ms
    @_delayed[ns] = delayed

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

  name-change: (e) ->
    $el = $ e.target
    game = $el.data \game
    (@delayed \_nameChange, game) $el, game

  _name-change: ($el, game) ->
    @update-name game, $el.val!.trim!

  update-name: (game, name) ~>
    game = @collection.get game
    if name is game.get \name then return
    console.log 'update-name' {game, name}
    $el = @game-el game
    $el.remove-class \saved .add-class \saving

    game.patch {name}
      .catch (e) ->
        # TODO: don't use alert
        alert error-message e
      .finally ->
        $el.remove-class \saving .add-class \saved
