require! {
  'data/plans'
  'lib/stripe'
  'user'
  'ui/CountrySelect'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \CreateSubscription
  mixins: [Backbone.React.Component.mixin]
  get-initial-state: -> {
    country: \gb
    stripe: stripe.get-handler!
  }

  change-country: (country) ->
    @set-state {country}

  args: (id) ->
    @set-state plan: plans[find-index ( .id is id ), plans]

  render: ->
    plan = @state.plan
    unless plan
      return dom.div class-name: \cont-wide,
        dom.h2 null, 'Loading...'

    vat = VATRates[@state.country.to-upper-case!]
    has-vat = !!vat
    vat ?= rates: standard: 0
    vat-amount = if vat then plan.amt * vat.rates.standard / 100 else 0
    total = plan.amt + vat-amount

    dom.div class-name: \cont-wide,
      dom.h2 null, 'Subscribe to E.A.K.'
      dom.p null, 'Todo: collect address, ask whether to auto-renew'
      dom.p null, 'Select your country from this tedious drop-down menu:'
      React.create-element CountrySelect, on-change: @change-country, country: @state.country
      dom.table null,
        dom.tr null,
          dom.td null, "E.A.K. #{plan.periodly} subscription"
          dom.td null, "£#{plan.amt.to-fixed 2}"

        dom.tr class-name: (cx hidden: not has-vat),
          dom.td null, "VAT (#{vat.rates.standard}%)"
          dom.td null, "£#{vat-amount.to-fixed 2}"

        dom.tr class-name: (cx hidden: not has-vat),
          dom.td null, 'Total'
          dom.td null, "£#{total.to-fixed 2}"

      dom.p null, "Country: #{@state.country}"
      dom.p null, "Confirm your subscription of #{total.to-fixed 2}/#{plan.period}"
      dom.button class-name: 'btn subscribe', 'Subscribe'
}

class PayView extends Backbone.View
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
