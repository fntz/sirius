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
    jQuery(element).text(content) #FIXME use text ?

  append: (element, content) ->
    jQuery(element).append(content)

  prepend: (element, content) ->
    jQuery(element).prepend(content)

  clear: (element) ->
    jQuery(element).text("")

  text: (element) ->
    jQuery(element).text()