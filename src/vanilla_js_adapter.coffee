
class VanillaJsAdapter extends Adapter

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
      all = @all(selector)
      for e in [0...all.length]
        all.item(e).addEventListener(event, fn)


  fire: (element, event, params...) ->
    # Fixme
    ev = document.createEvent("CustomEvent")
    ev.initCustomEvent(event, false, true, params)
    document.dispatchEvent(ev)

  get_property: (event, properties) ->
    e = event.target
    for p in properties
      @get_attr(e, p)

  get_attr: (element, attr) ->
    elem = @_get_element_from_selector(element)
    r = elem.getAttribute(attr)
    if !r?
      elem[attr]
    else
      r

  swap: (element, content) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      elem.value = content
    else
      elem.textContent = content

  set_attr: (element, attr, value) ->
    @_get_element_from_selector(element).setAttribute(attr, value)

  set_prop: (element, prop, value) ->
    @_get_element_from_selector(element).setAttribute(prop, value)

  append: (element, content) ->
    elem = @_get_element_from_selector(element)
    old = elem.textContent
    elem.textContent = old + content

  prepend: (element, content) ->
    elem = @_get_element_from_selector(element)
    old = elem.textContent
    elem.textContent = content + old

  clear: (element) ->
    elem = @_get_element_from_selector(element)
    tag = elem.tagName
    if tag == "INPUT" || tag == "TEXTAREA"
      elem.value = ""
    else
      elem.textContent = ""

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

  get_state: (element) ->
    @_get_element_from_selector(element).checked
