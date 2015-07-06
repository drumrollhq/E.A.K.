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
    @country = \gb

  events:
    'click button.subscribe': 'pay'
    'change select.country': 'changeCountryEvent'
    'keyup select.country': 'changeCountryEvent'

  sub-details: (type = @type) ->
    sub = switch type
    | \parents-yearly => parents-yearly
    | \parents-monthly => parents-monthly
    | otherwise => throw new Error "Bad sub type: #type"

    vat = VATRates[@country.to-upper-case!]
    if vat
      sub <<< {
        vat: true
        vat-percentage: vat.rates.standard
        vat-amt: sub.amt * vat.rates.standard / 100
      }
    else
      sub <<< vat: false, vat-amt: 0

    sub.total = sub.amt + sub.vat-amt
    sub

  render: ->
    data = @sub-details!
    @$el.html template data
    @$country-select = @$ \select.country
    @$country-select.val @country

  args: (type) ->
    @type = type
    @render!

  change-country-event: (e) ->
    @change-country @$country-select.val!
    @$country-select.focus!

  change-country: (new-country) ->
    if new-country isnt @country
      @country = new-country
      @render!

  pay: ->
    sub = @sub-details!
    console.log sub
    @handler-promise.then (handler) ~>
      handler.open {
        token: @token
        description: "E.A.K. #{sub.periodly} Subscription"
        amount: sub.total * 100
        email: user.get \user.email
        panel-label: 'Subscribe'
      }

  token: (token) ~>
    console.log token
    user.subscribe {
      plan: @sub-details!.id
      token: token.id
      ip: token.client_ip
      card-country: token.card.country
      user-country: @country
    }
