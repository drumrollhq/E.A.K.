require! {
  'user/game-store'
}

format-date = (date) ->
  moment date .format 'MMM Do, h:mm'

module.exports = class SaveGame extends Backbone.Model
  updated: ->
    new Date @get 'updatedAt'

  display-name: ->
    @get 'name' or format-date @updated!

  delete: ->
    game-store!.delete @id

  patch: (attrs) ->
    @set attrs
    game-store!.patch @id, attrs
