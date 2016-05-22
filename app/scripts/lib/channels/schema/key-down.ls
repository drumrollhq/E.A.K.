module.exports = {
  name: \key-down
  schema:
    code: {type: \number, +required}
    key: {type: \string, +required}
  parse: require 'lib/channels/schema/key-press' .parse
}
