module.exports = class Tutorial extends Backbone.DeepModel
  create-step: (id) ->
    if @get "steps.#{id}" then return
    step = {}
    @set "steps.#id", step
