var Mapper;
Mapper = require('game/dom/Mapper');
describe('game/dom/Mapper', function(){
  var el;
  el = null;
  document.body.style.fontSize = '20px';
  beforeEach(function(){
    var ref$;
    el = document.createElement('div');
    ref$ = el.style;
    ref$.position = 'absolute';
    ref$.top = 0;
    ref$.left = 0;
    document.body.appendChild(el);
    return el.innerHTML = 'content';
  });
  afterEach(function(){
    return document.body.removeChild(el);
  });
  specify('should take a dom element to measure', function(){
    var mapper;
    mapper = new Mapper(el);
    expect(mapper.el).to.exist();
    return expect(mapper.el).to.equal(el);
  });
  describe('#normalise-style', function(){
    var getStyle;
    getStyle = function(){
      var style, m;
      style = window.getComputedStyle(el);
      m = new Mapper(el);
      return m.normaliseStyle(style);
    };
    return specify('should normalise border radius', function(){
      var ref$;
      ref$ = el.style;
      ref$.width = '500px';
      ref$.height = '500px';
      expect(getStyle().borderRadius).to.equal('0px 0px 0px 0px / 0px 0px 0px 0px');
      el.style.borderTopLeftRadius = '30px';
      expect(getStyle().borderRadius).to.equal('30px 0px 0px 0px / 30px 0px 0px 0px');
      el.style.borderBottomRightRadius = '1.5em';
      expect(getStyle().borderRadius).to.equal('30px 0px 30px 0px / 30px 0px 30px 0px');
      el.style.borderBottomLeftRadius = '10px 20px';
      return expect(getStyle().borderRadius).to.equal('30px 0px 30px 10px / 30px 0px 30px 20px');
    });
  });
  return describe('#build', function(){
    specify('should build a map', function(){
      var mapper;
      mapper = new Mapper(el);
      mapper.build();
      expect(mapper.map).to.exist();
      return expect(mapper.map).to.be.an('array');
    });
    specify('should find the width and height of rects', function(){
      var x$, mapper;
      el.innerHTML = '<div style="position: absolute; top: 30px; left: 200px; width: 100px; height: 40px;">\n  Boop!\n</div>';
      x$ = mapper = new Mapper(el);
      x$.build();
      return expect(mapper.map).to.deep.equal([{
        type: 'rect',
        x: 250,
        y: 50,
        width: 100,
        height: 40,
        rotation: 0,
        el: el.children[0],
        data: {},
        aabb: {
          top: 30,
          bottom: 70,
          left: 200,
          right: 300
        }
      }]);
    });
    return specify('should find perfect circles', function(){
      var x$, mapper;
      el.innerHTML = '<div style="position: absolute; left: 400px; top: 500px; width: 200px; height: 200px; border-radius: 100%">\n  Blargh\n</div>';
      x$ = mapper = new Mapper(el);
      x$.build();
      return expect(mapper.map).to.deep.equal([{
        type: 'circle',
        x: 500,
        y: 600,
        radius: 100,
        rotation: 0,
        el: el.children[0],
        data: {},
        aabb: {
          top: 500,
          left: 400,
          bottom: 700,
          right: 600
        }
      }]);
    });
  });
});