dom = React.DOM

module.exports = error-panel = (error) ->
  dom.div class-name: (cx \error-panel hidden: not error),
    dom.strong class-name: \error-panel-label, 'Error: '
    dom.span class-name: \error-panel-content, error
