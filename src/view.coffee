
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

  _listeners: []

  # @private
  class EventHandlerParams
    constructor: (@selector, @event_name, @custom_event_name) ->

    eq: (another) ->
      @selector == another.selector and
      @event_name == another.event_name and
      # last arguments is a function
      @custom_event_name.toString == another.custom_event_name.toString


  # @param [String] - selector for element
  # @param [Function] - transform function for new content
  #
  constructor: (@element, @clb = (txt) -> txt) ->
    element = @element

    clb = @clb
    view = Sirius.View._Cache.filter (v) ->
      v.element == element && "#{v.clb}" == "#{clb}"

    if view.length != 0
      return view[0]


    @_cache_event_handlers = []
    @logger = Sirius.Application.get_logger()
    @_result_fn = (args...) ->
      clb.apply(null, args...)
    @logger.info("Create a new View for #{@element}", @logger.view)


    for strategy in @constructor._Strategies
      do(strategy) =>
        name = strategy[0]
        @logger.info("Define #{name} strategy", @logger.view)
        transform = strategy[1]
        render = strategy[2]
        @[name] = (attribute = "text") =>
          # @render already called
          # and we have @_result
          result = @_result
          element = @element
          @logger.info("Start processing strategy for #{element}", @logger.view)
          Sirius.Application.get_adapter().and_then (adapter) ->
            # need extract old value
            oldvalue = if attribute is 'text'
              adapter.text(element)
            else
              adapter.get_attr(element, attribute)
            res = transform(oldvalue, result)
            render(adapter, element, res, attribute)

    Sirius.View._Cache.push(@)
    @

  get_element: () ->
    @element

  _register_state_listener: (transformer) ->
    @logger.info("Register new listener for element: #{@get_element}", @logger.view)
    @_listeners.push(transformer)

  # compile function
  # @param [Array] with arguments, which pass into transform function
  # By default transform function take arguments and return it `(x) -> x`
  # @return [Sirius.View]
  render: (args...) ->
    @logger.info("Call render for #{args}", @logger.view)
    @_result = @_result_fn(args)
    @

  #
  # call strategy on inner element
  # @param [String] - inner element selector
  # @example
  #   //coffee
  #   v.render("new-class").zoom(".inner-element").swap('class')
  zoom: (selector) ->
    v = if selector == @element
      @
    else
      new Sirius.View("#{@element} #{selector}")

    v._result = @_result
    v

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

    type = if Sirius.Utils.is_string(custom_event_name)
      0
    else if Sirius.Utils.is_function(custom_event_name)
      1
    else
      throw new Error("View: 'custom_event_name' must be string or function, #{typeof(custom_event_name)} given")

    current = new EventHandlerParams(selector, event_name, custom_event_name)

    is_present = @_cache_event_handlers.filter (x) ->
      x.eq(current)

    if is_present.length == 0

      # TODO possible rebind ?
      @logger.info("Bind event for #{selector}, event name: #{event_name}, will be called : #{custom_event_name}", @logger.view)

      if type == 0
        handler = (e) ->
          Sirius.Application.get_adapter().and_then (adapter) ->
            adapter.fire.call(null, document, custom_event_name, e, params...)

        Sirius.Application.get_adapter().and_then (adapter) ->
          adapter.bind(document, selector, event_name, handler)

        tmp = new EventHandlerParams(selector, event_name, handler)
        @_cache_event_handlers.push(tmp)

      else
        Sirius.Application.get_adapter().and_then (adapter) ->
          adapter.bind(document, selector, event_name, custom_event_name)
        @_cache_event_handlers.push(current)

    else
      # Safe clojure management in Sirius.
      # Need remove old references with anon function
      # And off events for this handler

      f = is_present.shift()
      idx = @_cache_event_handlers.indexOf(f)
      if idx > -1
        @_cache_event_handlers.splice(idx, 1)
      @_cache_event_handlers.push(current)

      Sirius.Application.get_adapter().and_then (adapter) ->
        adapter.off(document, selector, event_name, f.custom_event_name)
        f = null
        adapter.bind(document, selector, event_name, custom_event_name)

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
  # Data flow: view1[from] ~> transform ~> view2[to] with strategy
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
  #    r1 = new Sirius.View('#r1')
  #    r2 = new Sirius.View('#r2')
  #    r3 = new Sirius.View('#r3')
  #    r4 = new Sirius.View('#r4')
  #    r5 = new Sirius.View('#r5')
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

    @logger.info("View: Call bind for #{klass}", @logger.view)
    if klass

      if (typeof(klass) == 'object') && Sirius.Utils.is_string(setting)
        @_bind_prop(klass, setting, extra)

        # bug, when bind object property {name: function() {}}
      else if klass.name && klass.name() == "View"
        @_bind_view(klass, setting)

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
    @logger.info("Bind #{@element} and model: #{Sirius.Utils.fn_name(model.constructor)}", @logger.view)

    logger = @logger

    Sirius.Application.get_adapter().and_then (adapter) =>

      # when it is object with functions -> transform
      # otherwise this setting for elements
      t = Object.keys(setting).map((key) -> Sirius.Utils.is_function(setting[key]))

      if t.length == 0
        logger.info("View: Bind: setting empty", logger.view)
        setting['transform'] = if setting['transform']?
          setting['transform']
        else
          logger.info("View: 'transform' method not found. Use default transform method.", logger.view)
          (x) -> x
      else
        # if not transform for given key define default transform method
        Object.keys(setting).map((key) ->
          if !setting[key]['transform']?
            logger.info("View: define default transform method for '#{key}'", logger.view)
            setting[key]['transform'] = (x) -> x
        )

      elements = new Sirius.BindHelper(@element).extract(adapter, setting)

      model_name = Sirius.Utils.fn_name(model.constructor)

      for element in elements
        do(element) ->
          # find property
          if model.get_attributes().indexOf(element.to) == -1
            throw new Error("Error attribute '#{element.to}' not exist in model class '#{model_name}'")

          transform = element.transform

          clb = (result) ->
            # work with logical elements: checkbox, radio and select
            # for checkbox or radio need define in model attribute as object
            # TODO cache this

            nms = element.element
            type = adapter.get_attr(nms, 'type')
            selector = element.selector
            state = result['state']
            value = adapter.get_attr(nms, 'value')
            actual_attribute = model.get(element.to)

            if result['text']? && (!element.from || element.from == 'text')
              model.set(element.to, transform(result['text']))
              return

            if element.from == result['attribute']
              model.set(element.to, transform(result['text']))
              return

            if element.from == "checked" # // "selected"
              if value.length == 0
                throw new Error("value attribute for #{selector} is empty, check please")

              if type == 'radio'
                if Sirius.Utils.is_object(actual_attribute)
                  logger.info("attribute #{element.to} is object, change property #{value} to #{state}", logger.view)
                  o = {}
                  o[value] = state
                  model.set(element.to, o)
                else
                  if state is true
                    throw new Error("For bind radio '#{selector}' need define attribute '#{element.to}' in model as object")
              else if type == 'checkbox'
                if Sirius.Utils.is_object(actual_attribute)
                  logger.info("attribute #{element.to} is object, change property #{value} to #{state}", logger.view)
                  o = {}
                  o[value] = state
                  model.set(element.to, o)
                else
                  throw new Error("For bind checkbox '#{selector}' need define attribute '#{element.to}' in model as object")
              else
                model.set(element.to, result['state']) # FIXME for select?

          new Sirius.Observer(element.element, clb)

          # then need set in model attributes if present and length > 0
          # result: [text, attribute, state]
          if !element.from || element.from == 'text'
            txt = adapter.text(element.element)
            if txt && txt.length > 0
              clb({text: txt})
          else if element.from == "checked"
            state = adapter.get_state(element.element)
            clb({state: state})
          else # attribute
            txt = adapter.get_attr(element.element, element.from)
            if txt && txt.length > 0
              clb({text: txt, attribute: element.from})



  # @private
  # @nodoc
  _bind_prop: (object, prop, setting = {}) ->
    @logger.info("View: Bind '#{@element}' and object #{object} with property: #{prop}", @logger.view)
    to = setting['to'] || 'text'
    strategy  = setting['strategy'] || 'swap'
    transform = setting['transform'] || (x) -> x
    # from this property
    view = @

    clb = (result) ->
      txt = transform(result['text'])
      view.render(txt)[strategy](to)

    new Sirius.Observer({object: object, prop: prop}, clb)
    return

  # @private
  # @nodoc
  _bind_view: (view, setting) ->
    @logger.info("Bind '#{@element}' with '#{view.element}'", @logger.view)
    to   = setting['to']   || 'text'
    from = setting['from'] || 'text'
    strategy = setting['strategy'] || 'swap'
    @logger.info("for '#{view.element}' use to: '#{to}' and from: '#{from}', strategy: #{strategy}", @logger.view)
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


  pipe: (output, via) ->
    t = new Sirius.Transformer(@, output)
    t.run(via)

    return




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
    logger.info("View: Register new Strategy #{name}", logger.view)
    transform = object.transform
    render = object.render
    if !Sirius.Utils.is_function(transform)
      msg = "Strategy must be Function, but #{typeof transform} given."
      logger.error("View: #{msg}", logger.view)
      throw new Error(msg)

    if !Sirius.Utils.is_function(render)
      msg = "Strategy must be Function, but #{typeof render} given."
      logger.error("View: #{msg}", logger.view)
      throw new Error(msg)

    if !Sirius.Utils.is_string(name)
      msg = "Strategy name must be String, but #{typeof name} given."
      logger.error("View: #{msg}", logger.view)
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
    tag = adapter.get_attr(element, 'tagName')
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      throw new Error("'append' strategy not work for `input` or `textarea` or `select` elements")

    if attribute == 'text'
      adapter.append(element, result)
    else
      throw new Error("Strategy 'append' only work for 'text' content, not for '#{attribute}'")
)

Sirius.View.register_strategy('prepend',
  transform: (oldvalue, newvalue) -> newvalue
  render: (adapter, element, result, attribute) ->
    tag = adapter.get_attr(element, 'tagName')
    if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
      throw new Error("'prepend' strategy not work for `input` or `textarea` or `select` elements")

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



