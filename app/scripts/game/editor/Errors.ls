mustache-settings = {
  escape: /\{\{(.+?)\}\}/g
  evaluate: /\[%(.+?)%\]/g
}

module.exports = class Errors
  (@base-path) ->
    @$templates = $!

  load: (names, cb) ->
    reqs = names.map (name) ~> $.get "#{@base-path}errors.#{name}.html"
    $.when.apply($, reqs).then ~>
      reqs.for-each (req) ~>
        div = $ '<div></div>' .html req.responseText
        @$templates .= add($ '<div></div>' .html req.responseText .find '.error-msg')
      cb!
    , -> cb 'ERROR: at least one template failed to load'

  fill-error: (el, err) ->
    selector = ".error-msg.#{err.type}"
    template = @$templates.filter selector
    if template.length is 0 then throw new Error "template not found for #{err.type}"
    el.html _.template(template.html!, mustache-settings)(err) .show!

  get-error: (err) -> @fill-error ($ '<div></div>'), err

