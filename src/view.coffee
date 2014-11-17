
# Class which represent Views for Application
# Fluent interface for manipulate views
#
# @note By default this function mark elements with id
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

  # @param [String] - selector for element
  # @param [Function] - transform function for new content
  #
  constructor: (@element, clb = (txt) -> txt) ->
    @_result_fn = (args...) =>
      clb.apply(null, args...)

  render: (args...) ->
    @_result = @_result_fn(args)
    @

  # swap content for given element
  # @return null
  swap: (attributes...) ->
    @_apply_strategy
      attributes: for a in attributes when a != null then a
      name : 'swap'
      transform: (old, result) -> "#{result}"

  # append to current element new content in bottom
  # @param [Array] list of attributes for append new value
  # when attributes is empty(is default for text|value) then only append
  # @note this strategy not work for SELECT element
  # @return null
  append: (attributes...) ->
    @_apply_strategy
      attributes: for a in attributes when a != null then a
      name : 'append'
      transform: (old, result) -> "#{old}#{result}"

  # prepend to current element new content in top
  # @note this strategy not work for SELECT element
  # @return null
  prepend: (attributes...) ->
    @_apply_strategy
      attributes: for a in attributes when a != null then a
      name : 'prepend'
      transform: (old, result) -> "#{result}#{old}"

  #
  # @param [String] - selector in element
  # @param [String] - event name
  # @param [String] - custom event name, which will be fired on event name
  # @param [Array]  - parameters which will be pass into method for custom event name
  # @note  First param for bind method is an Custom Event
  # @note  Second param for bind method is an Original Event
  # @example
  #    //html
  #    <button id="click">click me</button>
  #
  #    //js
  #    buttonView = Sirius.View("#click")
  #    buttonView.on("click", "button:click", 'param1', 'param2', param3')
  #
  #    routes =
  #      "button:click": (custom_event, original_event, p1, p2, p3) ->
  #         # you code
  on: (selector, event_name, custom_event_name, params...) ->
    adapter = Sirius.Application.adapter
    handler = (e) ->
      adapter.fire.call(null, document, custom_event_name, e, params...)

    adapter.bind(document, "#{@element} #{selector}", event_name, handler)
    null


  # @nodoc
  _apply_strategy: (object = {attributes: [], name: 'swap', transform: (old, result) -> "#{result}" }) ->
    adapter = Sirius.Application.adapter
    if object.attributes.length == 0
      adapter[object.name](@element, @_result)
    else
      for attr in object.attributes
        do(attr) =>
          if attr == 'text'
            adapter[object.name](@element, @_result)
          else
            old_val = adapter.get_attr(@element, attr)
            adapter.set_attr(@element, attr, object.transform(old_val, @_result))
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
  # # TODO back to after call callback, for example when user enter
  # # input then with bind with model
  # # after we return errors for view
  # # is it possible?
  # #
  # @param [Any] - klass, another view\model\function
  # @param [Object] - hash with setting: [to, from]
  bind: (klass, object_setting = {}) ->
    `var c = function(m){console.log(m);};`
    adapter = Sirius.Application.adapter
    current = @element

    if klass
      if klass.name && klass.name() == "View"
        to   = object_setting['to']   || 'text'
        from = object_setting['from'] || 'text'
        # {text: null, attribute: null}
        clb = (result) ->
          txt = result['text']
          if txt && !result['attribute'] # for change text
            klass.render(txt).swap(to)
          else
            klass.render(txt).swap(to)
        new Sirius.Observer(current, clb)
      else # then it's Sirius.Model
        to   = object_setting['to']
        from = object_setting['from']

        children = adapter.all("#{current} *")
        count    = children.length

        # before
        if count == 0
          # then it single element and we need extract data-bind-to, data-bind-from and name
          tmp_to   = adapter.get_attr(current, 'data-bind-to') || adapter.get_attr(current, 'name')
          tmp_from = adapter.get_attr(current, 'data-bind-from')

          if to && tmp_to
            c "You define `to` attribute twice"

          if from && tmp_from
            c "You define `from` attribute twice"

          if !tmp_to && !to
            c "Error# need pass `to` attribute into `.bind` method or define `data-bind-to` or `name` into html element code"

          to   = to is null ? tmp_to : to
          from = from is null ? tmp_from : from

        else
          if to || from
            c "Error, `to` or `from` which pass into `bind` method, not taken use `data-bind-to` or `name` and `data-bind-from`"

        # when only one element in collection need wrap his in array
        children = if count == 0
          [current]
        else
          children

        for child in children
          do(child) ->
            data_bind_to = if count == 0
              to
            else
              adapter.get_attr(child, 'data-bind-to') || adapter.get_attr(child, 'name')

            if data_bind_to
              # check if attribute present into model class
              if klass.attributes.indexOf(data_bind_to) == -1
                c "Error attribute #{to} not exist in model class #{klass}"

              data_bind_from = if count == 0
                from
              else
                adapter.get_attr(child, 'data-bind-from')

              if data_bind_to
                clb = (result) ->
                  txt = result['text']
                  if txt && !data_bind_from
                    klass[data_bind_to](txt)
                  if data_bind_from == result['attribute']
                    klass[data_bind_to](txt)

                new Sirius.Observer(child, clb)

    else
      if Sirius.Utils.is_function(klass)
        klass(@element)

    @

  bind2: () ->