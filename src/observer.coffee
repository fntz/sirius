
# hacks for observer when property or text changed into DOM

# #TODO not need create new observer, just subscribe for the currents
# @private
class Sirius.Observer

  @_observers:   []
  @add_observer: (new_observer) ->
    []
  @_clbs: {}#[] # save callbacks for properties

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
  constructor: (@from_element, @clb = ->) ->
    adapter = Sirius.Application.get_adapter()
    adapter.and_then(@_create)

  # @nodoc
  # @private
  _create: (adapter) =>
    logger  = Sirius.Application.get_logger()
    clb  = @clb
    from = @from_element
    current_value = null

    if typeof(from) == 'object' && from.object && from.prop
      logger.info("Observer: for #{from.object}", logger.observer)
      current_prop = from.prop.split(".").join("-")
      if @constructor._clbs[current_prop]?
        @constructor._clbs[current_prop].push([from.object, clb])
        # because already have handler
      else
        @constructor._clbs[current_prop] = [[from.object, clb]]

      clbs = @constructor._clbs

      handler = (prop, oldvalue, newvalue) ->
        # need call all callbacks for current pair: object#property
        result =
          text: newvalue
          previous: oldvalue

        clbs[current_prop].filter((a) -> a[0] == from.object).forEach((a) -> a[1].call(null, result))
        newvalue

      my_watch = (object, prop, handler) ->
        namespaces = prop.split(".")
        o = object
        for n, index in namespaces when index < namespaces.length - 1
          o = object[n]

        o.watch(namespaces[namespaces.length - 1], handler)
        return


      my_watch(from.object, from.prop, handler)

      return


    else
      tag  = adapter.get_attr(from, 'tagName')
      type = adapter.get_attr(from, 'type')

      logger.info("for #{from}", logger.observer)
      # FIXME maybe save all needed attributes in hash ????
      handler = (e) ->
        logger.info("Handler Function: given #{e.type} event", logger.observer)
        result = {text: null, attribute: null}
        return if ['focusout', 'focusin'].indexOf(e.type) != -1
        txt = adapter.text(from)

        return if ["input", "selectionchange"].indexOf(e.type) != -1 && txt == current_value

        if e.type == "input" || e.type == "childList" || e.type == "change" || e.type == "DOMNodeInserted" || e.type == "selectionchange"
          result['text'] = txt
          current_value = txt

        if e.type == "change" # get a state for input enable or disable
          result['state'] = adapter.get_state(from)

        if e.type == "attributes"
          attr_name = e.attributeName
          old_attr = e.oldValue || [] # FIXME remove this, because not used
          new_attr  = adapter.get_attr(from, attr_name)

          result['text'] = new_attr
          result['attribute'] = attr_name
          result['previous'] = old_attr

        if e.type == "DOMAttrModified" # for ie 9...
          attr_name = e.originalEvent.attrName
          old_attr  = e.originalEvent.prevValue
          new_attr  = adapter.get_attr(from, attr_name)
          result['text'] = new_attr
          result['attribute'] = attr_name
          result['previous'] = old_attr

        clb(result)

      #FIXME need only when 'from text' expected
      if ONCHANGE_TAGS.indexOf(tag) != -1
        if type == "checkbox" || type == "radio" || tag == "OPTION"
          logger.info("Get a #{type} & #{tag} element", logger.observer)
          adapter.bind(document, @from_element, 'change', handler)
        else
          current_value = adapter.text(@from_element)
          adapter.bind(document, @from_element, 'input', handler)
          #instead of using input event, which not work correctly in ie9
          #use own implementation of input event for form
          if Sirius.Utils.ie_version() == 9
            logger.warn("Hook for work with IE9 browser", logger.observer)
            adapter.bind(document, document, 'selectionchange', handler)

        # return, because for input element seems this events enough
        # fixme is it correct?
        return

      if MO
        logger.info("MutationObserver support", logger.observer)
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

        if Sirius.Utils.is_string(from)
          elements = adapter.get(from) # fixme : all
          observer.observe(elements, cnf)
        else
          observer.observe(from, cnf) # FIXME when it works?

      else # when null, need register event with routes
        # FIXME stackoverflow
        logger.warn("MutationObserver not support", logger.observer)
        logger.info("Use Deprecated events for observe", logger.observer)
        adapter.bind(document, @from_element, 'DOMNodeInserted', handler)
        adapter.bind(document, @from_element, 'DOMAttrModified', handler)












