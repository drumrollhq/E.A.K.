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
    @comm-cub = channels.game-commands.subscribe @game-commands

    @block-if-paused <[save cancel undo redo reset help handle-change remove on-change]>
    set-timeout (~> @on-change @model, @model.get 'html'), 0

  events:
    'click .save': \save
    'click .cancel': \cancel
    'click .undo': \undo
    'click .redo': \redo
    'click .reset': \reset
    'click .help': \help

  handle-change: (cm) ~> @model.set \html cm.get-value!

  render: -> $ document.body .add-class \editor

  remove: ~>
    $ document.body .remove-class \editor
    @stop-listening!
    @esc-sub.unsubscribe!
    @cm.off \change @handle-change
    $ @cm.get-wrapper-element! .remove!

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
