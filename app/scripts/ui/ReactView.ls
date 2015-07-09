module.exports = class ReactView extends Backbone.View
  initialize: ({component, model}) ->
    props = {
      model
      on-close: ~> @trigger \close
    }

    @component = React.render (React.create-element component, props), @el

  args: (...args) ->
    if @component.args then @component.args.apply @component, args
