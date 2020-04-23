#
#  Adapter
#  It's a base class, which must be redefine for concrete javascript library: prototype.js or jQuery or mootools or etc.
#  @abstract
#
class Adapter

  #   Attach event to an element
  #   @param [String] main the element for bind
  #   @param [String] selector - selector query string
  #   @param [String] event - event name
  #   @param [Function] fn - callback, will be called, when event fired
  #   @return [Void]
  #
  bind: (element, selector, event, fn) ->

  #   Remove event listener for an element
  #   @param [String] main the element for bind
  #   @param [String] selector - selector query string
  #   @param [String] event - event name
  #   @param [Function] fn - callback, will be called, when event fired
  #   @return [Void]
  #
  off: (element, selector, event, fn) ->


  #   Call an custom event with params
  #   @param [String] element - selector for the event
  #   @param [String] event   - event name
  #   @param [Array]  params  - params which will be passed into event callback
  #   @return [Void]
  #
  fire: (element, event, params...) ->

  #    Extract attribute from a target element from an event
  #    @param [EventObject] event - the event object
  #    @param [Array<String>] properties - names of attributes
  #    @return [Array<String>]
  #
  get_property: (event, properties...) ->

  get_attr: (element, attr) ->


  # Change content into element
  # @param   [String] element - selector
  # @content [String] content - new content
  swap: (element, content) ->

  # Add in bottom
  # @param   [String] element - selector
  # @content [String] content - new content
  append: (element, content) ->

  # Add in top
  # @param   [String] element - selector
  # @content [String] content - new content
  prepend: (element, content) ->

  # Remove content from element
  # @param [String] element - selector
  clear: (element) ->

  # set new attribute for element
  # @param [String] - selector
  # @param [String] - attribute
  # @param [String] - new value for attribute
  set_attr: (element, attr, value) ->


  # return all selectors
  all: (selector) ->
    return selector if (typeof(selector) == "object" && selector.nodeType == 1 || selector.nodeType == 9)
    document.querySelectorAll(selector)


  # first from selector
  get: (selector) ->
    document.querySelector(selector)

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
