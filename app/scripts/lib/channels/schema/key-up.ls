module.exports = {
  name: \key-up
  schema:
    code: {type: \number, +required}
    key: {type: \string, +required}
  parse: require 'lib/channels/schema/key-press' .parse
}
