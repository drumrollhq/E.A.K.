require! <[ animation/AnimationWrapper game/Game ]>

module.exports = class KittenQuest extends Backbone.View
  initialize: ~>
    @$menu = @$ \.menu
    @$about = @$ \.about

  events:
    'tap .menu li': \clickHandler
    'tap .about a.back': \closeAbout

  render: ~> @$menu.show-dialogue!

  click-handler: (e) ~>
    e.stop-propagation!
    el = $ e.target
    type = e.target.class-name.match /(new|load|about)/ .0

    switch type
      when \new then @play-game false
      when \load then @play-game true
      when \about then @$menu.switch-dialogue @$about

  close-about: ~> @$about.switch-dialogue @$menu

  play-game: (load) ~>
    game = new Game load
    game.start-level game.get \level
