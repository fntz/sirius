#
#  Adapter for [jQuery framework](http://jquery.com/).
#  For methods {@see Adapter}
#
class JQueryAdapter extends Adapter

  __name: () -> 'JQueryAdapter'

  bind: (element, selector, event, fn) ->
    if selector == null
      jQuery(element).on(event, fn)
    else
      jQuery(element).on(event, selector, fn)

  fire: (element, event, params...) ->
    jQuery(element).trigger(event, params)

  get_property: (event, properties) ->
    for p in properties then jQuery(event.target).attr(p)

  swap: (element, content) ->
    tag = @get_attr(element, 'tagName')
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
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
    if attr.indexOf('data-') == -1
      jQuery(element).attr(attr, value)
    else
      jQuery(element).data(attr.replace("data-", ""), value)

  set_prop: (element, prop, value) ->
    jQuery(element).prop(prop, value)

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
        jQuery(element).val()
      else
        jQuery(element).val()
    else if tag == "SELECT"
      jQuery("#{element} option:selected").val()
    else
      jQuery(element).text()

  get_state: (element) ->
    jQuery(element).prop('checked')