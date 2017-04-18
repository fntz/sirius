
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

  name: () -> 'View' # define name, because `constructor.name` not works in IE

  # contain all strategies for view
  @_Strategies = []

  @_Cache = [] # cache for all views

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

    @_listeners = []

    @_cache_event_handlers = []
    @logger = Sirius.Application.get_logger()
    @_result_fn = (args...) ->
      clb.apply(null, args...)
    @logger.debug("Create a new View for #{@element}", @logger.view)


    for strategy in @constructor._Strategies
      do(strategy) =>
        name = strategy[0]
        @logger.debug("Define #{name} strategy", @logger.view)
        transform = strategy[1]
        render = strategy[2]
        @[name] = (attribute = "text") =>
          # @render already called
          # and we have @_result
          result = @_result
          element = @element
          @logger.debug("Start processing strategy for #{element}", @logger.view)
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

  _register_state_listener: (clb) ->
    @logger.debug("Register new listener for element: #{@get_element}", @logger.view)
    @_listeners.push(clb)

  # compile function
  # @param [Array] with arguments, which pass into transform function
  # By default transform function take arguments and return it `(x) -> x`
  # @return [Sirius.View]
  render: (args...) ->
    @logger.debug("Call render for #{args}", @logger.view)
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

  # @see #on method
  for_me: (event_name, custom_event_name, params...) ->
    @on(@get_element(), event_name, custom_event_name, params...)

  get_attr: (attr) ->
    e = @get_element()
    Sirius.Application.get_adapter().and_then (adapter) ->
      adapter.get_attr(e, attr)


  # check if strategy valid
  # @param [String] - given strategy
  # @return [Boolean]
  @is_valid_strategy: (s) ->
    @_Strategies.filter((arr) -> arr[0] == s).length != 0

  bind: (output, via) ->
    @pipe(output, via)

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



