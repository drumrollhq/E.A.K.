module.exports = {
  name: \key-up
  schema:
    code: {type: \number, +required}
    key: {type: \string, +required}
  parse: require 'channels/schema/key-press' .parse
}
