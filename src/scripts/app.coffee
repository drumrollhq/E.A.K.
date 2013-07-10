AnimationWrapper = require "animation/wrapper"
Game = require "game/game"

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
        # $intro = @$ ".intro"
        # anim = new AnimationWrapper el: $intro
        # @$menu.switchDialogue $intro
        # anim.on "done", =>
        @playGame false

        # anim.start()

      when "load"
        @$menu.hideDialogue()
        @playGame true

      when "about"
        @$menu.switchDialogue @$about

  closeAbout: =>
    @$about.switchDialogue @$menu

  playGame: (load) =>
    @$menu.hideDialogue()
    new Game load
