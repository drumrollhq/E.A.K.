module.exports = class Editor extends Backbone.Model
  initialize: ->
    r = @get 'renderer'
    @set do
      'html': r.current-HTML.trim!
      'css': r.current-CSS
      'startHTML': r.current-HTML.trim!
      'startCSS': r.current-CSS
