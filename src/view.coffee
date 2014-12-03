
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
    handler = (e) ->
      Sirius.Application.get_adapter().and_then((adapter) =>
        adapter.fire.call(null, document, custom_event_name, e, params...)
      )

    Sirius.Application.get_adapter().and_then((adapter) => adapter.bind(document, selector, event_name, handler))
    null


  # @nodoc
  _apply_strategy: (object = {attributes: [], name: 'swap', transform: (old, result) -> "#{result}" }) ->
    Sirius.Application.get_adapter().and_then((adapter) =>
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
    )
    null


  # clear element content
  clear: () ->
    Sirius.Application.get_adapter().and_then((adapter) => adapter.clear(@element))
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
  #
  # ==== Strategies
  #  When you use `bind` for view to view binding you might add strategy for it
  #
  #  @example
  #    view1.bind(view2, {strategy: 'append'})
  #  # then all text from view1 will be copy into view2 content.
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
  # ==== Transform
  #
  # Sometimes need transform given value into other, for this you might use `transform` helper
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
  #     view.bind(my_model, {transform: { title_transformer: (title) -> "#{title}!!!" })
  #
  #     # When we enter input, then it change model attributes
  #     my_model.title() # => user input!!!
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
  # @note strategy it only for view to view
  # @note transform it only for view to model or model to view binding
  # @param [Any] - klass, another view\model\function
  # @param [Object] - hash with setting: [to, from]
  # @return [Sirius.View]
  # TODO pass parameters with object_setting
  bind: (klass, object_setting = {}) ->
    if klass
      if klass.name && klass.name() == "View"
        @_bind_view(klass, object_setting)

      else if Sirius.Utils.is_string(klass)
        @bind(new Sirius.View(klass, object_setting))

      else # then it's Sirius.Model
        @_bind_model(klass, object_setting)

    @

  # @private
  # @nodoc
  _bind_model: (model, setting) ->
    Sirius.Application.get_adapter().and_then (adapter) =>
      setting['transform'] = if setting['transform']?
        setting['transform']
      else
        (x) -> x
      elements = new Sirius.BindHelper(@element, {
        to: 'data-bind-to',
        from: 'data-bind-from'
        strategy: 'data-bind-strategy'
        transform: 'data-bind-transform'
        default_from : null
      }).extract(adapter, setting)

      model_name = Sirius.Utils.fn_name(model.constructor)
      for element in elements
        do(element) ->
          if model.get_attributes().indexOf(element.to) == -1
            throw new Error("Error attribute '#{element.to}' not exist in model class '#{model_name}'")

          transform = Sirius.BindHelper.transform(element.transform, setting)

          clb = (result) =>
            if result['text']? && !element.from
              model.set(element.to, transform(result['text']))
            if element.from == result['attribute']
              model.set(element.to, transform(result['text']))
            if element.from == "checked" # FIXME maybe add array with boolean attributes
              model.set(element.to, result['state'])

          new Sirius.Observer(element.element, clb)



  # @private
  # @nodoc
  _bind_view: (view, setting) ->
    to   = setting['to']   || 'text'
    from = setting['from'] || 'text'
    strategy = setting['strategy'] || 'swap'
    current = @element
    # {text: null, attribute: null}
    clb = (result) ->
      txt = result['text']
      if txt? && !result['attribute'] # for change text
        view.render(txt)[strategy](to)
      else
        view.render(txt)[strategy](to)

    new Sirius.Observer(current, clb)


  #
  # bind2
  # double-sided binding
  # @param [Sirius.View|Sirius.Model] klass - Sirius.Model or Sirius.View
  bind2: (klass) ->
    @bind(klass)
    if klass['bind'] && Sirius.Utils.is_function(klass['bind'])
      klass.bind(@)