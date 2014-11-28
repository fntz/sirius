
# @private
#
# This class should extract from element node all elements which contain information
# about binding (data-bind-*)
#
# extracted info:
# data-bind-from
# data-bind-to
# data-bind-strategy
# data-bind-view
# element selector
class Sirius.BindHelper

  # @param [String] - selector
  # @param [Object] - contain information for extract (data-bind-*)
  #                   and contain information from user
  #                   and then merge extracted info and passed
  #                   {to: 'data-bind-to', from: 'data-bind-from'
  #                    strategy: 'data-bind-strategy'
  #                    transform: 'data-bind-transform'
  #                    }
  constructor: (@element, @setting, @is_bind_view_to_model = true) ->
    @adapter = Sirius.Application.adapter

  #
  #
  # @param [Object] - `to` and `from` if present
  #
  extract: (user_setting = {}) ->
    # need extract main element, and children
    # fixme optimize this need extract only when element contain data-bind-*
    elements = @adapter.all("#{@element}, #{@element} *")
    # when it contain only one element (no children)
    # it's a single mode

    to = @setting['to']
    from = @setting['from']
    strategy = @setting['strategy']
    transform = @setting['transform']
    default_from = @setting['default_from']
    default_to = @setting['default_to']
    adapter = @adapter
    is_bind_view_to_model = @is_bind_view_to_model
    result = []

    #
    # Extract all elements which contain data-bind-*
    # with data-bind-strategy
    # with data-bind-transform
    # and selector
    for element in elements
      do(element) ->
        tmp_to   = adapter.get_attr(element, to) || default_to
        tmp_from = adapter.get_attr(element, from) || default_from
        tmp_strategy = adapter.get_attr(element, strategy) || 'swap'
        tmp_transform = adapter.get_attr(element, transform)
        # for view to model, need tmp_to but for model to view need tmp_from
        r = {
          to: tmp_to
          from: tmp_from
          strategy: tmp_strategy
          transform: tmp_transform
          element: element
        }
        if is_bind_view_to_model
          if tmp_to
            result.push(r)
        else
          if tmp_from
            result.push(r)

    result

  # @throw [Error] when transform method not defined
  # @param [String] - function name
  # @param [Object]
  # @return [Function] - return transform function from setting
  @transform: (name, setting = {}) ->
    error = (name) -> "Transform method '#{name}' not found in setting"
    if Sirius.Utils.is_function(setting.transform)
      if name
        throw new Error(error(name))
      else
        setting.transform
    else #when it object need extract necessary method
      if setting.transform[name]?
        setting.transform[name]
      else
        throw new Error(error(name))

