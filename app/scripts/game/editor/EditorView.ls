require! {
  'game/area/el-modify'
  'game/editor/CodeMirrorExtras'
  'game/editor/NiceComments'
  'lib/channels'
  'translations'
}

module.exports = class EditorView extends Backbone.View
  initialize: (options) ->
    html = @model.get \html

    @render-el = options.render-el if options.render-el?
    @renderer = @model.get \renderer

    @entities = @render-el.children \.entity

    cm = CodeMirror (@$ '.editor-html' .0),
      value: html
      mode: \htmlmixed
      theme: 'solarized light'
      tabsize: 2
      line-wrapping: true
      line-numbers: true
      extra-keys:
        Esc: @save

    cm.on \change _.throttle @handle-change, 250

    @ <<< {cm}
    @has-errors = false

    @listen-to @model, \change:html @on-change

    @extras = CodeMirrorExtras cm
    NiceComments cm, not @renderer.conf.glitch
    @extras.clear-cursor-marks!

    @esc-sub = channels.parse 'key-press: esc' .subscribe @save
    @comm-sub = channels.game-commands.subscribe @game-commands

    @block-if-paused <[save cancel undo redo reset help handle-change remove on-change]>
    set-timeout (~> @on-change @model, @model.get 'html'), 0
    @setup-events!

  events:
    'click .save': \save
    'click .cancel': \cancel
    'click .undo': \undo
    'click .redo': \redo
    'click .reset': \reset
    'click .help': \help

  handle-change: (cm) ~> @model.set \html cm.get-value!

  render: ->
    $ document.body .add-class \editor
    @on-change _, @cm.get-value!

  remove: ~>
    $ document.body .remove-class \editor
    @stop-listening!
    @esc-sub.unsubscribe!
    @cm.off \change @handle-change
    $ @cm.get-wrapper-element! .remove!

  setup-events: ~>
    timeout = 3_000ms
    @listen-to @cm, \change, _.debounce (~> @trigger \start-typing), timeout, leading: true, trailing: false
    @listen-to @cm, \change, _.debounce (~> @trigger \stop-typing), timeout, leading: false, trailing: true

  on-change: (m, html) ~>
    # preserve entities
    @entities.detach!
    e = @render-el

    parsed = @extras.process html
    @has-errors = parsed.error isnt null

    e.empty!
    e.append parsed.document

    e.find 'style' .each (i, style) ~>
      $style = $ style
      $style |> ( .text! ) |> @renderer.preprocess-css |> $style.text

    @entities.append-to e

    @renderer.set-error parsed.error
    el-modify e

  restore-entities: ~>
    @render-el.children \.entity .detach!
    @entities.append-to @render-el

  cancel: ~>
    @model.set \html @model.get \startHTML
    @model.trigger \save

  reset: ~>
    html = @model.get \originalHTML
    @model.set \html html
    @cm.set-value html
    NiceComments @cm

  save: ~>
    if @has-errors
      channels.alert.publish msg: translations.errors.code-errors
      return

    @model.trigger \save

  undo: ~> @cm.undo!

  redo: ~> @cm.redo!

  help: ~>
    @trigger 'show-extra'
    channels.game-commands.publish command: 'help'

  block-if-paused: (fns) ~>
    block = (fn, ths) -> ->
      if ths.paused then return
      fn.apply this, arguments

    for name in fns
      fn = this[name]
      this[name] = block fn, this

  game-commands: ({command}) ~>
    | command is 'force-pause' => @paused = true
    | command is 'force-resume' => @paused = false

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
