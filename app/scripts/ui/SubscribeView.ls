require! {
  'ui/actions'
  'ui/templates/subscribe': template
}

module.exports = class SubscribeView extends Backbone.View
  initialize: ->
    @render!

  render: ->
    @$el.html template!

  events:
    'click [data-sub-choice]': \selectOption

  select-option: (e) ->
    $el = $ e.current-target
    @select $el.attr \data-sub-choice

  select: (choice) ->
    if choice is \teachers
      alert 'TODO, yo!'
      return

    actions.get-user prevent-close: true
      .then ~>
        console.log 'changehash'
        window.location.hash = "/app/pay/#choice"
      .catch ->
        console.log \error-get-user arguments
