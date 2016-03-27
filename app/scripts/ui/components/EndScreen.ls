require! 'user'

dom = React.DOM

module.exports = React.create-class do
  display-name: \EndScreen
  render: ->
    dom.div class-name: 'cont clearfix',
      dom.h2 null, 'To be continued...'
      dom.h3 null, 'New levels coming soon!'
      dom.p style: {text-align: \center}, '''
        Thanks for playing E.A.K.! We're working on adding more levels at the moment, and
        they should be ready soon.'''
      dom.p style: {text-align: \center}, '''
        If you enjoyed playing E.A.K., please leave some feedback, or donate to receive a free copy
        of the full game when it's released.'''
      dom.div style: {text-align: \center, margin-top: \15px},
        dom.a {
          class-name: \btn
          style: {margin: '0 10px'}
          href: 'https://docs.google.com/forms/d/1gMg8FcbDmVH-FPYvAaiO33mVp5EaHndu1W3l97RN00s/viewform?usp=send_form'
          target: '_blank'
        } 'Leave Feedback'
        dom.a {
          class-name: \btn
          style: {margin: '0 10px'}
          href: '#/app/donate'
        } 'Donate'
