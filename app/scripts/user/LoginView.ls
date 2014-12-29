require! {
  'user/login': template
}

module.exports = class LoginView extends Backbone.View
  class-name: 'user-view-item'
  initialize: ->
    @render!

  render: ->
    @$el.html template!
