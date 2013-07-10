describe "game/mediator", ->
  expect = chai.expect

  mediator = require "game/mediator"

  $window = $ window

  keyevent = (code, type="press") -> jQuery.Event "key#{type}", which: code, keyCode: code

  describe "on key events", ->

    it "should fire events for keydown, keyup and keypress", ->
      spydown = sinon.spy()
      spyup = sinon.spy()
      spypress = sinon.spy()

      mediator.on "keydown", spydown
      $window.trigger keyevent 13, "down"

      mediator.on "keyup", spyup
      $window.trigger keyevent 13, "up"

      mediator.on "keypress", spypress
      $window.trigger keyevent 13, "press"

      expect(spydown).to.have.been.calledOnce
      expect(spyup).to.have.been.calledOnce
      expect(spypress).to.have.been.calledOnce

    it "should fire for specific keys", ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()

      mediator.on "keypress:enter", spy1
      mediator.on "keypress:up", spy2

      $window.trigger keyevent 38 # 38 -> up arrow

      expect(spy1).not.to.have.been.called
      expect(spy2).to.have.been.calledOnce

    it "should allow you to specify many specific keys", ->
      spy = sinon.spy()

      mediator.on "keypress:a,b,c", spy

      $window.trigger keyevent 65 # 65 -> a
      $window.trigger keyevent 88 # 88 -> x
      $window.trigger keyevent 66 # 66 -> b
      $window.trigger keyevent 89 # 89 -> y
      $window.trigger keyevent 67 # 67 -> c

      expect(spy).to.have.been.calledThrice