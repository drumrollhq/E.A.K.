module.exports = {
  name: \contact
  schema:
    type: {type: \string, +required} # start or end
    a: {type: \object, +required} # One of the things in contact
    b: {type: \object, +required} # The other thing in contact
    find: {type: \function, +required}

  parse: (str) ->
    contact-events = str
      |> split ','
      |> map (contact-ev) ->
        parts = contact-ev |> split ':' |> map ( .trim! )
        contacts = parts |> last |> split '+' |> map ( .trim! )
        contacts.0 ?= '*'
        contacts.1 ?= '*'

        {
          type: parts.0
          contacts: contacts
        }

    (contact) ->
      for cev-spec in contact-events when cev-spec.type is contact.type
        [spec-id-a, spec-id-b] = cev-spec.contacts
        ids-a = contact.a.ids
        ids-b = contact.b.ids

        if spec-id-a in ids-a and spec-id-b in ids-b then return true
        if spec-id-b in ids-a and spec-id-a in ids-b then return true

      return false
}
