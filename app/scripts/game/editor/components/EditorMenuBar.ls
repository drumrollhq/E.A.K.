dom = React.DOM

module.exports = React.create-class {
  display-name: \EditorMenuBar

  render: ->
    dom.header class-name: \topbar,
      dom.div class-name: \right,
        dom.button class-name: \save, on-click: @props.on-save, 'Save'
        dom.button class-name: \reset, on-click: @props.on-reset, 'Reset'
        dom.button class-name: \cancel, on-click: @props.on-cancel, 'Cancel'

      dom.button class-name: \undo, on-click: @props.on-undo, 'Undo'
      dom.button class-name: \redo, on-click: @props.on-redo, 'Redo'
      dom.button class-name: \help, on-click: @props.on-help,
        dom.span class-name: 'fa fa-lightbulb-o'
}
