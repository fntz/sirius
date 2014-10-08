
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

  name: () -> 'View' # define name, because not work in IE: constructor.name

  constructor: (@element, clb = (txt) -> txt) ->
    @_result_fn = (args...) =>
      clb.apply(null, args...)

  render: (args...) ->
    @_result = @_result_fn(args)
    @

  # swap content for given element
  # @return null
  swap: (attributes...) ->
    real_attributes = for a in attributes when a != null then a
    if real_attributes.length == 0
      Sirius.Application.adapter.swap(@element, @_result)
    else
      for attr in real_attributes
        Sirius.Application.adapter.set_attr(@element, attr, @_result)
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
  # view1.bind(view2, to: ["id"])
  # when we change text in view1, then should changes in view2 id attribute
  #
  # ### 3 View to View relation change attributes in View1
  #
  # view1.bind(view2, from: ["id"])
  #
  # when change id in view1, we should change text in view2
  #
  # ### 4 Combination of 3 and 4
  # view1.bind(view2, from: ["id"], to: ["class"]
  #
  # ### 5 View Model relation
  # when it's model, then need inspect element, and extract children from current element
  #
  # simple example, bind one element for one attribute:
  #   <input id="title" type='text' />
  #
  #   view = Sirius.View("#title")
  #   model = new MyModel()//model with attrs: [title, id, description]
  #   # bind
  #   view.bind(model, {to: 'title'})
  #   # more ...
  #   view.bind(model, {to: 'other-attribute'}) #error, because attribute not found
  #   # or possible
  #   <input id="title" type='text' data-bind-to='title' />
  #   view.bind(model) #to extracted automatically
  #   #or
  #   <input id="title" type='text' name='title' />
  #   # to = name in attributes
  #   #or possible bind attribute
  #   data-from='class'
  #   or
  #   view.bind(model, {to: 'title', from: 'class'})
  #
  #
  #  more complex example
  #
  #   <div id="post">
  #     <input type="text" data-bind-to='title' data-to='' />
  #     <textarea data-bind='description' data-to='description'></textarea>
  #   </div>
  #
  #   view.bind(model)
  #
  # ### 6 View to any function relation
  #
  #
  # # TODO Also need strategy for change: swap, append, prepend or custom
  # # TODO default value, when text: undefined
  #
  # @param [Any] - klass, another view\model\function
  # @param [Object] - hash with setting: [to, from]
  bind: (klass, object_setting = {}) ->
    `var c = function(m){console.log(m);};`
    adapter = Sirius.Application.adapter
    current = @element
    to   = object_setting['to'] || null
    from = object_setting['from'] || null

    if klass
      if klass.name && klass.name() == "View"
        # {text: null, attribute: null}
        clb = (result) ->
          txt = result['text']
          if txt && !result['attribute']
            klass.render(txt).swap(to)
          else
            c "not implemented #1"
            c result
        new Sirius.Observer(current, clb)
      else # then it Sirius.Model
        children = adapter.all("#{current} *")
        if children.length == 0
          # then it single element and we need extract data-bind-to, data-bind-from and name
          data_bind_to   = adapter.get_attr(current, 'data-bind-to') || adapter.get_attr(current, 'name')
          data_bind_from = adapter.get_attr(current, 'data-bind-from')

          if to && data_bind_to
            c "You define `to` attribute twice: #{to}, #{data_bind_to}"

          if from && data_bind_from
            c "You define `from` attribute twice: #{from}, #{data_bind_from}"

          if !data_bind_to && !to
            c "Error# need pass `to` attribute into `.bind` method or define `data-bind-to` or `name` into html element code"

          to   = to   ? data_bind_to
          from = from ? data_bind_from

          # check if attribute present into model class
          if klass.attributes.indexOf(to) == -1
            c "Error attribute #{to} not exist in model class #{klass}"



          clb = (result) ->
            txt = result['text']
            klass[to](txt)
            c klass 

          new Sirius.Observer(current, clb)


    else
      if Sirius.Utils.is_function(klass)
        1 #when it's only function

    @

  bind2: () ->