#
#  Adapter for [prototype.js framework](http://prototypejs.org}).
#  For methods {@see Adapter}
#
class PrototypeAdapter extends Adapter
  bind: (element, selector, event, fn) ->
    if selector == null
      $(element).on(event, fn)
    else
      $(element).on(event, selector, fn)

  form_to_json: (selector) ->
    JSON.stringify($$(selector).first().serialize(true))

  fire: (element, event, params...) ->
    $(element).fire(event, params)

  get_property: (event, properties...) -> #FIXME
    for p in properties then Event.element(event).readAttribute(p);