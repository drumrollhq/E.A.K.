module.exports = class ReactView extends Backbone.View
  initialize: ({component, model}) ->
    React.render (React.create-element component, {model}), @el
