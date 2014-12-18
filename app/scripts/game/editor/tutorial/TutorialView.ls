require! 'game/editor/tutorial/template'

module.exports = class TutorialView extends Backbone.View
  initialize: ({@tutorial}) ->
    @render!
    @media = @tutorial.media
    @listen-to @media, 'playing', @on-play
    @listen-to @media, 'pause', @on-pause
    @listen-to @media, 'ended', @on-pause
    @listen-to @media, 'timeupdate', @update-progress

  events:
    'click .controls .play-pause': 'playPause'
    'click .controls .step': 'playStep'
    'click .controls .next': 'playNext'
    'click .controls .prev': 'playPrev'

  render: ->
    @{tutorial} |> template |> @$el.html
    @els = {
      playpause-icon: @$ '.controls .play-pause .fa'
      next: @$ '.controls .next'
      prev: @$ '.controls .prev'
      steps: @$ '.controls .step'
    }

    for step, i in @tutorial.steps
      @els["step-#{i}"] = st = @$ ".controls [data-step=#i]"
      @els["step-#{i}-progress"] = st.find '.progress'

  remove: ->
    @$el.empty!
    @stop-listening!
    @undelegate-events!

  update-progress: ~>
    time = @media.current-time!
    [complete, incomplete] = @tutorial.steps |> partition ( .end <= time )
    active-index = complete.length
    active = first incomplete

    if active? then @update-step-progress active-index, (time - active.start) / active.duration

    if active-index isnt @active-index
      @els.steps.remove-class 'active'
      if @tutorial.steps[active-index]? then @els["step-#{active-index}"].add-class 'active'

      for _, step in complete => @update-step-progress step, 1
      if tail incomplete then for _, step in that => @update-step-progress step + complete.length + 1, 0

      if complete.length is 0 then @disable 'prev' true else @disable 'prev' false
      if incomplete.length is 1 then @disable 'next' true else @disable 'next' false
      if incomplete.length is 0
        @disable 'prev' true
        @disable 'next' true

    @active-index = active-index

  update-step-progress: (i, progress) ~> @els["step-#{i}-progress"].css 'width', "#{progress * 100}%"

  disable: (el, disable) ~>
    | typeof el is 'string' => @disable @els[el], disable
    | otherwise => el.attr 'disabled' disable

  play-pause: ~> @tutorial.play-pause!

  play-step: (e) ~>
    $el = $ e.current-target
    step = parse-int $el.attr 'data-step'
    @tutorial.play-step step

  play-next: ~>
    if @active-index < @tutorial.steps.length - 1 then @tutorial.play-step @active-index + 1

  play-prev: ~>
    if @active-index > 0 then @tutorial.play-step @active-index - 1

  on-play: ~>
    @els.playpause-icon.remove-class 'fa-play' .add-class 'fa-pause'

  on-pause: ~>
    @els.playpause-icon.remove-class 'fa-pause' .add-class 'fa-play'

  set-step-allowed: (step, allowed) ~>
    el = @els["step-#{step}"]
    if allowed then el.remove-class 'locked' else el.add-class 'locked'
    @disable el, not allowed
