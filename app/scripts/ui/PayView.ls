require! {
  'lib/stripe'
  'ui/templates/pay': template
  'user'
}

parents-yearly = amt: 25, period: \year, periodly: 'Yearly', id: \eak-parent-annual
parents-monthly = amt: 3, period: \month, periodly: 'Monthly', id: \eak-parent-monthly

module.exports = class PayView extends Backbone.View
  initialize: ->
    @handler-promise = stripe.get-handler!

  events:
    'click button.subscribe': 'pay'

  sub-details: (type = @type) ->
    switch type
    | \parents-yearly => parents-yearly
    | \parents-monthly => parents-monthly
    | otherwise => throw new Error "Bad sub type: #type"

  render: ->
    data = @sub-details!
    @$el.html template data

  args: (type) ->
    @type = type
    @render!

  pay: ->
    sub = @sub-details!
    console.log sub
    @handler-promise.then (handler) ~>
      handler.open {
        token: @token
        description: "E.A.K. #{sub.periodly} Subscription"
        amount: sub.amt * 100
        email: user.get \user.email
        panel-label: 'Subscribe'
      }

  token: (token) ~>

