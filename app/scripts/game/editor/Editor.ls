beautify = (html) ->
  try
    html_beautify html, {
      indent_size: 2
      indent_char: ' '
      preserve_newlines: false
    }
  catch e
    html

module.exports = class Editor extends Backbone.Model
  initialize: ->
    r = @get 'renderer'

    html = if r.conf.format-code
      beautify r.current-HTML.trim!
    else
      r.current-HTML.trim!

    @set do
      'html': html
      'css': r.current-CSS
      'startHTML': html
      'startCSS': r.current-CSS
    @on \all console.log.bind console, 'Editor'

  reset: ->
    @set \html, @get \startHTML
    @set \css, @get \startCSS
    @trigger \reset
