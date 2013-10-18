module.exports = class Editor extends Backbone.Model
  initialize: ->
    r = @get 'renderer'
    @set do
      'html': r.current-HTML
      'css': r.current-CSS
      'startHTML': r.current-HTML
      'startCSS': r.current-CSS
