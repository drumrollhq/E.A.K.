require! {
  'game/editor/components/EditorMenuBar'
  'game/editor/components/CodeEditor'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \Editor
  mixins: [Backbone.React.Component.mixin]

  on-change: (code) ->
    @props.model.editor.set \html, code

  on-reset: ->
    @props.model.editor.set \html, @props.model.get \startHTML

  on-undo: ->
    @refs.editor.undo!

  on-redo: ->
    @refs.editor.redo!

  on-save: ->
    @props.on-save!

  on-cancel: ->
    @on-reset!
    @on-save!

  on-help: ->
    @props.on-help!

  render: ->
    dom.div class-name: \editor,
      React.create-element EditorMenuBar, @{on-save, on-reset, on-cancel, on-undo, on-redo, on-help}
      React.create-element CodeEditor,
        ref: \editor
        code: @state.editor.html
        render-el: @props.render-el
        on-change: @on-change
        keys: Esc: @on-save
}
