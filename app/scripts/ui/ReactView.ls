module.exports = class ReactView extends Backbone.View
  initialize: ({component, model, collection}) ->
    props = {
      model
      collection
      on-close: ~> @trigger \close
    }

    @component = React.render (React.create-element component, props), @el

  args: (...args) ->
    if @component.args then @component.args.apply @component, args
