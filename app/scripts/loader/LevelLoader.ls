require! 'game/mediator'

module.exports = class LevelLoader extends Backbone.Model
  defaults: do
    stage: ''
    progress: null

  initialize: ->
    @ <<< asset-queue: [], loading-assets: false

  load: ->
    @set \stage, 'Fetching levels'

    do
      data <~ $.get (@get \url), _
      @set \stage, ''
      @set data.{base, levels}
      mediator.LevelStore = data.levels
      @trigger \load:done

    .fail ~> @set \stage, 'Failed to load levels.'
