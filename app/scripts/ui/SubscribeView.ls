require! {
  'data/plans'
  'ui/actions'
}

dom = React.DOM

module.exports = Subscribe = React.create-class {
  display-name: \Subscribe
  mixins: [Backbone.React.Component.mixin]
  get-initial-state: -> {plans}

  select-option: (choice) ->
    if choice is \teachers
      alert 'TODO'
      return

    actions.get-user prevent-close: true
      .then -> window.location.hash = "/app/pay/#choice"
      .catch (e) -> console.log \error-get-user e

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
      dom.ul class-name: \subchoice, plan-list @state.plans
      dom.p null, 'Something here explaining why anyone would want to buy our thing probably aimed at parents.'
}
