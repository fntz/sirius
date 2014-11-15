#
#  Adapter for [jQuery framework](http://jquery.com/).
#  For methods {@see Adapter}
#
class JQueryAdapter extends Adapter
  bind: (element, selector, event, fn) ->
    if selector == null
      jQuery(element).on(event, fn)
    else
      jQuery(element).on(event, selector, fn)

  form_to_json: (selector) ->
    o = {}
    a = jQuery(selector).serializeArray()

    for obj in a
      do(obj) =>
        name = obj["name"]
        value = obj["value"]
        if o[name]
          if !o[name].push
            o[name] = [o[name]]
          else
            o[name].push(value || '')
        else
          o[name] = value || ''
    JSON.stringify(o)

  fire: (element, event, params...) ->
    jQuery(element).trigger(event, params)

  get_property: (event, properties) ->
    for p in properties then jQuery(event.target).attr(p)

  swap: (element, content) ->
    tag = @get_attr(element, 'tagName')
    if tag == "INPUT" || tag == "TEXTAREA"
      jQuery(element).val(content)
    else
      jQuery(element).text(content) #FIXME use text ?

  get_attr: (element, attr) ->
    if attr.indexOf('data') == 0
      attr = attr.substring(5, attr.length)
      jQuery(element).data(attr)
    else
      jQuery(element).prop(attr)

  set_attr: (element, attr, value) ->
    jQuery(element).attr(attr, value)

  append: (element, content) ->
    tag = @get_attr(element, 'tagName')
    if tag == "INPUT" || tag == "TEXTAREA"
      old_val = jQuery(element).val()
      jQuery(element).val("#{old_val}#{content}")
    else
      jQuery(element).append(content)


  prepend: (element, content) ->
    tag = @get_attr(element, 'tagName')
    if tag == "INPUT" || tag == "TEXTAREA"
      old_val = jQuery(element).val()
      jQuery(element).val("#{content}#{old_val}")
    else
      jQuery(element).prepend(content)

  clear: (element) ->
    jQuery(element).text("")

  text: (element) ->
    tag  = @get_attr(element, 'tagName')
    type = @get_attr(element, 'type')
    if tag == "INPUT" || tag == "TEXTAREA"
      if type == "checkbox" || type == "radio"
        jQuery("#{element}:checked").val()
      else
        jQuery(element).val()
    else if tag == "SELECT"
      jQuery("#{element} option:selected").val()
    else
      jQuery(element).text()