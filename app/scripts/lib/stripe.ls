handler-promise = null
load-stripe = -> new Promise (resolve, reject) ->
  el = document.create-element \script
    ..onload = resolve
    ..onerror = reject
    ..src = 'https://checkout.stripe.com/checkout.js'

  document.head.append-child el

export get-handler = ->
  if handler-promise then return that
  handler-promise := load-stripe!
    .then ->
      StripeCheckout.configure {
        key: EAKCONFIG.STRIPE
        image: 'https://s3-eu-west-1.amazonaws.com/drumroll-uploads/social-innit-small.png'
        name: 'Drum Roll HQ Limited'
        currency: \GBP
      }
