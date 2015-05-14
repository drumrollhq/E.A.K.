handler-promise = null
load-stripe = -> new Promise (resolve, reject) ->
  $ '<script></script>'
    .one \load -> resolve!
    .one \error -> reject!
    .attr \src, 'https://checkout.stripe.com/checkout.js'
    .append-to document.body

export get-handler = ->
  if handler-promise then return that
  handler-promise = load-stripe!
    .then ->
      StripeCheckout.configure {
        key: EAKCONFIG.STRIPE
        image: 'https://s3.amazonaws.com/stripe-uploads/acct_15BCvVFFXmeeZW4Gmerchant-icon-1429460523003-social%20innit.png'
        name: 'Drum Roll HQ Limited (E.A.K.)'
        bitcoin: true
      }
