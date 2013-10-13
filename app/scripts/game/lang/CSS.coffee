walk = (css, type, fn) ->
  for rule in css.rules
    if rule.type is type
      fn rule
    else if rule.rules isnt undefined
      walk rule, type, fn

module.exports = class CSS
  constructor: (css) ->
    @source = css
    @css = rework css
    @clean = rework css

  scope: (scope) =>
    @css.use (css) ->
      walk css, "rule", (rule) ->
        rule.selectors = rule.selectors.map (selector) -> "#{scope} #{selector}"

  toCleanString: (comp = false) =>
    @clean.toString compress: comp

  toString: (comp = false) =>
    @css.toString compress: comp
