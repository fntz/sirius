
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


  #
  # when we have:
  # ### 1 View to View relation with change text
  #   view1.bind(view2)
  # if view1 element have onchange event then we use this event
  # if view1 element does not have onchange event we should use Dom level 3\4 events see #observer.coffee
  #
  # ### 2 View to View relation with change attributes in View2
  #
  # for view1 we should use Dom level 3\4 events
  # also we should know which attributes changed (filter), therefore
  # view1.bind(view2, with: ["id"])
  # when we change text in view1, then should changes in view2 id attribute
  #
  # ### 3 View to View relation change attributes in View1
  #
  # view1.bind(view2, from: ["id"])
  #
  # when change id in view1, we should change text in view2
  #
  # ### 4 Combination of 3 and 4
  #
  # ### 5 View Model relation
  #
  # ### 6 View to any function relation
  bind: (klass) ->
    `var c = function(m){console.log(m);};`
    if klass && klass.constructor && klass.constructor.name
      if klass.constructor.name == "View"
        adapter = Sirius.Application.adapter
        elements = document.querySelectorAll(klass.element)

        #FIXME optimize this
        for element in elements
          # it's for input,textarea, select...
          if Object.keys(element).indexOf("value") != -1
            c "value"
          else

        1

  bind2: () ->