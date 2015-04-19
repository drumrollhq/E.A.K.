module.exports = class TemplateView extends Backbone.View
  initialize: ({template}) ->
    @template = require template
    @render!

  render: ->
    @$el.html @template!
