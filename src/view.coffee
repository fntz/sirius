
# Views representation for an Application
# Fluent interface for manipulating views
# From high-view views are wrapper around html-document with a few convenient methods
#
# @note By default the function mark elements with id
#
# @example:
#
#   myView = new Sirius.View("body", (content) -> "<div>#{content}</div>"
#   # in a controller
#   myView.render(results_from_ajax_to_html).swap() # change body content
#
#   myView.clear().render('results')
#   myListView.render("<li>new element</li>").append()
#   myTableView.render("<tr><td>top</td></tr>").prepend()
#
class Sirius.View

  name: () -> 'View' # define name, because `constructor.name` does not works in IE

  # contain all strategies for view
  @_Strategies = []

  # do not call every time
  @_Strategies_Is_Logged = false

  @_Cache = [] # cache for all views

  # @private
  class EventHandlerParams
    constructor: (@selector, @event_name, @custom_event_name) ->

    eq: (another) ->
      @selector == another.selector and
      @event_name == another.event_name and
      # last argument should be a function
      @custom_event_name.toString == another.custom_event_name.toString

  # @param [String]   - selector for element
  # @param [Function] - transform function for new content
  #
  constructor: (@element, @clb = (txt) -> txt) ->
    element = @element
    clb = @clb

    # one per on element
    view = Sirius.View._Cache.filter (v) ->
      v.element == element && "#{v.clb}" == "#{clb}"

    if view.length != 0
      return view[0]

    @_listeners = []

    @_cache_event_handlers = []
    @logger = Sirius.Application.get_logger("Sirius.View[{#{@get_element()}]")
    @_result_fn = (args...) ->
      clb.apply(null, args...)
    @logger.debug("Create a new View for #{@element}")


    for strategy in @constructor._Strategies
      do(strategy) =>
        [name, transform, render] = strategy
        unless @constructor._Strategies_Is_Logged
          @logger.debug("Define '#{name}' strategy")
        @constructor._Strategies_Is_Logged = true
        @[name] = (attribute = "text") =>
          # @render already called
          # and we have @_result
          result = @_result
          element = @element
          # TODO get element identifier or toString somehow
          @logger.debug("Start processing strategy for the #{element}")
          Sirius.Application.get_adapter().and_then (adapter) ->
            # need extract old value
            oldvalue = if attribute is 'text'
              adapter.text(element)
            else
              adapter.get_attr(element, attribute)
            res = transform(oldvalue, result)
            render(adapter, element, res, attribute)

    Sirius.View._Cache.push(@)
    return @

  get_element: () ->
    @element

  # internal method for binding only
  # @private
  # @nodoc
  _register_state_listener: (listener) ->
    @logger.debug("Register new listener '#{listener.name}'")
    @_listeners.push(listener)

  # @private
  # @nodoc
  _unregister_state_listener: (name) ->
    @logger.debug("Unregister listener '#{name}'")
    xs = @_listeners.filter ((x) -> x.name == name)
    @_listeners = @_listeners.filter ((x) -> x.name != name)
    xs


  # compile function
  # @param [Array] of arguments, which will be passed into `transform` function
  # By default transform function take arguments and return it `(x) -> x` (identity)
  # @return [Sirius.View]
  render: (args...) ->
    @logger.debug("Call render for #{args}")
    @_result = @_result_fn(args)
    @

  #
  # call strategy on an inner element
  # @param [String] - inner element selector
  # @example
  #   //coffee
  #   # <div id="some-view"><span class="inner-element"></span>
  #   v = new Sirius.View("#some-view")
  #   v.render("new-class").zoom(".inner-element").swap('class')
  #
  #   # result is:
  #   # <div id="some-view"><span class="new-class"></span>
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
  # @param [String] - custom event name, which will be fired on the event name
  # @param [Array]  - arguments will be pass into method for custom event name
  # @note  First parameter for bind method is a Custom Event
  # @note  Second parameter for bind method is an Original Event
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
  #         # your code
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
      throw new Error("View: 'custom_event_name' must be string or function, '#{typeof(custom_event_name)}' given")

    current = new EventHandlerParams(selector, event_name, custom_event_name)

    is_present = @_cache_event_handlers.filter (x) ->
      x.eq(current)

    if is_present.length == 0

      # TODO possible rebind ?
      @logger.info("Bind event for #{selector}, event name: #{event_name}, will be called : #{custom_event_name}")

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
        adapter.off(selector, event_name, f.custom_event_name)
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
    logger = Sirius.Application.get_logger("Sirius.View.Static")
    logger.info("View: Register new Strategy #{name}")
    transform = object.transform
    render = object.render
    if !Sirius.Utils.is_function(transform)
      msg = "Strategy 'transform' must be a function, but #{typeof transform} given"
      logger.error("View: #{msg}")
      throw new Error(msg)

    if !Sirius.Utils.is_function(render)
      msg = "Strategy 'render' must be a function, but #{typeof render} given"
      logger.error("View: #{msg}")
      throw new Error(msg)

    if !Sirius.Utils.is_string(name)
      msg = "Strategy 'name' must be a string, but #{typeof name} given"
      logger.error("View: #{msg}")
      throw new Error(msg)

    @_Strategies.push([name, transform, render])
    null

  # @private
  # @nodoc
  @_run_view_strategy_registration: () ->
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

            adapter.set_attr(element, 'checked', r)
          else
            adapter.set_attr(element, attribute, result)
    )

    Sirius.View.register_strategy('append',
      transform: (oldvalue, newvalue) -> newvalue
      render: (adapter, element, result, attribute) ->
        tag = adapter.get_attr(element, 'tagName')
        if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
          throw new Error("'append' strategy does not work for `input` or `textarea` or `select` elements")

        if attribute == 'text'
          adapter.append(element, result)
        else
          throw new Error("Strategy 'append' works only for 'text' content, your call with attribute:'#{attribute}'")
    )

    Sirius.View.register_strategy('prepend',
      transform: (oldvalue, newvalue) -> newvalue
      render: (adapter, element, result, attribute) ->
        tag = adapter.get_attr(element, 'tagName')
        if tag == "INPUT" || tag == "TEXTAREA" || tag == "SELECT"
          throw new Error("'prepend' strategy does not work for `input` or `textarea` or `select` elements")

        if attribute == 'text'
          adapter.prepend(element, result)
        else
          throw new Error("Strategy 'prepend' works only for 'text' content, your call with attribute:'#{attribute}'")
    )

    Sirius.View.register_strategy('clear',
      transform: (oldvalue, newvalue) -> ""
      render: (adapter, element, result, attribute) ->
        adapter.clear(element)
    )


Sirius.View._run_view_strategy_registration()
