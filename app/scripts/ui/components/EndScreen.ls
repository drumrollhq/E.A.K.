require! 'user'

dom = React.DOM

module.exports = React.create-class do
  display-name: \EndScreen
  render: ->
    dom.div class-name: 'cont clearfix',
      dom.h2 null, 'To be continued...'
      dom.h3 null, 'New levels coming soon!'
      dom.p style: {text-align: \center}, 'Sign up to save your progress, or leave feedback to make E.A.K. even better!'
      dom.div style: {text-align: \center, margin-top: \15px},
        dom.a {
          class-name: \btn
          style: {margin: '0 10px'}
          href: 'https://docs.google.com/forms/d/1gMg8FcbDmVH-FPYvAaiO33mVp5EaHndu1W3l97RN00s/viewform?usp=send_form'
          target: '_blank'
        } 'Leave Feedback'
        dom.a {
          disabled: user.logged-in!
          class-name: \btn
          style: {margin: '0 10px'}
          href: '#/app/signup'
        } 'Sign Up'
