require! {
  'game/editor/CodeMirrorExtras'
  'game/editor/NiceComments'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \CodeMirrorEditor

  component-did-mount: ->
    @cm = CodeMirror @refs.cm-container,
      value: @props.code
      mode: \htmlmixed
      theme: 'solarized light'
      tabsize: 2
      line-wrapping: true
      extra-keys: @props.keys or {}

    @extras = CodeMirrorExtras @cm
    NiceComments @cm, if @props.beautify? then props.beautify else true
    @extras.clear-cursor-marks!

    @cm.on \change, @on-change

  component-will-receive-props: (next-props) ->
    if next-props.code isnt @cm.get-value!
      @cm.set-value next-props.code

  component-will-unmount: ->
    @cm.off \change, @on-change
    $ @cm.get-wrapper-element! .remove!

  on-change: -> @props.on-change @cm.get-value!

  undo: ->
    @cm.undo!

  redo: ->
    @cm.redo!

  render: ->
    dom.section class-name: \editor-html, ref: \cmContainer, ''
}
