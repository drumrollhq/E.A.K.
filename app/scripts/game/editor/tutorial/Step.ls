require! {
  'game/editor/tutorial/Action'
}

id-counter = 0

# TODO: Find a less horrid way of doing this:
get-allowed-fn = (cond) -> new Function 'code', '$', 'return ' + cond

module.exports = class Step
  (@start, $step) ~>
    @duration = parse-float $step.attr 'duration' or throw new Error 'Step must have a duration'
    @end = @start + @duration

    @content = $step.find 'content'
    if @content.length isnt 1 then throw new Error 'Step must have one content element'

    condition = $step.attr 'condition'
    @allowed = if condition then get-allowed-fn condition else -> true
    @locked = false

    @actions = for el in $step.find 'action' .get! => new Action @start, @end, $ el

  set-view: (view, editor) ->
    @view = view
    @content-container = view.$ '.content-container > .content'
    @editor = editor
    for action in @actions => action.set-view view, editor

  set-allowed: (allowed) ~>
    @locked = not allowed
    if @_waiting and allowed
      @track.play!
      @on-start!

  on-start: ~>
    if @locked
      @track.pause!
      @_waiting = true
    else
      @content-container.html @content.html!

  on-end: ~>
    @_waiting = false

  content-enter: ({content-id}) ~>
    @content-container.find "[data-content-id=#content-id]" .add-class 'active'

  content-exit: ({content-id}) ~>
    @content-container.find "[data-content-id=#content-id]" .remove-class 'active'

  add-track-events: (track, view) ->
    @track = track

    for action in @actions
      track.code action

    @content.find '[in],[out]' .each (i, el) ~>
      $el = $ el
      id = id-counter++
      $el.attr 'data-content-id', id

      in-time = if $el.attr 'in'
        parse-float that or throw new Error "Can't parse content.in: #that"
      else 0

      out-time = if $el.attr 'out'
        o = parse-float that or throw new Error "Can't parse content.out: #that"
        if o > @duration then throw new Error "content.out (#o) cannot be greater than step.duration (#{@duration})"
        o
      else @duration

      track.code {
        start: @start + in-time
        end: @end + out-time
        on-start: @content-enter
        on-end: @content-exit
        content-id: id
      }
