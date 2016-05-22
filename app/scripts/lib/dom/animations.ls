module.exports = {
  get-animations: ->
    animations = {}
    for sheet in document.style-sheets
      for rule in sheet.css-rules
        if rule.type is 7 then animations[rule.name] = rule

    animations
}
