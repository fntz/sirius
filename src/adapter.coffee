###!
#  Sirius.js v0.4.3
#  (c) 2014 fntzr
#  license: MIT
###

#
#  Adapter
#  It's a base class, which must be redefine for concrete javascript library: prototype.js or jQuery or mootools or etc.
#  @abstract
#
class Adapter

  #   Attach event to element
  #   @param [String] main element for bind
  #   @param [String] selector - selector string
  #   @param [String] event - event name
  #   @param [Function] fn - callback, will be called, when event fired
  #   @return [Void]
  #
  bind: (element, selector, event, fn) ->

  #   Convert element which find with 'selector' to json
  #   @param [String] selector - selector, for find element
  #   @return [JSON]
  #
  form_to_json: (selector) ->

  #   Call custom event with params
  #   @param [String] element - selector for event
  #   @param [String] event   - event name
  #   @param [Array]  params  - params which will be passed into event callback
  #   @return [Void]
  #
  fire: (element, event, params...) ->

  #    Extract attribute from target element from event
  #    @param [EventObject] event - event object
  #    @param [Array<String>] properties - names of attributes
  #    @return [Array<String>]
  #
  get_property: (event, properties...) ->

  get_attr: (element, attr) ->


  set_prop: (element, attr, value) ->
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
    document.querySelectorAll(selector)

  # first from selector
  get: (selector) ->
    document.querySelector(selector)

