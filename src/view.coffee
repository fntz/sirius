
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

  name: () -> 'View' # define name, because `constructor.name` not work in IE

  # contain all strategies for view
  @_Strategies = []

  @_Cache = [] # cache for all views

  # @param [String] - selector for element
  # @param [Function] - transform function for new content
  #
  constructor: (@element, @clb = (txt) -> txt) ->
    element = @element
    clb = @clb

    view = @constructor._Cache.filter((v) -> v.element == element && "#{v.clb}" == "#{clb}")

    if view.length != 0
      view[0]

    @logger = Sirius.Application.get_logger()
    @_result_fn = (args...) =>
      clb.apply(null, args...)
    @logger.info("View: Create a new View for #{@element}")



    for strategy in @constructor._Strategies
      do(strategy) =>
        name = strategy[0]
        @logger.info("View: Define #{name} strategy")
        transform = strategy[1]
        render = strategy[2]
        @[name] = (attribute = "text") =>
          # @render already called
          # and we have @_result
          result = @_result
          element = @element
          @logger.info("View: Start processing strategy for #{element}")
          Sirius.Application.get_adapter().and_then (adapter) ->
            # need extract old value
            oldvalue = if attribute is 'text'
              adapter.text(element)
            else
              adapter.get_attr(element, attribute)
            res = transform(oldvalue, result)
            render(adapter, element, res, attribute)

    @constructor._Cache.push(@)

  # compile function
  # @param [Array] with arguments, which pass into transform function
  # By default transform function take arguments and return it `(x) -> x`
  # @return [Sirius.View]
  render: (args...) ->
    @logger.info("View: Call render for #{args}")
    @_result = @_result_fn(args)
    @

  #
  # @param [String] - selector in element
  # @param [String] - event name
  # @param [String] - custom event name, which will be fired on event name
  # @param [Array]  - parameters which will be pass into method for custom event name
  # @note  First param for bind method is an Custom Event
  # @note  Second param for bind method is an Original Event
  # @example
  #    //html
  #    <div id="my-div">
  #      <button>click me</button>
  #    </div>
  #
  #    # coffee
  #    view = Sirius.View("#my-div")
  #    view.on("button", "click", "button:click", 'param1', 'param2', param3')
  #    # or
  #    view.on("button", "click", (e) -> view.render("custom-class").swap("class"))
  #
  #    routes =
  #      "button:click": (custom_event, original_event, p1, p2, p3) ->
  #         # you code
  on: (selector, event_name, custom_event_name, params...) ->
    selector = if selector == @element
                 selector
               else
                 "#{@element} #{selector}"
    @logger.info("View: Bind event for #{selector}, event name: #{event_name}, will be called : #{custom_event_name}")

    if Sirius.Utils.is_string(custom_event_name)
      handler = (e) ->
        Sirius.Application.get_adapter().and_then((adapter) =>
          adapter.fire.call(null, document, custom_event_name, e, params...)
        )
      Sirius.Application.get_adapter().and_then((adapter) => adapter.bind(document, selector, event_name, handler))
    else
      if Sirius.Utils.is_function(custom_event_name)
        Sirius.Application.get_adapter().and_then((adapter) =>
          adapter.bind(document, selector, event_name, custom_event_name)
        )
        #custom_event_name
      else
        throw new Error("View: 'custom_event_name' must be string or function, #{typeof(custom_event_name)} given")

    return


  # check if strategy valid
  # @param [String] - given strategy
  # @return [Boolean]
  @is_valid_strategy: (s) ->
    @_Strategies.filter((arr) -> arr[0] == s).length != 0


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
  #
  # Another way for pass parameters to bind method:
  #
  # @example
  #    view1.bind(view2, {strategy: 'strategy-name', from: 'text', to: 'data-attr'})
  #
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
  #
  # With options:
  #
  # @example
  #    # in html code not need to specify data-* attributes
  #    form_view.bind(model, {
  #      'input[type="text"]': {from: 'text', to: 'title', transform: (x) -> "#{x}!!!", strategy: "swap",
  #      'textarea': {to: 'description'}
  #    })
  #
  #  Only need create an object, where keys is a nodes for current view (`form_view` in current case),
  #  when you need bind one node with more then one model attribute use array:
  #
  # @example
  #   form_view.bind(model, {
  #     'input[type="text"]': [{to: 'title'}, {to: 'another-attribute', transform: (title_text) -> "#{title_text}!!!" ]
  #   })
  #
  # As previously: default strategy: 'swap', default transform: `(x) -> x`
  #
  # === 3. View to String
  #
  # When you pass into `bind` method string, then it create new `Sirius.View` for it string,
  # and work as View to View.
  #
  # === 4. Property to View
  #
  # View possible bind with any javascript object property.
  #
  # @example
  #
  #    //html
  #    <span></span>
  #
  #    my_collection = new Sirius.Collection(MyModel)
  #    view = new Sirius.View("span")
  #    view.bind(my_collection, 'length')
  #
  #    my_collection.push(new MyModel())
  #    # then
  #    <span>1</span>
  #
  # @note
  #   change in view -> view|model
  #   but
  #   chane in property -> view
  #
  # @note strategy it only for view to view
  # @note transform it only for view to model or model to view binding
  # @param [Any] - type, another view\model\function
  # @param [Object|String] - hash with setting: [to, from] or property
  # @return [Sirius.View]
  # TODO pass parameters with setting
  bind: (klass, args...) ->
    setting = args[0] || {}
    extra = args[1] || {}

    @logger.info("View: Call bind for #{klass}")
    if klass
      if klass.name && klass.name() == "View"
        @_bind_view(klass, setting)

      else if (typeof(klass) == 'object') && Sirius.Utils.is_string(setting)
        @_bind_prop(klass, setting, extra)

      else if Sirius.Utils.is_string(klass)
        @bind(new Sirius.View(klass, setting))

      else # then it's Sirius.Model
        @_bind_model(klass, setting)

    @

  # @private
  # @nodoc
  _bind_model: (model, setting) ->
    # setting must be like
    # setting =
    #   '#element':
    #     to: ''
    #     from: ''
    #     transform: '' # or default transform
    #     strategy: '' # or default strategy
    #
    @logger.info("View: Bind #{@element} and model: #{Sirius.Utils.fn_name(model.constructor)}")
    Sirius.Application.get_adapter().and_then (adapter) =>

      setting['transform'] = if setting['transform']?
        @logger.info("View: 'transform' method not found. Use default transform method.")
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
          # find property
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
  _bind_prop: (object, prop, setting = {}) ->
    @logger.info("View: Bind '#{@element}' and object #{object} with property: #{prop}")
    to = setting['to'] || 'text'
    strategy  = setting['strategy'] || 'swap'
    transform = setting['transform'] || (x) -> x
    # from this property
    view = @
    clb = (result) ->
      txt = transform(result['text'])
      view.render(txt)[strategy](to)

    new Sirius.Observer({object: object, prop: prop}, clb)

  # @private
  # @nodoc
  _bind_view: (view, setting) ->
    @logger.info("View: Bind '#{@element}' with '#{view.element}'")
    to   = setting['to']   || 'text'
    from = setting['from'] || 'text'
    strategy = setting['strategy'] || 'swap'
    @logger.info("View: for '#{view.element}' use to: '#{to}' and from: '#{from}', strategy: #{strategy}")
    current = @element
    # {text: null, attribute: null}
    clb = (result) ->
      txt = result['text']
      view.render(txt)[strategy](to)

    new Sirius.Observer(current, clb)


  #
  # bind2
  # double-sided binding
  # @param [Sirius.View|Sirius.Model] klass - Sirius.Model or Sirius.View
  bind2: (klass, setting = {}) ->
    @bind(klass, setting['model'] || {})
    if klass['bind'] && Sirius.Utils.is_function(klass['bind'])
      klass.bind(@, setting['view'] || {})

  # Register new strategy for View
  # @param [String] - strategy name
  # @param [Object] - object with transform and render functions, take oldvalue, and newvalue for attribute
  # transform [Function] - transform function, take oldvalue, and newvalue for attribute
  # render [Function] - render function, take adapter, element, result and attribute
  #
  # @example
  #   # swap strategy
  #   Sirius.View.register_strategy('swap',
  #      transform: (oldvalue, newvalue) -> "#{newvalue}"
  #      render: (adapter, element, result, attribute) ->
  #        if attribute == 'text'
  #          adapter.swap(element, result)
  #        else
  #          adapter.set_attr(@element, attribute, result)
  #   )
  #
  #   # html strategy
  #   Sirius.View.register_strategy('html',
  #      transform: (oldvalue, newvalue) -> "<b>#{newvalue}<b>"
  #      render: (adapter, element, result, attribute) ->
  #        if attribute == 'text'
  #          $(element).html(result)
  #        else
  #          throw new Error("Html strategy work only for text, not for #{attribute}")
  #   )
  #
  #
  # @return [Void]
  @register_strategy: (name, object = {}) ->
    logger = Sirius.Application.get_logger()
    logger.info("View: Register new Strategy #{name}")
    transform = object.transform
    render = object.render
    if !Sirius.Utils.is_function(transform)
      msg = "Strategy must be Function, but #{typeof transform} given."
      logger.error("View: #{msg}")
      throw new Error(msg)

    if !Sirius.Utils.is_function(render)
      msg = "Strategy must be Function, but #{typeof render} given."
      logger.error("View: #{msg}")
      throw new Error(msg)

    if !Sirius.Utils.is_string(name)
      msg = "Strategy name must be String, but #{typeof name} given."
      logger.error("View: #{msg}")
      throw new Error(msg)

    @_Strategies.push([name, transform, render])
    null


Sirius.View.register_strategy('swap',
  transform: (oldvalue, newvalue) -> "#{newvalue}"
  render: (adapter, element, result, attribute) ->
    if attribute == 'text'
      adapter.swap(element, result)
    else
      if attribute == 'checked'
        # for boolean attributes need remove it when result is false
        r = if Sirius.Utils.is_string(result)
              if result == 'true'
                true
              else
                false
            else
              !!result

        adapter.set_prop(element, 'checked', r)
      else
        adapter.set_attr(element, attribute, result)
)

Sirius.View.register_strategy('append',
  transform: (oldvalue, newvalue) -> newvalue
  render: (adapter, element, result, attribute) ->
    if attribute == 'text'
      adapter.append(element, result)
    else
      throw new Error("Strategy 'append' only work for 'text' content, not for '#{attribute}'")
)

Sirius.View.register_strategy('prepend',
  transform: (oldvalue, newvalue) -> newvalue
  render: (adapter, element, result, attribute) ->
    if attribute == 'text'
      adapter.prepend(element, result)
    else
      throw new Error("Strategy 'prepend' only work for 'text' content, not for '#{attribute}'")
)

Sirius.View.register_strategy('clear',
  transform: (oldvalue, newvalue) -> ""
  render: (adapter, element, result, attribute) ->
    adapter.clear(element)
)



