module.exports = class Action
  (@parent-start, @parent-end, $action) ->
    if $action.attr 'at'
      @at = parse-float that
      if is-NaN @at then throw new Error 'Cannot parse action.at'
    else @at = 0

    @start = @parent-start + @at

    if $action.attr 'duration'
      @duration = parse-float that
      if is-NaN @duration then throw new Error 'Cannot parse action.duration'
    else @duration = @parent-end - @start

    @end = @start + @duration

  on-start: ~>

  on-end: ~>

