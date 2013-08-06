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

  it "should add the correct div to the root tag", ->
    root = $ "<div></div>"

    r = new Renderer html: sampleHTML, css: sampleCSS, root: root

    expect(root.children().length).to.equal 1

  it "should add a unique ID to the element", ->
    r = new Renderer html: sampleHTML, css: sampleCSS
    id1 = r.el.id
    r.remove()

    r = new Renderer html: sampleHTML, css: sampleCSS
    id2 = r.el.id
    expect(id1).not.to.equal id2

  it "should scope CSS appropriately", ->
    h1 = $ "<h1></h1>"
    h1.text "sample"

    root = $ "<div></div>"
    root.appendTo document.body

    r = new Renderer html: sampleHTML, css: sampleCSS, root: root

    otherH1 = r.$el.find "h1"

    expect(otherH1.css "backgroundColor").not.to.equal h1.css "backgroundColor"
    root.remove()

  describe "#remove()", ->
    it "should remove the style element", (done) ->
      r = new Renderer html: sampleHTML, css: sampleCSS

      styleCount = (($ document.head).find "style").length

      r.remove ->
        expect((($ document.head).find "style").length).to.equal styleCount - 1
        done()

    it "should remove the HTML element", (done) ->
      root = $ "<div></div>"

      r = new Renderer html: sampleHTML, css: sampleCSS, root: root

      c = root.children().length

      r.remove ->
        expect(root.children().length).to.equal c - 1
        done()

  describe "#map", ->
    it "should map relative to the center of the element", ->
      html = "<div></div>"
      css = "div{width: 400px; height: 100px; background: lime;}"

      root = $ "<div></div>"
      root.appendTo document.body

      r = new Renderer html: html, css: css, root: root

      r.$el.css "position", "absolute"

      m = r.createMap()

      expect(m).to.deep.equal [
        type: 'rect'
        x: 200
        y: 50
        width: 400
        height: 100
        el: r.el.children[0]
        data: {}
      ]

      root.remove()
