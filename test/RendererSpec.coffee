describe "game/renderer", ->
  expect = chai.expect

  mediator = require "game/mediator"
  Renderer = require "game/renderer"

  sampleHTML = "<h1>Yo!</h1>"
  sampleCSS = "h1 { background: red; }"

  afterEach ->
    ($ ".level").remove()
    ($ "head style").remove()

  it "should add a style tag to the head", ->
    styleCount = (($ document.head).find "style").length

    r = new Renderer html: sampleHTML, css: sampleCSS

    expect((($ document.head).find "style").length).to.equal styleCount + 1

  it "should add the correct div to the body", ->
    divCount = (($ document.body).find "div").length
    levelCount = ($ ".level").length

    r = new Renderer html: sampleHTML, css: sampleCSS

    expect((($ document.body).find "div").length).to.equal divCount + 1

    expect(($ ".level").length).to.equal levelCount + 1

  it "should add a unique ID to the element", (done) ->
    r = new Renderer html: sampleHTML, css: sampleCSS

    id1 = ($ ".level")[0].id

    # unique id may be time based
    setTimeout ->
      ($ ".level").remove()
      new Renderer html: sampleHTML, css: sampleCSS
      id2 = ($ ".level")[0].id
      expect(id1).not.to.equal id2
      done()
    , 100

  it "should scope CSS appropriately", ->
    h1 = $ "<h1></h1>"
    h1.text "sample"

    r = new Renderer html: sampleHTML, css: sampleCSS

    otherH1 = r.$el.find "h1"

    expect(otherH1.css "backgroundColor").not.to.equal h1.css "backgroundColor"

  describe "#remove()", ->
    it "should remove the style element", (done) ->
      r = new Renderer html: sampleHTML, css: sampleCSS

      styleCount = (($ document.head).find "style").length

      r.remove ->
        expect((($ document.head).find "style").length).to.equal styleCount - 1
        done()

    it "should remove the HTML element", (done) ->
      r = new Renderer html: sampleHTML, css: sampleCSS

      divCount = (($ document.body).find "div").length
      levelCount = ($ ".level").length

      r.remove ->
        expect((($ document.body).find "div").length).to.equal divCount - 1
        expect(($ ".level").length).to.equal levelCount - 1
        done()
