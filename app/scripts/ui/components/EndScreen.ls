require! 'user'

dom = React.DOM

module.exports = React.create-class do
  display-name: \EndScreen
  render: ->
    dom.div class-name: 'cont clearfix' style: {max-width: 500px},
      dom.h2 null, 'Want more levels?'
      dom.p style: {text-align: \center}, '''
        If you’d like to see E.A.K. turn into a ‘Mario meets Minecraft’ style game, please support us by making a donation.'''
      dom.p style: {text-align: \center}, '''
        We need developers to help us create more levels and tools for you to build your own levels.'''
      dom.p style: {text-align: \center}, '''
        To say thanks, we’ll send you a copy of the full game for free, when it’s released :)'''
      dom.div style: {text-align: \center, margin-top: \15px},
        dom.a {
          class-name: \btn
          style: {margin: '0 10px'}
          href: '#/app/donate'
        } 'Donate'
