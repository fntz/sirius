
# hacks for observer when property or text changed into DOM

# #TODO not need create new observer, just subscribe for the currents
# @private
class Sirius.Internal.Observer

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
  # BUG when reset input, bound element should reset
  constructor: (@from_element, @original, @watch_for, @clb = ->) ->
    adapter = Sirius.Application.get_adapter()
    adapter.and_then(@_create)

  # @nodoc
  # @private
  _create: (adapter) =>
    logger  = Sirius.Application.get_logger()
    clb  = @clb
    from = @from_element
    original = @original
    current_value = null
    watch_for = @watch_for

    tag  = adapter.get_attr(from, 'tagName')
    type = adapter.get_attr(from, 'type')

    logger.debug("Create binding for #{from}", logger.binding)

    handler = (e) ->
      logger.debug("Handler Function: given #{e.type} event", logger.binding)
      result = {text: null, attribute: null, from: from, original: original}
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

    if watch_for == "text"
      # text + input
      if ONCHANGE_TAGS.indexOf(tag) != -1
        logger.debug("It is not a #{ONCHANGE_TAGS}")
        if type == "checkbox" || type == "radio" || tag == "OPTION"
          logger.debug("Get a #{type} & #{tag} element for bool elements", logger.binding)
          adapter.bind(document, @from_element, 'change', handler)
        else
          current_value = adapter.text(@from_element)
          adapter.bind(document, @from_element, 'input', handler)
          #instead of using input event, which not work correctly in ie9
          #use own implementation of input event for form
          if Sirius.Utils.ie_version() == 9
            logger.warn("Hook for work with IE9 browser", logger.binding)
            adapter.bind(document, document, 'selectionchange', handler)

        # return, because for input element seems this events enough

      else
        logger.warn("Seems you try to bind for #{tag} of #{type} for 'text' which is not supported")


    else if MO # any element + not text
      logger.debug("MutationObserver support", logger.binding)
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
      logger.warn("MutationObserver not supported", logger.binding)
      logger.warn("Use Deprecated events for observe", logger.binding)
      adapter.bind(document, @from_element, 'DOMNodeInserted', handler)
      adapter.bind(document, @from_element, 'DOMAttrModified', handler)












