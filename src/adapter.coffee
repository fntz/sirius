###
 Adapter
 It's a base class, which must be redefined for concrete javascript library: prototype.js or jQuery or mootools or etc.
 @abstract
###
class Adapter

  _adapter_name: "Adapter"

  ###
   Attach event to an element
   @param {string} main the element for bind
   @param {string} selector - selector query string
   @param {string} event - event name
   @param {function} fn - callback, will be called, when event fired
   @returns {void}
  ###
  bind: (element, selector, event, fn) ->

  ###
   Remove event listener for an element
   @param {string} selector - selector query string
   @param {string} event - event name
   @param {function} fn - callback, will be called, when event fired
   @returns {void}
  ###
  off: (selector, event, fn) ->



  ###
   Call an custom event with params
   @param {string} element - selector for the event
   @param {string} event   - event name
   @param {array<string>}  params  - params which will be passed into event callback
   @returns {void}
  ###
  fire: (element, event, params...) ->

  ###
   Fetch properties from a target element from an event
   @param {EventObject} event - the event object
   @param {array<string>} properties - names of attributes
   @returns {array<string>}
  ###
  get_properties: (event, properties...) ->

  ###
    Fetch an attribute from an element
    @param {HtmlElement} - document
    @param {string} - an attribute name
    @returns {null|boolean|string} - result (depends on attribute meaning)
  ###
  get_attr: (element, attr) ->

  ###
   Change a content into an element
   @param {string} element - a selector
   @param {string} content - a new content
   @returns {void}
  ###
  swap: (element, content) ->

  ###
   Add into bottom
   @param   {string} element - a selector
   @param {string} content - a new content
   @returns {void}
  ###
  append: (element, content) ->

  ###
   Add into top
   @param   {string} element - a selector
   @param {string} content - a new content
   @returns {void}
  ###
  prepend: (element, content) ->

  ###
   Remove a content from an element
   @param {string} element - a selector
   @returns {void}
  ###
  clear: (element) ->

  ###
   set new attribute for element
   @param {string} - a selector
   @param {string} - an attribute
   @param {string} - a new value for the attribute
   @returns {void}
  ###
  set_attr: (element, attr, value) ->

  ###
   @param {string} - a selector
   @returns {array<HtmlDocument>}
  ###
  all: (selector) ->
    return selector if (typeof(selector) == "object" && selector.nodeType == 1 || selector.nodeType == 9)
    document.querySelectorAll(selector)

  ###
   find the first document by a selector
   @returns {HtmlDocument|null}
  ###
  get: (selector) ->
    document.querySelector(selector)

  ###
    pretty print HtmlDocument
    @returns {string}
  ###
  as_string: (doc) ->
    if doc is document
      return "document"
    else if Object.prototype.toString.call(doc) is '[object String]'
      return doc
    else
      try
        if Array.isArray(doc) && doc.size > 1
          klasses = doc.map (x) -> "#{x.tagName}.#{x.className}"
          klasses.slice(0, 3).join(", ")
        else
          "#{doc.tagName}.#{id}"
      catch
        doc
