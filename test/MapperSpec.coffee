describe "game/dom/mapper", ->
  Mapper = {}
  el = {}

  expect = chai.expect

  beforeEach ->
    Mapper = require 'game/dom/mapper'

    el = document.createElement 'div'
    document.body.appendChild el

    el.setAttribute 'id', 'el'

    el.innerHTML = "Nothing to see here"

  afterEach ->
    el = document.getElementById 'el'
    document.body.removeChild el

    Mapper = {}
    el = {}

  it "should take a DOM element", ->
    mapper = new Mapper el

    expect(mapper.el).to.exist
    expect(mapper.el).to.equal el

  describe "#normaliseStyle", ->
    getStyle = ->
      style = window.getComputedStyle el
      m = new Mapper el
      m.normaliseStyle style

    it "should normalise border-radius", ->
      el.style.width = "500px"
      el.style.height = "500px"
      style = getStyle()
      expect(style.borderRadius).to.equal "0px 0px 0px 0px / 0px 0px 0px 0px"

      el.style.borderTopLeftRadius = "30px"
      style = getStyle()
      expect(style.borderRadius).to.equal "30px 0px 0px 0px / 30px 0px 0px 0px"

      el.style.borderBottomRightRadius = "1.5em"
      style = getStyle()
      expect(style.borderRadius).to.equal "30px 0px 30px 0px / 30px 0px 30px 0px"

      el.style.borderBottomLeftRadius = "10px 20px"
      style = getStyle()
      expect(style.borderRadius).to.equal "30px 0px 30px 10px / 30px 0px 30px 20px"


  describe "#build", ->

    it "should build a map", ->
      mapper = new Mapper el

      mapper.build()

      expect(mapper.map).to.exist
      expect(mapper.map).to.be.an 'array'


    it "should find width and height of rects", ->
      el.innerHTML = "<div style=\"position:absolute; top: 30px;
        left: 200px; width: 100px; height: 40px; background: red;\">boop</div>"

      mapper = new Mapper el

      mapper.build()

      expect(mapper.map).to.deep.equal [
        type: 'rect'
        x: 250
        y: 50
        width: 100
        height: 40
        el: el.children[0]
        data: {}
      ]

    it "should find perfect circles", ->
      el.innerHTML = "
        <div style=\"position: absolute;
          left: 400px;
          top: 500px;
          width: 200px;
          height: 200px;
          border-radius: 100%;\"></div>
        <div style=\"position: absolute;
          left: 200px;
          top: 100px;
          width: 50px;
          height: 50px;
          border-radius: 25px;\"></div>
        <div style=\"position: absolute;
          left: 300px;
          top: 200px;
          width: 60px;
          height: 60px;
          border-radius: 40px;\"></div>"

      mapper = new Mapper el

      mapper.build()

      expect(mapper.map).to.deep.equal [
        type: 'circle'
        x: 500
        y: 600
        radius: 100
        el: (el.querySelectorAll "div")[0]
        data: {}
      ,
        type: 'circle'
        x: 225
        y: 125
        radius: 25
        el: (el.querySelectorAll "div")[1]
        data: {}
      ,
        type: 'circle'
        x: 330
        y: 230
        radius: 30
        el: (el.querySelectorAll "div")[2]
        data: {}
      ]

    it "should find pills", ->
      el.innerHTML = "
        <div style=\"position: absolute;
          left: 200px;
          top: 100px;
          width: 300px;
          height: 50px;
          border-radius: 25px;\"></div>

        <div style=\"position: absolute;
          left: 200px;
          top: 100px;
          width: 100px;
          height: 200px;
          border-radius: 500px;\"></div>
      "

      mapper = new Mapper el

      mapper.build()

      (expect mapper.map).to.deep.equal [
        type: 'compound'
        x: 350
        y: 125
        el: (el.querySelectorAll "div")[0]
        data: {}
        shapes: [
          type: 'rect'
          x: 0
          y: 0
          width: 250
          height: 50
        ,
          type: 'circle'
          x: -125
          y: 0
          radius: 25
        ,
          type: 'circle'
          x: 125
          y: 0
          radius: 25
        ]
      ,
        type: 'compound'
        x: 250
        y: 200
        el: (el.querySelectorAll "div")[1]
        data: {}
        shapes: [
          type: 'rect'
          x: 0
          y: 0
          width: 100
          height: 100
        ,
          type: 'circle'
          x: 0
          y: -50
          radius: 50
        ,
          type: 'circle'
          x: 0
          y: 50
          radius: 50
        ]
      ]

    it "should find uniform rounded rects", ->
      el.innerHTML = """
        <div style="
          position: absolute;
          top: 200px;
          left: 400px;
          width: 300px;
          height: 200px;
          border-radius: 20px;
        "></div>
      """

      mapper = new Mapper el

      mapper.build()

      console.log mapper.map

      expect(mapper.map).to.deep.equal [
        type: "compound"
        x: 550
        y: 300
        el: el.querySelector "div"
        data: {}
        shapes: [
          type: "rect"
          x: 0
          y: 0
          width: 300
          height: 160
        ,
          type: "rect"
          x: 0
          y: 0
          width: 260
          height: 200
        ,
          type: "circle"
          x: 130
          y: 80
          radius: 20
        ,
          type: "circle"
          x: -130
          y: 80
          radius: 20
        ,
          type: "circle"
          x: -130
          y: -80
          radius: 20
        ,
          type: "circle"
          x: 130
          y: -80
          radius: 20
        ]
      ]

    it "should add values in data-attributes to the map", ->
      el.innerHTML = """
        <p data-thing="value" data-kittens="several"></p>
        <p data-hello="goodbye" data-breakfast="toast"></p>
      """

      mapper = new Mapper el

      mapper.build()

      d1 = mapper.map[0].data
      d2 = mapper.map[1].data

      expect(d1).to.deep.equal thing: "value", kittens: "several"
      expect(d2).to.deep.equal hello: "goodbye", breakfast: "toast"

    it "should ignore some specified elements", ->
      el.innerHTML = """
        <p>Some tag</p>
        <p data-ignore>Other tag</p>
      """

      mapper = new Mapper el

      mapper.build()

      expect(mapper.map).to.have.length 1
