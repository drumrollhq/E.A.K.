require! {
  'lib/dom/Mapper'
}

describe 'lib/dom/Mapper' ->
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

      delete mapper.map.0.bounds

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

      delete mapper.map.0.bounds

      expect mapper.map .to.deep.equal [
        type: \circle
        x: 500px, y: 600px
        radius: 100px, rotation: 0
        el: el.children.0, data: {}
        aabb: {top: 500px, left: 400px, bottom: 700px, right: 600px}
      ]

    specify 'should find pills [horizontal]' ->
      el.inner-HTML = '''
        <div style="position: absolute; left: 200px; top: 100px; width: 300px; height: 50px; border-radius: 25px;">
          Horizontal Pill
        </div>
      '''

      mapper = new Mapper el
        ..build!

      delete mapper.map.0.bounds

      expect mapper.map .to.deep.equal [
        type: \compound
        x: 350px, y: 125px
        el: el.children.0, data: {}
        rotation: 0
        aabb: {top: 100px, left: 200px, bottom: 150px, right: 500px}
        shapes:
          * type: \rect
            x: 0, y: 0
            width: 250px, height: 50px
          * type: \circle
            x: -125px, y: 0
            radius: 25px
          * type: \circle
            x: 125px, y: 0
            radius: 25px
      ]

    specify 'should find pills [vertical]' ->
      el.inner-HTML = '''
        <div style="position: absolute; left: 200px; top: 100px; width: 50px; height: 300px; border-radius: 25px;">
          Vertical Pill
        </div>
      '''

      mapper = new Mapper el
        ..build!

      delete mapper.map.0.bounds

      expect mapper.map .to.deep.equal [
        type: \compound
        x: 225px, y: 250px
        el: el.children.0, data: {}
        rotation: 0
        aabb: {top: 100px, left: 200px, bottom: 400px, right: 250px}
        shapes:
          * type: \rect
            x: 0, y: 0
            width: 50px, height: 250px
          * type: \circle
            x: 0, y: -125px
            radius: 25px
          * type: \circle
            x: 0, y: 125px
            radius: 25px
      ]

    specify 'should find uniform rounded rects' ->
      el.inner-HTML = '''
        <div style="position: absolute; top: 100px; left: 200px; width: 300px; height: 400px; border-radius: 20px">
          Rounded Rect
        </div>
      '''

      mapper = new Mapper el
        ..build!

      delete mapper.map.0.bounds

      expect mapper.map .to.deep.equal [
        type: \compound
        x: 350px, y: 300px
        el: el.children.0, data: {}
        rotation: 0
        aabb: {top: 100px, left: 200px, bottom: 500px, right: 500px}
        shapes:
          * type: \rect
            x: 0, y: 0
            width: 300px, height: 360px
          * type: \rect
            x: 0, y: 0
            width: 260px, height: 400px
          * type: \circle
            x: 130px, y: 180px
            radius: 20px
          * type: \circle
            x: -130px, y: 180px
            radius: 20px
          * type: \circle
            x: -130px, y: -180px
            radius: 20px
          * type: \circle
            x: 130px, y: -180px
            radius: 20px
      ]

    specify 'should store values from data- attributes' ->
      el.inner-HTML = '''
        <div style="position: absolute; top: 100px; left: 100px; width: 100px; height: 100px;" data-hello="world" data-thing="blah">
          Hello!
        </div>
      '''

      mapper = new Mapper el
        ..build!

      delete mapper.map.0.bounds

      expect mapper.map .to.deep.equal [
        type: \rect
        x: 150px, y: 150px
        width: 100px, height: 100px
        aabb: {top: 100px, left: 100px, right: 200px, bottom: 200px}
        rotation: 0, el: el.children.0
        data:
          hello: 'world'
          thing: 'blah'
      ]

    specify 'should ignore elements with data-ignore' ->
      el.inner-HTML = '''
        <div style="position: absolute; top: 100px; left: 100px; width: 100px; height: 100px;" data-ignore>
          Ignore me
        </div>
        <div style="position: absolute; top: 100px; left: 100px; width: 100px; height: 100px;">
          Hello!
        </div>
      '''

      mapper = new Mapper el
        ..build!

      delete mapper.map.0.bounds

      expect mapper.map .to.deep.equal [
        type: \rect
        x: 150px, y: 150px
        width: 100px, height: 100px
        aabb: {top: 100px, left: 100px, right: 200px, bottom: 200px}
        rotation: 0, el: el.children.1
        data: {}
      ]
