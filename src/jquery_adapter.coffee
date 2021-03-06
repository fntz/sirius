#
#  Adapter for [jQuery framework](http://jquery.com/).
#  For methods {@see Adapter}
#
class JQueryAdapter extends Adapter

  _adapter_name: "jQuery"

  bind: (element, selector, event, fn) ->
    if selector == null
      jQuery(element).on(event, fn)
    else
      jQuery(element).on(event, selector, fn)
    return

  off: (selector, event, fn) ->
    jQuery(document).off(event, selector, fn)
    return

  fire: (element, event, params...) ->
    jQuery(element).trigger(event, params)
    return

  get_properties: (event, properties) ->
    target = jQuery(event.target)
    current_target = jQuery(event.currentTarget || event.target)
    result = []
    for p in properties
      t = target.attr(p)
      ct = current_target.attr(p)
      result.push(t || ct)
    result

  get_attr: (element, attr) ->
    if attr.indexOf('data') == 0
      attr = attr.replace("data-", "")
      jQuery(element).data(attr)
    else
      jQuery(element).prop(attr)

  set_attr: (element, attr, value) ->
    if attr.indexOf('data-') == -1
      jQuery(element).attr(attr, value)
    else
      jQuery(element).data(attr.replace("data-", ""), value)
    return

  append: (element, content) ->
    jQuery(element).append(content)
    return

  prepend: (element, content) ->
    jQuery(element).prepend(content)
    return

  clear: (element) ->
    jQuery(element).text("")
    return

  swap: (element, content) ->
    tag = @get_attr(element, 'tagName')
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      jQuery(element).val(content)
    else
      jQuery(element).text(content)
    return

  text: (element) ->
    tag  = @get_attr(element, 'tagName')
    type = @get_attr(element, 'type')
    if tag == "INPUT" || tag == "TEXTAREA"
      if type == "checkbox" || type == "radio"
        jQuery(element).val()
      else
        jQuery(element).val()
    else if tag == "SELECT"
      jQuery(element).find("option:selected").val()
    else
      jQuery(element).text()
