dom = React.DOM

module.exports = error-panel-list = (header, errors = []) ->
  dom.div class-name: (cx \error-panel hidden: empty errors),
    header,
    dom.ul class-name: \list,
      for error, i in errors
        dom.li key: i, error
