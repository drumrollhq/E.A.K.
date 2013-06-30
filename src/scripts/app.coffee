module.exports = class App extends Backbone.View
  initialize: ->
    @$menu = @$ ".menu"
    @$about = @$ ".about"

  events:
    "click .menu li": "clickHandler"
    "click .about a.back": "closeAbout"

  render: ->
    @$menu.showDialogue()

  clickHandler: (e) =>
    el = $ e.target
    type = (e.target.className.match /(new|load|about)/)[0]

    switch type
      when "new"
        console.log "new"

      when "load"
        console.log "load"

      when "about"
        @$menu.hideDialogue()
        setTimeout (=> @$about.showDialogue()), 400

  closeAbout: =>
    @$about.hideDialogue()
    setTimeout (=> @$menu.showDialogue()), 400
