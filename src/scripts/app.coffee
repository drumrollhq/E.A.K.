#Game = require "game/wrapper"

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
        #new Game el: @$ ".game"
        @$menu.hideDialogue()

      when "load"
        console.log "load"

      when "about"
        @$menu.switchDialogue @$about

  closeAbout: =>
    @$about.switchDialogue @$menu
