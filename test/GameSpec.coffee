describe "game/game", ->
  expect = chai.expect

  mediator = require "game/mediator"
  Game = require "game/game"

  beforeEach ->
    localStorage.clear()

    mediator.LevelStore =
      0:
        css: "",
        html: ""

  describe "#load", ->
    it "should have no affect if localStorage is empty", ->
      game = new Game false

      attrs = _.clone game.attributes

      localStorage.clear()

      game.load()

      expect(attrs).to.deep.equal game.attributes

    it "should set localStorage data on the model", ->
      game = new Game false

      game.set "something", "value"

      localStorage.setItem Game::savefile, '{"something":"othervalue"}'

      game.load()

      expect(game.get "something").to.equal "othervalue"

  describe "#save", ->
    it "should store attributes in local storage", ->
      game = new Game false
      target = {something: "some value"}
      game.attributes = target

      localStorage.clear()

      game.save()

      attrs = JSON.parse localStorage.getItem Game::savefile

      expect(attrs).to.deep.equal target

    it "should save data on set", ->
      game = new Game false

      localStorage.clear()

      game.set "numberOfKittens", "ALL"

      saved = JSON.parse localStorage.getItem Game::savefile

      expect(saved).to.contain.key "numberOfKittens"
      expect(saved.numberOfKittens).to.equal "ALL"