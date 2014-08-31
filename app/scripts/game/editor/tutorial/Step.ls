require! {
  'game/editor/tutorial/Action'
}

module.exports = class Step
  (@start, $step) ~>
    @duration = parse-float $step.attr 'duration' or throw new Error 'Step must have a duration'
    @end = @start + @duration

    @content = $step.find 'content'
    if @content.length isnt 1 then throw new Error 'Step must have one content element'

    @actions = for el in $step.find 'action' .get! => new Action @start, @end, $ el

  on-start: ~>
    console.log 'Step on start', this

  on-end: ~>
    console.log 'Step on end', this

  add-track-events: (track) ->
    for action in @actions
      track.code action

