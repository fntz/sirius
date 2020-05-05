#
#  Adapter for [prototype.js framework](http://prototypejs.org}).
#  For methods {@see Adapter}
#  @note use selectors
class PrototypeAdapter extends Adapter

  _adapter_name: "PrototypeJs"

  constructor: () ->
    super()
    @__handlers = [] # {selector:'', event_name:'', fun: '', handler: ''}

  _get_element_from_selector: (selector) ->
    if (typeof(selector) == "object" && selector.nodeType == 1)
      return $(selector)
    e = @all(selector)
    if e.length == 0
      throw new Error("Selector `#{selector}` not found")
    e[0]


  bind: (element, selector, event, fn) ->
    h = if selector == null
      $(document).on(event, fn)
    else
      if (typeof(selector) == "object" && selector.nodeType == 1)
        $(selector).on(event, fn)
      else
        $(element).on(event, selector, fn)
    @__handlers.push({selector: selector, event_name: event, fun: fn, handler: h})
    return


  off: (selector, event, fn) ->
    for o in @__handlers
      if o["selector"] == selector && o["event_name"] == event &&
      o["fun"].toString == fn.toString
        o["handler"].stop()

    return


  fire: (element, event, params...) ->
    $(element).fire(event, params)
    return

  get_properties: (event, properties...) ->
    element = Event.element(event)
    self = @
    properties.flatten().inject([], (acc, p) ->
      acc.push(self.get_attr(element, p))
      acc
    )

  get_attr: (element, attr) ->
    elem = @_get_element_from_selector(element)
    r = elem.readAttribute(attr)

    if r?
      if attr is "checked" || attr is "selected"
        if r == "false"
          false
        else
          true
      else
        r
    else
      elem[attr]

  set_attr: (element, attr, value) ->
    @_get_element_from_selector(element).writeAttribute(attr, value)

  swap: (element, content) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      elem.setValue("")
      elem.clear()
      elem.setValue(content)
    else
      @_get_element_from_selector(element).update(content)
    return

  append: (element, content) ->
    @_get_element_from_selector(element).insert(bottom: content)
    return

  prepend: (element, content) ->
    @_get_element_from_selector(element).insert(top: content)
    return

  clear: (element) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if $w("INPUT TEXTAREA").include(tag)
      elem.clear()
    else
      elem.update("")
    return

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
