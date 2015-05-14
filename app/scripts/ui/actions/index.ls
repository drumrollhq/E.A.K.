require! {
  'ui/actions/GetUser'
}

module.exports = actions = {
  setup: (overlay, app) -> actions <<< {
    get-user: -> new GetUser overlay, app .promise
  }
}
