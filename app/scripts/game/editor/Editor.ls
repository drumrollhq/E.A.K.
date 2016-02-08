beautify = (html) ->
  html_beautify html, {
    indent_size: 2
    indent_char: ' '
    preserve_newlines: false
  }

module.exports = class Editor extends Backbone.Model
  initialize: ->
    r = @get 'renderer'
    html = beautify r.current-HTML.trim!
    @set do
      'html': html
      'css': r.current-CSS
      'startHTML': html
      'startCSS': r.current-CSS

  reset: ->
    @set \html, @get \startHTML
    @set \css, @get \startCSS
    @trigger \reset
