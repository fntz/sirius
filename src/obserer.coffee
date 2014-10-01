
# hacks for observer when property or text changed into DOM

# #TODO not need create new observer, just subscribe for the currents
#
class Sirius.Observer

  @_observers:   []
  @add_observer: (new_observer) ->
    1

  MO = window.MutationObserver ||
       window.WebKitMutationObserver ||
       window.MozMutationObserver || null

  ONCHANGE_TAGS = ["INPUT", "TEXTAREA", "SELECT"]

  # browser support: http://caniuse.com/#feat=mutationobserver
  # MutationObserver support in FF and Chrome, but in old ie (9-10) not
  # for support this browser
  # http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-MutationEvent
  # https://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#mutation-observers
  # BUG when reset input, bind element should reset the same
  # TODO add logger for events
  constructor: (@from_element, @clb = ->) ->
    `var c = function(m){console.log(m);};`
    adapter = Sirius.Application.adapter
    logger  = Sirius.Application.logger
    clb  = @clb
    from = @from_element

    tag  = adapter.get_attr(from, 'tagName')
    type = adapter.get_attr(from, 'type')
    # FIXME maybe save all needed attributes in hash ????
    handler = (e) ->
      result = {text: null, attribute: null}
      if e.type == "input" || e.type == "childList" || e.type == "change"
        result['text'] = adapter.text(from)
      if e.type == "attributes"
        attr_name = e.attributeName
        old_attr = e.oldValue || [] # FIXME remove this, because not used
        new_attr  = adapter.get_attr(from, attr_name)

        result['text'] = new_attr

#        # when old < new, then we add value, send diff
#        # when old = new, then swap value, send new
#        # when old > new, then we remove value, send new
#        new_value = null
#        old_attr_length = old_attr.length
#        new_attr_length = new_attr.length
#
#        if old_attr_length < new_attr_length
#
#        else if old_attr_length == new_attr_length
#
#        else # old > new


        result['attribute'] = attr_name
      clb(result)

    if ONCHANGE_TAGS.indexOf(tag) != -1
      if type == "checkbox" || type == "radio"
        adapter.bind(document, @from_element, 'change', handler)
      else
        adapter.bind(document, @from_element, 'input', handler)


    else
      if MO
        # TODO from element should not be input\textarea\select
        observer = new MO( (mutations) ->
          mutations.forEach handler
        )

        cnf =
          childList: true
          attributes: true
          characterData: true
          attributeOldValue: true
          characterDataOldValue: true
          subtree: false # FIXME subtree: true

        elems = adapter.get(@from_element) # fixme : all

        observer.observe(elems, cnf)

      else # when null, need register event with routes
        1















