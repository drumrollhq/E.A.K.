require! {
  'game/mediator'
  'WebWorker'
}

# Background manages the background images. It tries to parse the URL out of a
# CSS background property, and then passes the result to a worker that blurs the
# image. The blurred image fills the browser window behind the level.

module.exports = class Background
  ->
    @$body = $ document.body

    # Set up the worker
    @worker = new WebWorker name: 'Blur'

    # Background is controlled by the global Mediator.
    mediator.on 'prepareBackground' @prepare-background
    mediator.on 'showBackground' @show-background
    mediator.on 'clearBackground' @clear-background

  prepare-background: (background) ~>
    @current-background = value: '', ready: false

    # Parse out an image URL from the background property
    background = @parse-bg background

    # Load the image
    img = new Image

    img.addEventListener \load, ~>

      # Create a canvas a quarter the size of the image
      canvas = document.create-element \canvas
      canvas.width = img.width / 4
      canvas.height = img.height / 4

      ctx = canvas.get-context \2d

      # draw the image to the canvas so we can get the image data from it
      ctx.draw-image img, 0, 0, canvas.width, canvas.height

      # Blur the image on the canvas
      <~ @blur ctx

      # Save the blurred canvas, ready to be used
      @current-background = ready: true, value: "url(#{canvas.to-data-URL 'image/png'})"

      @current-background.ready: true

      # We've already had someone try to show the background, show it now
      if @show-called
        @apply-current-background!

    , false

    # Kick off image load
    img.src = background

  # If the background's ready, show it. If not, signal to show the background as
  # soon as it's ready
  show-background: ~>
    if @current-background.ready
      @apply-current-background!
    else
      @show-called = true

  # reset bg image
  clear-background: ~> @$body.css \background-image, 'none'

  # Get the background image onto the page
  apply-current-background: ~>
    @show-called = false
    if @current-background.ready
      @$body.css \background-image, @current-background.value
      @current-background = value: '', ready: true

  # Find a URL from a background image
  parse-bg: (bg) ->
    bg = bg / 'url(' |> _.last
    bg = bg / ')' |> _.first
    bg .= replace /\'\"/g ''

  # Blur takes a canvas context, and a callback for when the blurring is done.
  blur: (ctx, done) ->
    # Fetch data out from the canvas context
    data = ctx.get-image-data 0, 0, ctx.canvas.width, ctx.canvas.height

    # Send it to the blur worker
    data <- @worker.send 'blur', data

    # Restore the blurred data when the worker is done with it
    ctx.put-image-data data, 0, 0

    done!

  current-background: value: '', ready: true
  show-called: false
