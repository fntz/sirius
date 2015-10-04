
# @private
#
class Sirius.BindHelper

  # @param [String] - selector
  #                   and contain information from user
  #                   and then merge extracted info and passed
  #
  constructor: (@element, @is_bind_view_to_model = true) ->
    @logger = Sirius.Application.get_logger()
  #
  # @param [T < Adapter] - current application adapter
  # @param [Object] - `to` and `from` if present
  #
  extract: (adapter, user_setting = {}) ->
    # when it contain only one element (no children)
    # it's a single mode
    is_bind_view_to_model = @is_bind_view_to_model
    result = []
    default_from = null
    default_to = if is_bind_view_to_model
      null
    else
      'text'
    @logger.info("BindHelper: default from: #{default_from}", @logger.binding)
    @logger.info("BindHelper: default to: #{default_to}", @logger.binding)

    element = @element
    keys = Object.keys(user_setting)
    keys.forEach (k) ->
      if !Sirius.Utils.is_object(user_setting[k])
        @logger.error("DEPRECATED: seems `user_setting`: '#{tmp_a}' in #{Object.keys(user_setting)} contain non object")
        @logger.error("Html data-bind-* removed")
        throw new Error("Define setting for binding with javascript object")

    elements = []

    Object.keys(user_setting).map (selector) ->
      realElement = if selector is element
        element
      else
        "#{element} #{selector}"
      tag = adapter.get_attr(realElement, 'tagName')
      type = adapter.get_attr(realElement, 'type')

      if tag == "OPTION" || type == "checkbox" || type == "radio"
        z = adapter.all(realElement)
        for x in z
          elements.push([x, selector])
      else
        elements.push([adapter.get(realElement), selector])

    logger = @logger
    top = element

    elements.forEach (elem) ->
      if !elem[0]?
        msg = "Element '#{elem[1]}' not found. Check please."
        logger.error(msg, logger.binding)
        throw new Error(msg)

      key = user_setting[elem[1]]
      if !key?
        msg = "BindHelper: Not found keys for binding for '#{key}' element"
        logger.error(msg, logger.binding)
        throw new Error(msg)

    unwrap = (element, key) ->
      tmp_to = key['to'] || default_to
      tmp_from = key['from'] || default_from
      tmp_strategy = key['strategy'] || 'swap'
      tmp_transform = key['transform']
      tmp_original = if top is element[1] then "#{top}" else "#{top} #{element[1]}"
      elem = element[0]
      {
        to: tmp_to
        from: tmp_from
        strategy: tmp_strategy
        transform: tmp_transform
        element: elem
        selector: tmp_original
      }

    for element in elements
      do(element) ->
        key = user_setting[element[1]]
        if Sirius.Utils.is_array(key)
          key.forEach (key) ->
            r = unwrap(element, key)
            result.push(r)
        else
          r = unwrap(element, key)
          if is_bind_view_to_model
            if r['to']
              result.push(r)
          else
            if r['from']
              result.push(r)

    result

