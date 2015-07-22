walk = (css, type, fn) ->
  for rule in css.rules
    if rule.type is type
      fn rule
    else if rule.rules?
      walk rule, type, fn


module.exports = class CSS
  (css) ->
    @source = css
    @css = rework css
    @clean = rework css

  scope: (scope) ~>
    @css.use (css) ->
      walk css, 'rule', (rule) ->
        rule.selectors .= map (selector) ->
          | selector.trim! is 'body' => "#scope"
          | selector.match 'body' => selector.replace 'body', scope
          | otherwise => "#scope #selector"

  rewrite-hover: (new-hover) ~>
    @css.use (css) ->
      walk css, 'rule', (rule) ->
        rule.selectors .= map -> it.replace ':hover', new-hover

  rewrite-assets: (rewrite) ~>
    @css.use (css) ->
      walk css, 'rule', (rule) ->
        for declaration in rule.declarations
          declaration.value .= replace /url\(([^)]+)\)/g, (str, url) -> "url(#{rewrite url})"

  to-clean-string: (compress = false) ~>
    @clean.to-string {compress}

  to-string: (compress = false) ~>
    @css.to-string {compress}
