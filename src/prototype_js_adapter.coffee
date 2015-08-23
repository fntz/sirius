#
#  Adapter for [prototype.js framework](http://prototypejs.org}).
#  For methods {@see Adapter}
#  @note use selectors
class PrototypeAdapter extends Adapter

  _get_element_from_selector: (selector) ->
    if (typeof(selector) == "object" && selector.nodeType == 1)
      return $(selector)
    e = @all(selector)
    if e.length == 0
      throw new Error("Selector `#{selector}` not found")
    e[0]


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
    elem = @_get_element_from_selector(element)
    r = elem.readAttribute(attr)
    if !r?
      r = elem[attr]
    r

  set_attr: (element, attr, value) ->
    @_get_element_from_selector(element).writeAttribute(attr, value)

  set_prop: (element, prop, value) ->
    @_get_element_from_selector(element)[prop] = value

  swap: (element, content) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      elem.setValue("")
      elem.clear()
      elem.setValue(content)
    else
      @_get_element_from_selector(element).update(content)

  append: (element, content) ->
    @_get_element_from_selector(element).insert(bottom: content)

  prepend: (element, content) ->
    @_get_element_from_selector(element).insert(top: content)

  clear: (element) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if $w("INPUT TEXTAREA").include(tag)
      elem.clear()
    else
      elem.update("")

  text: (element) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      elem.getValue()
    else
      if elem.innerText
        elem.innerText
      else
        elem.textContent

  get_state: (element) ->
    @_get_element_from_selector(element).checked