require! {
  'ui/actions/GetUser'
}

module.exports = actions = {
  setup: (overlay, app) -> actions <<< {
    get-user: (options) -> new GetUser overlay, app, options .promise
  }
}
