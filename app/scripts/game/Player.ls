require! {
  'game/mediator'
}

{reduce} = _

module.exports = class Player extends Backbone.View
  tag-name: \div
  class-name: 'player entity'

  initialize: (start = {x: 0, y: 0, colour: 'white'}, w, h) ->
    @el.width = @el.height = 40

    @$el.add-class "player-colour-#{start.colour}"

    @$inner-el = $ '<div></div>'
      ..add-class 'player-inner'
      ..append-to @$el

    @$el.attr \data-ignore true

    @$el.css do
      position: \absolute
      left: start.x + w/2 - 20
      top: start.y + h/2 - 20

    @last-classes = []
    @classes-disabled = false

    console.log start
    # Data for physics engine:
    @ <<< {
      type: 'rect'
      x: start.x + w/2
      y: start.y + h/2
      width: 40
      height: 40
      rotation: 0
      data:
        player: true
    }

  apply-classes: (classes) ~>
    for classname in @last-classes
      if classname not in classes then @$el.remove-class "player-#classname"

    for classname in classes
      if classname not in @last-classes then @$el.add-class "player-#classname"

    @last-classes := classes
