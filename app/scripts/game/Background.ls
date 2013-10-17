require! {
  'game/mediator'
  'WebWorker'
}

module.exports = class Background
  ->
    @$body = $ document.body
    @worker = new WebWorker name: 'Blur'

    mediator.on 'prepareBackground' @prepare-background
    mediator.on 'showBackground' @show-background
    mediator.on 'clearBackground' @clear-background

  prepare-background: (background) ~>
    @current-background = value: '', ready: false
    background = @parse-bg background

    img = new Image

    img.addEventListener \load, ~>

      console.log "Image loaded"

      # Prepare background:
      canvas = document.create-element \canvas
      canvas.width = img.width / 4
      canvas.height = img.height / 4

      ctx = canvas.get-context \2d

      ctx.draw-image img, 0, 0, canvas.width, canvas.height

      <~ @blur ctx

      console.log "Recieved blur stuff"

      @current-background = ready: true, value: "url(#{canvas.to-data-URL 'image/png'})"

      @current-background.ready: true
      if @show-called
        @apply-current-background!

    , false

    img.src = background

  show-background: ~>
    if @current-background.ready
      @apply-current-background!
    else
      @show-called = true

  clear-background: ~>
    console.log "CLEARBG"
    @$body.css \background-image, 'none'

  apply-current-background: ~>
    @show-called = false
    if @current-background.ready
      @$body.css \background-image, @current-background.value
      @current-background = value: '', ready: true

  parse-bg: (bg) ->
    bg = bg / 'url(' |> _.last
    bg = bg / ')' |> _.first
    bg .= replace /\'\"/g ''

  blur: (ctx, done) ->
    data = ctx.get-image-data 0, 0, ctx.canvas.width, ctx.canvas.height
    data <- @worker.send 'blur', data
    ctx.put-image-data data, 0, 0

    done!

  current-background: value: '', ready: true
  show-called: false
