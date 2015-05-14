require! {
  'ui/templates/pay': template
}

module.exports = class PayView extends Backbone.View
  initialize: ->
    @render!

  render: ->
    @$el.html template!

  args: (type) ->
    console.log \args type
