dom = React.DOM
{CSSTransitionGroup} = React.addons

SaveGame = React.create-class {
  display-name: \SaveGame
  mixins: [Backbone.React.Component.mixin]

  get-initial-state: -> {
    saving: ''
  }

  component-did-mount: ->
    model = @get-model!
    @save-name = _.debounce @_save-name, 1500ms

  _save-name: ->
    model = @get-model!
    @set-state saving: \saving
    model.patch {name: model.get \name}
      .catch (e) ~>
        console.log e
        # TODO: better error handling
        alert error-message e
      .finally ~>
        @set-state saving: \saved

  delete: ->
    @set-state deleting: true, delete-prompt: false
    @props.on-delete @state.model.id

  play: ->
    @props.on-play @state.model.id

  render: ->
    placeholder = "Auto-save #{@state.model.id}"
    if @state.model.state.current-location then placeholder += " - #{@state.model.state.current-location}"

    dom.li class-name: (cx \savegame, @state.saving, @state.{deleting, delete-prompt}),
      dom.div class-name: \savegame-info,
        dom.div class-name: 'name text-field savegame-info-name',
          dom.input {
            type: \text
            value: @state.model.name or ''
            placeholder: placeholder
            on-change: (e) ~>
              @get-model!.set \name, e.target.value
              @save-name!
          }
          dom.div class-name: 'savegame-status-input savegame-status-saving', 'Saving...'
          dom.div class-name: 'savegame-status-input savegame-status-saved', 'Saved'
        dom.div class-name: \savegame-info-lastplayed,
          "Current Location: #{@state.model.state.current-location or 'Unknown'}"
        dom.div class-name: \savegame-info-started,
          "Last played: #{moment @state.model.updated-at .format 'MMMM Do YYYY, h:mm a'}. Started: #{moment @state.model.created-at .format 'l'}."
      dom.div class-name: \savegame-actions,
        dom.button class-name: 'savegame-actions-play btn', on-click: @play, 'Play'
        dom.button class-name: 'savegame-actions-delete btn', on-click: (~> @set-state delete-prompt: true), 'Delete'
      dom.div class-name: \savegame-status-deleting, 'Deleting...'
      dom.div class-name: \savegame-prompt-delete,
        dom.p null,
          'Are you sure you want to delete this game?'
          dom.br!
          'It\'ll be gone forever. That\'s a long time!'
        dom.button class-name: \btn, on-click: (~> @set-state delete-prompt: false), 'Cancel'
        dom.button class-name: 'btn danger', on-click: @delete, 'Delete'
}

module.exports = React.create-class {
  display-name: \SaveGames
  mixins: [Backbone.React.Component.mixin]
  render: ->
    collection = @get-collection!
    remove = collection.delete.bind collection
    play = @props.app.load-game.bind @props.app
    dom.div class-name: \cont-wide,
      dom.h2 null, 'Saved Games'
      dom.div class-name: \games,
        React.create-element CSSTransitionGroup, component: \ul, transition-name: \savegame,
          @state.collection.map (game) ~>
            React.create-element SaveGame, {
              key: game.id
              model: collection.get game.id
              on-delete: remove
              on-play: play
            }
}
