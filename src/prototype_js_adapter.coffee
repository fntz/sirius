#
#  Adapter for [prototype.js framework](http://prototypejs.org}).
#  For methods {@see Adapter}
#  @waning: need tests for it
class PrototypeAdapter extends Adapter

  bind: (element, selector, event, fn) ->
    if selector == null
      $(document).on(event, fn)
    else
      $(element).on(event, selector, fn)

  fire: (element, event, params...) ->
    $(element).fire(event, params)

  get_property: (event, properties...) ->
    element = Event.element(event)
    self = @
    properties.flatten().inject([], (acc, p) ->
      acc.push(self.get_attr(element, p))
      acc
    )

  get_attr: (element, attr) ->
    r = $(element).readAttribute(attr)
    if !r?
      r = $(element)[attr]
    r

  set_attr: (element, attr, value) ->
    $(element).writeAttribute(attr, value)

  set_prop: (element, prop, value) ->
    $(element).prop = value

  swap: (element, content) ->
    element = $(element)
    tag = element.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      element.setValue("")
      element.clear()
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
    tag = $(element).tagName
    if $w("INPUT TEXTAREA").include(tag)
      $(element).clear()
    else
      $(element).update("")

  text: (element) ->
    elem = $(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      elem.getValue()
    else
      if elem.innerText
        elem.innerText
      else
        elem.textContent

  get_state: (element) ->
    $(element).checked