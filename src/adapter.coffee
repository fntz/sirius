###
  Base Adapter class, which must be redefine for concrete javascript library: prototypejs or jquery or mootools...
###
class Adapter
  # Create a event for selector with callback
  # @param selector [String] is a tag name
  # @param event [String] event name
  # @param fn [Funciton] callback
  bind: (selector, event, fn) ->
  #
  # Find all elements by selector
  # @param [String] selector
  find: (selector) ->
  #
  # Create a new html element with value as a text and options
  # @param element [String] html tag
  # @param value [String]
  # @param options [Object] an object
  element: (element, value, options = {}) ->
  #
  # serialize form to json
  # @param [String] selector - form selector
  form_to_json: (selector) ->
