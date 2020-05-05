
class VanillaJsAdapter extends Adapter

  _adapter_name: "VanillaJs"

  _get_element_from_selector: (selector) ->
    if (typeof(selector) == "object" && selector.nodeType == 1)
      return selector
    e = @all(selector)
    if e.length == 0
      throw new Error("Selector `#{selector}` not found")
    e[0]

  bind: (element, selector, event, fn) ->
    if selector == null || selector == element
      element.addEventListener(event, fn)
    else
      # need find all elements and add listener
      if (typeof(selector) == "object" && selector.nodeType == 1)
        selector.addEventListener(event, fn)
      else
        all = @all(selector)

        for e in [0...all.length]
          all.item(e).addEventListener(event, fn)
    return

  off: (selector, event, fn) ->
    all = @all(selector)
    for e in [0...all.length]
      all.item(e).removeEventListener(event, fn)
    return

  fire: (element, event, params...) ->
    # Fixme
    ev = document.createEvent("CustomEvent")
    ev.initCustomEvent(event, false, true, params)
    document.dispatchEvent(ev)
    return

  get_properties: (event, properties) ->
    e = event.target
    for p in properties
      @get_attr(e, p)

  get_attr: (element, attr) ->
    elem = @_get_element_from_selector(element)
    r = elem.getAttribute(attr)

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


  swap: (element, content) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      elem.value = content
    else
      elem.textContent = content
    return

  set_attr: (element, attr, value) ->
    @_get_element_from_selector(element).setAttribute(attr, value)
    return

  append: (element, content) ->
    elem = @_get_element_from_selector(element)
    old = elem.textContent
    elem.textContent = old + content
    return

  prepend: (element, content) ->
    elem = @_get_element_from_selector(element)
    old = elem.textContent
    elem.textContent = content + old
    return

  clear: (element) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA"
      elem.value = ""
    else
      elem.textContent = ""
    return

  text: (element) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      elem.value
    else
      if elem.innerText
        elem.innerText
      else
        elem.textContent

