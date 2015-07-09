require! {
  'data/plans'
  'ui/actions'
  'user'
  'ui/loader'
  'lib/stripe'
}

dom = React.DOM

plan-details = (id) -> plans[find-index ( .id is id ), plans]

module.exports = Subscribe = React.create-class {
  display-name: \Subscribe
  mixins: [Backbone.React.Component.mixin]
  get-initial-state: -> {plans}

  component-did-mount: ->
    stripe
      .get-handler!
      .then (handler) ~>
        @set-state stripe-loaded: true
        @stripe-handler = handler

  activate: ->
    actions.get-user prevent-close: true
      .then -> window.location.hash = '/app/subscribe'
      .catch (e) -> console.log \error-get-user e

  select-option: (choice) ->
    if @state.loading or not @state.stripe-loaded then return
    @set-state error: null

    if choice is \teachers
      alert 'TODO'
      return

    plan = plan-details choice
    @stripe-handler.open {
      token: @on-token.bind this, plan
      description: "E.A.K. #{plan.periodly} Subscription"
      amount: plan.amt * 100
      email: user.get \user.email
      panel-label: 'Subscribe {{amount}} + VAT'
      billing-address: true
    }

  on-token: (plan, token) ->
    @set-state loading: true
    user
      .subscribe {
        plan: plan.id
        token: token.id
        ip: token.client_ip
        card-country: token.card.country
        user-country: token.card.address_country
      }
      .then (subscription) ~>
        @set-state loading: false
        console.log \subscription subscription
      .catch (e) ~>
        console.log e
        @set-state loading: false, error: e.details || 'We can\'t create your subscription because of mystery reasons D:'

  render: ->
    plan-heading = (plan) ~>
      if plan.amt
        dom.h3 class-name: \subchoice-item-price,
          dom.span class-name: \subchoice-item-amount, "£#{plan.amt}"
          dom.span class-name: \subchoice-item-period, "/#{plan.period}"

      else
        dom.h3 null, plan.title

    plan-list = (plans) ~>
      for plan in plans
        dom.li class-name: \subchoice-item-cont, key: plan.id,
          dom.div class-name: "subchoice-item #{'subchoice-item-emph' if plan.emph}", on-click: (@select-option.bind this, plan.id),
            plan-heading plan
            dom.ul class-name: \subchoice-item-features,
              plan.features.map (feature, i) -> dom.li key: i, feature

    dom.div class-name: \cont-wide,
      dom.h2 null, 'Subscribe to E.A.K.'
      loader.toggle @state.loading || not @state.stripe-loaded, 'Loading...',
        dom.div class-name: (cx \error-panel hidden: not @state.error),
          dom.strong class-name: \error-panel-label, 'Error: '
          dom.span class-name: \error-panel-content, @state.error
        dom.ul class-name: \subchoice, plan-list @state.plans
        dom.p null, 'Something here explaining why anyone would want to buy our thing probably aimed at parents.'
}
