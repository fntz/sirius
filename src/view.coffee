
# Class which represent Views for Application
# Fluent interface for manipulate views
#
# @example:
#
#   myView = new Sirius.View("body", false, (content) -> "<div>#{content}</div>"
#   # in controller
#   myView.render(results_from_ajax_to_html).swap() # change body content
#
#   myView.clear().render('results')
#   myListView.render("<li>new element</li>").append()
#   myTableView.render("<tr><td>top</td></tr>").prepend()
#
class Sirius.View

  constructor: (@element, @cache = false, clb = ->) ->
    @_cache_result = []
    @_adapter = Sirius.Application.adapter
    @_result = (args...) =>
      result = clb.apply(null, args...)
      @_cache_result.push([arguments, result]) if @cache
      result

  clear_cache: () ->
    @_cache_result = []

  render: (args...) ->
    @_result(args)
    @

  # swap content for given element
  # @return null
  swap: () ->
    @_adapter.swap(element, content)
    null

  # append to current element new content in bottom
  # @return null
  append: () ->
    @_adapter.append(element, content)
    null

  # prepend to current element new content in top
  prepend: () ->
    @_adapter.prepend(element, content)
    null

  # clear element content
  clear: () ->
    @_adapter.clear(element)
    @






