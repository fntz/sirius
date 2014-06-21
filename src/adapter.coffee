#
#  Adapter
#  It's a base class, which must be redefine for concrete javascript library: prototype.js or jQuery or mootools or etc.
#  @abstract
#
class Adapter

  #   Attach event to element
  #   @method #bind(selector, event, fn)
  #   @param [String] selector - selector string
  #   @param [String] event - event name
  #   @param [Function] fn - callback, will be called, when event fired
  #   @return [Void]
  #
  bind: (selector, event, fn) ->

  #   Convert element which find with 'selector' to json
  #   @method #form_to_json(selector)
  #   @param [String] selector - selector, for find element
  #   @return [JSON]
  #
  form_to_json: (selector) ->

  #   Call custom event with params
  #   @method #fire(element, event, params...)
  #   @param [String] element - selector for event
  #   @param [String] event   - event name
  #   @param [Array]  params  - params which will be passed into event callback
  #   @return [Void]
  #
  fire: (element, event, params...) ->

  #    Extract attribute from target element from event
  #    @method #get_property(event, properties...)
  #    @param [EventObject] event - event object
  #    @param [Array<String>] properties - names of attributes
  #    @return [Array<String>]
  #
  get_property: (event, properties...) ->



