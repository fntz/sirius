
# Class which represent Views for Application
# Fluent interface for manipulate views
#
# @example:
#
#   myView = new Sirius.View("body", (content) -> "<div>#{content}</div>"
#   # in controller
#   myView.render(results_from_ajax_to_html).swap() # change body content
#
#   myView.clear().render('results')
#   myListView.render("<li>new element</li>").append()
#   myTableView.render("<tr><td>top</td></tr>").prepend()
#
class Sirius.View

  constructor: (@element, clb = ->) ->
    @_result_fn = (args...) =>
      clb.apply(null, args...)

  render: (args...) ->
    @_result = @_result_fn(args)
    @

  # swap content for given element
  # @return null
  swap: () ->

    Sirius.Application.adapter.swap(@element, @_result)
    null

  # append to current element new content in bottom
  # @return null
  append: () ->
    Sirius.Application.adapter.append(@element, @_result)
    null

  # prepend to current element new content in top
  prepend: () ->
    Sirius.Application.adapter.prepend(@element, @_result)
    null

  # clear element content
  clear: () ->
    Sirius.Application.adapter.clear(@element)
    @