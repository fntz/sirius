class JQueryAdapter extends Adapter
  bind: (selector, event, fn) ->
    jQuery(document).on(event, selector, fn)

  find: (selector) ->
    jQuery(selector)

  element: (element, value, options = {}) ->
    jQuery("<#{element}>").attr(options).text(value)

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
