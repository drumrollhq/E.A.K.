module.exports = class ReactView extends Backbone.View
  initialize: ({component, model, collection, app}) ->
    props = {
      model
      collection
      app
      on-close: ~> @trigger \close
    }

    @component = React.render (React.create-element component, props), @el

  args: (...args) ->
    if @component.args then @component.args.apply @component, args
