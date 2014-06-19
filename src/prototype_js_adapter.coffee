class PrototypeAdapter extends Adapter
  bind: (selector, event, fn) ->
    $(document).on(event, selector, fn)

  find: (selector) ->
    $$(selector)

  element: (element, value, options = {}) ->
    new Element(element, options).update(value)

  form_to_json: (selector) ->
    JSON.stringify($$(selector).first().serialize(true))

  fire: (element, event, params...) ->
    $(element).fire(event, params)

  get_property: (event, properties...) -> #FIXME
    for p in properties then Event.element(event).readAttribute(p);