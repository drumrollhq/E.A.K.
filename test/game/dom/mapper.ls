require! {
  'game/dom/Mapper'
}

describe 'game/dom/Mapper' ->
  el = null
  document.body.style.font-size = '20px'

  before-each ->
    el := document.create-element 'div'
    el.style <<< {position: 'absolute', top: 0, left: 0}
    document.body.append-child el
    el.inner-HTML = 'content'

  after-each ->
    document.body.remove-child el

  specify 'should take a dom element to measure' ->
    mapper = new Mapper el
    expect mapper.el .to.exist!
    expect mapper.el .to.equal el

  describe '#normalise-style' ->
    get-style = ->
      style = window.get-computed-style el
      m = new Mapper el
      m.normalise-style style

    specify 'should normalise border radius' ->
      el.style <<< {width: '500px', height: '500px'}
      expect get-style!.border-radius .to.equal '0px 0px 0px 0px / 0px 0px 0px 0px'

      el.style.border-top-left-radius = '30px'
      expect get-style!.border-radius .to.equal '30px 0px 0px 0px / 30px 0px 0px 0px'

      el.style.border-bottom-right-radius = '1.5em'
      expect get-style!.border-radius .to.equal '30px 0px 30px 0px / 30px 0px 30px 0px'

      el.style.border-bottom-left-radius = '10px 20px'
      expect get-style!.border-radius .to.equal '30px 0px 30px 10px / 30px 0px 30px 20px'

  describe '#build' ->
    specify 'should build a map' ->
      mapper = new Mapper el
      mapper.build!
      expect mapper.map .to.exist!
      expect mapper.map .to.be.an 'array'

    specify 'should find the width and height of rects' ->
      el.inner-HTML = '''
        <div style="position: absolute; top: 30px; left: 200px; width: 100px; height: 40px;">
          Boop!
        </div>
      '''

      mapper = new Mapper el
        ..build!

      expect mapper.map .to.deep.equal [
        type: \rect
        x: 250px, y: 50px
        width: 100px, height: 40px
        rotation: 0
        el: el.children.0, data: {}
        aabb: {top: 30px, bottom: 70px, left: 200px, right: 300px}
      ]

    specify 'should find perfect circles' ->
      el.innerHTML = '''
        <div style="position: absolute; left: 400px; top: 500px; width: 200px; height: 200px; border-radius: 100%">
          Blargh
        </div>
      '''

      mapper = new Mapper el
        ..build!

      expect mapper.map .to.deep.equal [
        type: \circle
        x: 500px, y: 600px
        radius: 100px, rotation: 0
        el: el.children.0, data: {}
        aabb: {top: 500px, left: 400px, bottom: 700px, right: 600px}
      ]
