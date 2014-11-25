
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
    selector = if selector == @element
                 selector
               else
                 "#{@element} #{selector}"
    adapter = Sirius.Application.adapter
    handler = (e) ->
      adapter.fire.call(null, document, custom_event_name, e, params...)

    adapter.bind(document, selector, event_name, handler)
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
  # == bind
  # This method bind current view and another view or model, or string.
  #
  # === 1. View to View binding
  #
  # We might bind two views, and when in first change some attribute (default is
  # text content or value if it an input or textarea element), then changes the related
  # attributes for second view.
  #
  # @example
  #    // html source
  #    <input type='text' id='v1' />
  #    <input type='text' id='v2' data-bind-from='data-name' data-name='foo' />
  #    <p id='v3'>text</p>
  #    <span id='v4'></span>
  #    <span id='v5' data-name=""></span>
  #
  #    <span id='r1' data-bind-to='data-name'></span>
  #    <span id='r2'></span>
  #    <span id='r3'></span>
  #    <textarea id='r4'></textarea>
  #    <span id='r5'></span>
  #
  #    # coffee
  #    v1 = new Sirius.View('#v1')
  #    v2 = new Sirius.View('#v2')
  #    v3 = new Sirius.View('#v3')
  #    v4 = new Sirius.View('#v4')
  #    v5 = new Sirius.View('#v5')
  #
  #    r1 = new Sirius.View('#v1')
  #    r2 = new Sirius.View('#v2')
  #    r3 = new Sirius.View('#v3')
  #    r4 = new Sirius.View('#v4')
  #    r5 = new Sirius.View('#v5')
  #
  #    # bind
  #    v1.bind(r1)
  #    v2.bind(r2)
  #    v3.bind(r3)
  #    v4.bind(r4)
  #    v5.bind(r5, {from: 'data-name', to: 'data-name'}) # without create data-bind-* in html code
  #
  #    # change some text or attribute
  #    # change text in input, then:
  #    $("#r1").data('name') # => user input
  #
  #    # change attr in another input
  #    $("#v2").data("bar")
  #    $("#r2").data('name') # => bar
  #
  #    # by default we bind text to text
  #    $("#v3").text("new content")
  #    $("#r3").text() # => new content
  #
  #    text to text
  #    $("#v4").text("new content")
  #    $("#r4").val() # => new content
  #
  #    # attribute to attribute
  #    $("#v5").data('name', "new name")
  #    $("#r5").data('name') # => new name
  #
  # You might bind text to text or text to attribute, or attribute to text, or attribute to attribute.
  #
  # === 2. View to Model
  #
  # Change view attribute or text content will be change in model related attribute.
  #
  # You might bind html attribute or html content with any attribute in model.
  #
  #  @example
  #     // html source code
  #
  #     <form id="form">
  #       <input type='text' data-bind-to='title'>
  #       <textarea data-bind-to='description'></textarea>
  #     </form>
  #
  #     # coffee
  #     view = new Sirius.View("#form")
  #     my_model = new MyModel() # attributes: id, title, description
  #     view.bind(my_model)
  #
  #     # When we enter input, then it change model attributes
  #     my_model.title() # => user input
  #     my_model.description() # => user input
  #
  # === 3. View to String
  #
  # When you pass into `bind` method string, then it create new `Sirius.View` for it string,
  # and work as View to View.
  #
  #
  # @note when you add text into element with jQuery#text method, it will not cause associated method. Use #html for it.
  #
  # TODO: add strategies
  # @param [Any] - klass, another view\model\function
  # @param [Object] - hash with setting: [to, from]
  # @return [Sirius.View]
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
          if txt? && !result['attribute'] # for change text
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
          # then it single element and we need extract data-bind-to, data-bind-from
          tmp_to   = adapter.get_attr(current, 'data-bind-to')
          tmp_from = adapter.get_attr(current, 'data-bind-from') || 'text'

          if to && tmp_to
            new Error("Error: You define `to` attribute twice")

          if from && tmp_from
            new Error("Error: You define `from` attribute twice")

          if !tmp_to && !to
            new Error("Error: need pass `to` attribute into `.bind` method or define `data-bind-to` into html element code")

          to   = if !to then tmp_to else to
          from = if !from then tmp_from else from

          clb = (result) =>
            txt = result['text']
            if txt? && from == 'text'
              #c("call #{to} with #{txt}")
              klass.set(to, txt)
            if from == result['attribute']
              klass.set(to, txt)

          new Sirius.Observer(@element, clb)


        else
          if to || from
            new  Error("Error: `to` or `from` which pass into `bind` method, not taken use `data-bind-to` or `name` and `data-bind-from`")

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
              adapter.get_attr(child, 'data-bind-to')

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
                  if txt? && !data_bind_from
                    klass[data_bind_to](txt)
                  if data_bind_from == result['attribute']
                    klass[data_bind_to](txt)
                  if data_bind_from == "checked"
                    klass[data_bind_to](result['state'])

                new Sirius.Observer(child, clb)

    else
      if Sirius.Utils.is_string(klass)
        @bind(new Sirius.View(klass))
      else
        new Error("Unsupported argument for `bind`. Need View, Model, or String.")

    @

  #
  # bind2
  # double-sided binding
  # @param [Sirius.View|Sirius.Model] klass - Sirius.Model or Sirius.View
  bind2: (klass) ->
    @bind(klass)
    if klass['bind'] && Sirius.Utils.is_function(klass['bind'])
      klass.bind(@)