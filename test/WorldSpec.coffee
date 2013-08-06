describe "game/physics/world", ->
  expect = chai.expect

  el = {}

  World = require "game/physics/world"

  beforeEach ->
    el = ($ "<div></div>").css width: 400, height: 300, position: "absolute", top: 30, left: 30
    el.appendTo document.body

  afterEach ->
    #($ "canvas").remove()
    #el.remove()

  it "should create a Box2d world", ->
    world = new World el

    expect(world.world).to.be.defined
    expect(world.world instanceof Box2D.Dynamics.b2World).to.be.true

  describe "#resize()", ->
    it "should position the canvas over the level element", ->
      world = new World el

      world.$el.appendTo document.body

      world.el.style.display = "block"

      world.resize()

      expect(world.el.getBoundingClientRect()).to.deep.equal el[0].getBoundingClientRect()