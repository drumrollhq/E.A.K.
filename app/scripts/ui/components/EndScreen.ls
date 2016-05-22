require! 'user'

dom = React.DOM

module.exports = React.create-class do
  display-name: \EndScreen
  render: ->
    dom.div class-name: 'cont clearfix' style: {max-width: 700px},
      dom.h2 {style: margin-top: \5vh}, 'Thanks for your support!'
      dom.h3 {style: margin-top: \2rem}, '''We can't wait to turn E.A.K. into a full game :)'''
      dom.div style: {text-align: \center, margin-top: \3rem},
        dom.a class-name: \btn, href: 'https://twitter.com/eraseallkittens',
          'Follow us on Twitter'
