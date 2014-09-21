
# Class which represent Views for Application
# Fluent interface for manipulate views
#
class Sirius.View

  constructor: (@cache = false, clb = ->) ->
    @_cache_result = []
    @_adapter = Sirius.Application.adapter
    @_result = (args...) =>
      result = clb.apply(null, args...) #TODO maybe @ instead of null
      @_cache_result.push([arguments, result]) if @cache
      result

  clear: () ->
    @_cache_result = []

  render: (args...) ->
    @_result(args)
    @

  # swap content for given element
  swap: () ->
    # @_adapter.swap(element, content)

  # append to current element new content in bottom
  append: () ->
    # @_adapter.append(element, content)

  # prepend to current element new content in top
  prepend: () ->
    # @_adapter.prepend(element, content)








