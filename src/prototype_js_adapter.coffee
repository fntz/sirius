#
#  Adapter for [prototype.js framework](http://prototypejs.org}).
#  For methods {@see Adapter}
#  @waning: need tests for it
class PrototypeAdapter extends Adapter

  __name: () -> 'PrototypeAdapter'

  bind: (element, selector, event, fn) ->
    if selector == null
      $(element).on(event, fn)
    else
      $(element).on(event, selector, fn)

  fire: (element, event, params...) ->
    $(element).fire(event, params)

  get_property: (event, properties...) -> #FIXME
    for p in properties then Event.element(event).readAttribute(p);

  get_attr: (element, attr) ->
    $(element).readAttribute(attr) #FIXME maybe $(element).attr ?

  set_attr: (element, attr, value) ->
    $(element).writeAttribute(attr, value)

  set_prop: (element, prop, value) ->
    $(element).prop = value

  swap: (element, content) ->
    element = $(element)
    tag = element.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      element.setValue(content)
    else
      $(element).update(content)

  append: (element, content) ->
    element = $(element)
    tag = element.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      old_val = element.getValue()
      element.setValue("#{old_val}#{content}")
    else
      $(element).insert({bottom: content})

  prepend: (element, content) ->
    element = $(element)
    tag = element.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      old_val = element.getValue()
      element.setValue("#{content}#{old_val}")
    else
      $(element).insert({top: content})

  clear: (element) ->
    $(element).update("")

  text: (element) ->
    element = $(element)
    tag = element.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || "SELECT"
      element.getValue()
    else
      if element.innerText
        element.innerText
      else
        element.textContent

  get_state: (element) ->
    $(element).checked