require! {
  'game/area/el-modify'
  'game/editor/components/Editor': EditorComponent
  'lib/channels'
}

module.exports = class EditorView extends Backbone.View
  initialize: (options) ->
    # render-el is the level element that the html will be rendered to
    @render-el = options.render-el
    @area-level = @model.get \renderer
    @tutorial = options.tutorial
    @tutorial.editor-view = this

    # entities are special - we need to keep track of them and stop them from being destroyed
    @entities = @render-el.children \.entity

    # Does the editor currently have errors in its code?
    @has-errors = false

    # Mount the editor React component and show it
    @render!

    # Event listeners for every one!
    @esc-sub = channels.parse 'key-press: esc' .subscribe @save
    @comm-sub = channels.game-commands.subscribe @game-commands
    @listen-to @model, 'change:html', _.throttle @on-change, 250
    @block-if-paused <[save cancel undo redo reset help handle-change remove on-change]>

    typing-timeout = 1_000ms
    @cm.on \change, _.debounce (~> @trigger \start-typing), typing-timeout, leading: true, trailing: false
    @cm.on \change, _.debounce (~> @trigger \stop-typing), typing-timeout, leading: false, trailing: true

    # First render:
    @on-change!

  render: ->
    @component = ReactDOM.render (React.create-element EditorComponent, {
      model:
        editor: @model
        tutorial: @tutorial
      on-save: @save
      on-select-step: @tutorial.play-step.bind @tutorial
      render-el: @render-el.get 0
    }), @el
    $ document.body .add-class \editor

    # Expose codemirror and codemirror extras:
    @cm = @component.refs.editor.cm
    @extras = @component.refs.editor.extras

  remove: ~>
    $ document.body .remove-class \editor
    @stop-listening!
    @esc-sub.unsubscribe!
    ReactDOM.unmount-component-at-node @el

  on-change: ~>
    html = @model.get \html

    # preserve dynamic entities:
    @entities.detach!

    # parse html:
    parsed = @component.refs.editor.extras.process html
    @has-errors = parsed.error isnt null

    # Clear and re-build the level:
    @render-el
      .empty!
      .append parsed.document
      .find 'style' .each (i, style) ~>
        $style = $ style
        $style.text!
          |> @area-level.preprocess-css
          |> $style.text

    @entities.append-to @render-el
    @area-level.set-error parsed.error
    el-modify @render-el

  save: ~>
    if @has-errors
      channels.alert.publish msg: translations.errors.code-errors
      return

    @model.trigger \save

  game-commands: ({command}) ~>
    | command is 'force-pause' => @paused = true
    | command is 'force-resume' => @paused = false

  block-if-paused: (fns) ~>
    block = (fn, ths) -> ->
      if ths.paused then return
      fn.apply this, arguments

    for name in fns
      fn = this[name]
      this[name] = block fn, this

  restore-entities: ~>
    @render-el.children \.entity .detach!
    @entities.append-to @render-el

  select: (selector) ->
    | !selector => [{start: -1, end: @model.get \html .length + 1}]
    | typeof! selector is \RegExp => @select-by-regex selector
    | typeof! selector is \String => @select-by-css-selector selector
    | otherwise => console.error 'Unknown selector:' selector

  select-one: (selector) -> first @select selector

  select-by-css-selector: (selector) ->
    parse-structure-pseudo-selector = (selector) ->
      for pseudo-selector in <[inner outer open close all]>
        re = new RegExp "\\:\\:?#{pseudo-selector}$"
        if selector.match re
          return structure-selector: pseudo-selector, selector: selector.replace re, ''

      return structure-selector: \all, selector: selector

    get-range = (pos, type) ->
      switch type
      | \all => {start: pos.open-tag.start, end: pos.close-tag.end}
      | \open => {start: pos.open-tag.start, end: pos.open-tag.end}
      | \close => {start: pos.close-tag.start, end: pos.close-tag.end}
      | \inner => {start: pos.open-tag.end, end: pos.close-tag.start}
      | \outer => [{start: pos.open-tag.start, end: pos.open-tag.end}, {start: pos.close-tag.start, end: pos.close-tag.end}]

    ranges = selector
      .split ','
      .map ( .trim! )
      .map (original-selector) ~>
        {selector, structure-selector} = parse-structure-pseudo-selector original-selector
        for el in @render-el.find selector when el.parse-info
          get-range el.parse-info, structure-selector

    flatten ranges

  select-by-regex: (re) ->
    code = @model.get \html
    matches = if re.global
      while re.exec code => that
    else [re.exec code]

    matches.map (m) -> {start: m.index, end: m.index + m.0.length}
