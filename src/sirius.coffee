# Redirect to given url.
# @method .Sirius.redirect(url)
# @example
#   Controller =
#     action: (params) ->
#        if (params.length == 0)
#          redirect("/") //redirect to root url
#        else
#          //code
#     }
#
Sirius.redirect = (url) ->
  app = Sirius.Application
  app.logger.info("Redirect to #{url}", app.logger.redirect)

  if app.use_hash_routing_for_old_browsers && !app.push_state_support
    url = if url.indexOf("#") == 0
      url
    else
      if url.indexOf("/") == 0
        "\##{url}"
      else
        "\#/#{url}"


  if url.indexOf("#") == 0
    if app.push_state_support
      location.replace(url)
  else
    if app.push_state_support
      Sirius.Internal.RouteSystem.dispatch.call(null, {type: 'redirect', target: {href: url}})

# @private
# Class for map urls.
#
# Also it's class contain extracted parts from url.
# ### Url syntax:
# ```coffee
# #/:param1/:param2   => extract param1, param2 ...
# #/[0-9]+            => extract param, which satisfy given regexp
# #/start/*           => extract all after /start/
# ```
class Sirius.Internal.RoutePart
  constructor: (route) ->
    @end   = yes  # when route have a end (ends with `*`)
    @start = null #not used ...
    @parts = []
    @args  = []
    # #/abc/dsa/ => ["#", "abc", "dsa"] or ["", "abc", "dsa"]
    parts = route.replace(/\/$/, "").split("/")
    parts[0] = "#" if parts[0] == "" # hack
    # mark, this route not have a length and end
    #  #/title/id/*
    # matched with #/title/id/2014 and #/title/id/2014/2020 ...
    @end   = no if parts[parts.length - 1] == "*"

    @parts = parts[0..-1]

  #
  # Check if given url equal `parts` url
  #
  # When return true, then `args` contain extracted arguments:
  # @example
  #   var rp = new Sirius.Internal.RoutePart("#/post/:title")
  #   rp.match("#/abc") // => false
  #   rp.args          // => []
  #   rp.match("#/post/my-post-title") // => true
  #   rp.args                          // => ["my-post-title"]
  #
  #
  # @param url [String] - given url
  # @return [Boolean] true if matched, otherwise - return false
  match: (url) ->
    @args = []
    parts = url.replace(/\/$/, "").split("/")

    parts[0] = "#" if parts[0] == ""

    #when not end, and parts have a different length, this not the same routes
    return false if ((parts.length != @parts.length) && @end)
    #when it have a different length, but @parts len > given len
    return false if (@parts.length > 1) && parts.length < @parts.length

    is_named_part = (part) ->
      part.indexOf(":") == 0

    is_regexp_part = (part) ->
      part.indexOf("[") == 0

    is_end_part = (part) ->
      part.indexOf("*") == 0

    i = -1
    # protect
    args = []
    while i < 10
      i++
      [cp, gp] = [@parts[i], parts[i]]
      break if !cp || !gp
      if is_named_part(cp)
        args.push(parts[i])
        continue
      if is_regexp_part(cp)
        r = new RegExp("^#{cp}$")
        return false if !r.test(gp)
        args.push(r.exec(gp)[0])
        continue
      if is_end_part(cp)
        args = args.concat(parts[i..-1])
        break
      if cp != gp
        return false

    @args = args

    true


# @private
# Helper class, which check object for route, and have a methods, which used as event listener.
# @example
#   "#/my-route" : { controller: Controller, action: "action", before: "before", after: "after", guard: "guard", "data" : ["data"] }
#
class Sirius.Internal.ControlFlow

  # @param params  [Object] - object from route
  # @param wrapper [Function] - wrap action in this function, used for shared helpers between all controllers
  # `params` is a object with have a next keys `controller`, `action`, `before`, `after`, `data`, `guard`.
  # @note `controller` required
  # @note `action` required
  # @note `before`must be a string, where string is a method from `controller` or function
  # @note `after` must be a string, where string is a method from `controller` or function
  # @note `guard` must be a string, where string is a method from `controller` or function
  # @note you might create in controller method with name: `before_x`,
  # where `x` you action, then you may not specify `before` into params,
  # it automatically find and assigned as `before` method, the same for `after` and `guard`
  # @note `data` must be a string, or array of string
  constructor: (params, wrapper = (x) -> x) ->
    @logger = Sirius.Application.get_logger(@constructor.name)
    controller = params['controller'] || throw new Error("Params must contain a Controller")

    act = params['action']

    action = if Sirius.Utils.is_string(act)
      controller[act]
    else if Sirius.Utils.is_function(act)
      act
    else
      msg = "Action must be string or function"
      @logger.error("ControlFlow: #{msg}", @logger.routing)
      throw new Error(msg)
    if !action
      msg = "action #{act} not found in controller #{controller}"
      @logger.error("ControlFlow: #{msg}", @logger.routing)
      throw new Error(msg)

    @action = wrapper(action)

    extract = (property, is_guard = false) ->
      p = params[property]
      k = controller["#{property}_#{act}"]
      err = (a) ->
        new Error("#{a} action must be string or function")

      if Sirius.Utils.is_string(p)
        t = controller[p]
        throw err(Sirius.Utils.camelize(property)) if !Sirius.Utils.is_function(t)
        t
      else if Sirius.Utils.is_function(p)
        p
      else if p
        throw err(Sirius.Utils.camelize(property))
      else if k
        throw err(Sirius.Utils.camelize(property)) if !Sirius.Utils.is_function(k)
        k
      else
        if !is_guard
          ->
        else
          null

    @before = extract('before')
    @after  = extract('after')
    @guard  = extract('guard', true)

    @data = params['data'] || null
    @controller = controller

    return


  # @param e [EventObject|null] - event object if it's a mouse\key events, and `null` when it's url change event
  # @param args [Array<Any>] - arguments, used only for url changes events
  #
  # @note if you have a guard function, then firstly called it, if `guard` is true, then will be called `before`, `action` and `after` methods
  #
  handle_event: (e, args...) ->
    #when e defined it's a Event, otherwise it's call from url_routes
    # not need call for CustomEvent
    @logger.debug("ControlFlow: Start event processing", @logger.routing)
    if e
      data   = if Sirius.Utils.is_array(@data) then @data else if @data then [@data] else []
      result   = Sirius.Application.adapter.get_property(e, data) #FIXME use Promise

      merge  = [].concat([], [e], result)
      # fix bug#4 when event is a custom event we should get an args for this event
      merge  = [].concat([], merge, args...)
      if @guard
        if @guard.apply(@controller, merge)
          @before.apply(@controller)
          @action.apply(@controller, merge)
          @after.apply(@controller)
      else
        @before.apply(@controller)
        @action.apply(@controller, merge)
        @after.apply(@controller)
    else
      args = [].concat.apply([], args)
      if @guard
        if @guard.apply(@controller, args)
          @before.apply(@controller)
          @action.apply(@controller, args)
          @after.apply(@controller)
      else
        @before.apply(@controller)
        @action.apply(@controller, args)
        @after.apply(@controller)

  # the same as handle_event but for scheduler
  # @note if you have a guard function, then firstly called it, if `guard` is true, then will be called `before`, `action` and `after` methods
  #
  tick: () ->
    @logger.debug("ControlFlow: tick", @logger.routing)
    if @guard
      if @guard.apply(@controller)
        @before.apply(@controller)
        @action.apply(@controller)
        @after.apply(@controller)
    else
      @before.apply(@controller)
      @action.apply(@controller)
      @after.apply(@controller)



# @mixin
# @private
# Object, for creating event listeners
Sirius.Internal.RouteSystem =

  _every: "every"
  _scheduler: "scheduler"
  _once: "once"

  _selector: "a:not([href^='#'])"

  _is_hash_route: (url) ->
    url.toString().indexOf("#") == 0

  _is_404_route: (url) ->
    url.toString() == "404"

  _is_plain_route: (url) ->
    url.toString().indexOf("/") == 0

  _is_scheduler_command: (url) ->
    url.lastIndexOf(@_scheduler) == 0 ||
    url.lastIndexOf(@_once) == 0 ||
    url.lastIndexOf(@_every) == 0

  _is_event_route: (url) ->
    !@_is_hash_route(url) &&
    !@_is_404_route(url) &&
    !@_is_plain_route(url) &&
    !@_is_scheduler_command(url)

  _get_time_unit: (url, unit) ->
    result = unit.match(/^(\d+)(ms|s|m)/)
    if result
      num = parseInt(result[1], 10)
      t_unit = result[2] || "s"

      if t_unit == "ms"
        num
      else if t_unit == "s"
        num * 1000
      else
        num * 60000

    else
      throw new Error("Bad time unit: #{unit} in #{url}, available units: 'ms', 's', 'm'")

  _get_scheduler_params: (url) ->
    xs = url.split(" ")
    e = "Define time unit for scheduler, for example: 'every 10s', given: #{url}"
    if xs.length == 1
      throw new Error(e)
    else if xs.length == 2
      time_param = Sirius.Internal.RouteSystem._get_time_unit(url, xs[1])
      {
        'delay': null,
        'time': time_param
      }

    else if xs.length == 3
      time_param = Sirius.Internal.RouteSystem._get_time_unit(url, xs[1])
      time_param1 = Sirius.Internal.RouteSystem._get_time_unit(url, xs[2])
      {
        'delay': time_param
        'time': time_param1
      }
    else
      throw new Error(e)

  _scheduler_register: (routes, wrapper, adapter, logger) ->
    every = @_every
    scheduler = @_scheduler
    once = @_once
    f = @_get_scheduler_params
    for url, action of routes when @_is_scheduler_command(url)
      do(url, action) ->
        handler = if Sirius.Utils.is_function(action)
          wrapper(action)
        else
          () ->
            (new Sirius.Internal.ControlFlow(action, wrapper)).tick()

        units = f(url)

        logger.debug("Define scheduler for '#{url}' with #{JSON.stringify(units)}", logger.routing)

        if url.lastIndexOf(every) == 0 || url.lastIndexOf(scheduler) == 0
          if units.delay == null
            setInterval(handler, units.time)
          else
            setTimeout(
              () -> setInterval(handler, units.time)
              units.delay
            )
        else
          if units.delay == null
            setTimeout(handler, units.time)
          else
            setTimeout(
              () -> setTimeout(handler, units.time)
              units.delay
            )



  _event_register: (routes, wrapper, adapter, logger) ->
    for url, action of routes when @_is_event_route(url)
      do(url, action) ->
        handler = if Sirius.Utils.is_function(action)
          wrapper(action)
        else
          (e, params...) ->
            (new Sirius.Internal.ControlFlow(action, wrapper)).handle_event(e, params)

        z = url.match(/^([a-zA-Z:]+)(\s+)?(.*)?/)
        event_name = z[1]
        selector   = z[3] || document #when it a custom event: 'custom:event' for example
        adapter.bind(document, selector, event_name, handler)
        logger.debug("RouteSystem: define event route: '#{event_name}' for '#{selector}'", logger.routing)

  _get_hash_routes: (routes, wrapper, adapter, logger) ->
    for url, action of routes when @_is_hash_route(url)
      logger.info("RouteSystem: define hash route: '#{url}'", logger.routing)
      url    = new Sirius.Internal.RoutePart(url)
      action = if Sirius.Utils.is_function(action)
        wrapper(action)
      else
        new Sirius.Internal.ControlFlow(action, wrapper)
      [url, action]

  _get_plain_routes: (routes, wrapper, adapter, logger) ->
    for url, action of routes when @_is_plain_route(url)
      logger.debug("RouteSystem: define route: '#{url}'", logger.routing)
      url    = new Sirius.Internal.RoutePart(url)
      action = if Sirius.Utils.is_function(action)
        wrapper(action)
      else
        new Sirius.Internal.ControlFlow(action, wrapper)
      [url, action]

  # @param routes [Object] object with routes
  # @param fn [Function] callback, which will be called, after routes will be defined
  # @event application:urlchange - generate, when url change
  # @event application:404 - generate, if given url not matched defined routes
  # @event application:run - generate, after application running
  # setting : old, top, support
  create: (routes, setting, fn = ->) ->
    logger = Sirius.Application.get_logger(@constructor.name)
    current = prev = window.location.hash
    redirect_to_hash   = setting["old"]
    push_state_support = setting["support"]
    ignore_not_matched_urls = setting['ignore']

    Sirius.Application.get_adapter().and_then (adapter) =>
      if redirect_to_hash and !push_state_support
        logger.info("RouteSystem: Convert plain routing into hash routing")
        # convert to new routing
        urls = [] #save urls into array, for check collision
        route = {}
        for url, action of routes
          urls.push(url) if @_is_hash_route(url)
          if @_is_plain_route(url)
            url = "\##{url}"
            if urls.indexOf(url) != -1
              logger.warn("RouteSystem: Routes already defined '#{url}' url")
          route[url] = action
        routes = route


      # wrap all controller actions
      wrapper = (fn) ->
        for key, value of Sirius.Application.controller_wrapper
          @[key] = value

        fn

      # set routing by event
      @_event_register(routes, wrapper, adapter, logger)

      # scheduler
      @_scheduler_register(routes, wrapper, adapter, logger)

      # for cache change obj[k, v] to array [[k,v]]
      array_of_routes = @_get_hash_routes(routes, wrapper, adapter, logger)

      plain_routes = @_get_plain_routes(routes, wrapper, adapter, logger)

      _prevent_default = (e) ->
        if e.preventDefault
          e.preventDefault()
        else
          e.returnValue = false

      # optimize this function
      dispatcher = (e) ->
        prev        = current
        route_array = []
        result      = false
        is_hash_based_route = false

        logger.info("RouteSystem: start processing route: '#{current}'")

        if e.type == "hashchange"
          # hashchange
          route_array = array_of_routes
          current = window.location.hash
          origin = window.location.origin
          is_hash_based_route = true

          if push_state_support
            history.pushState({href: current}, "#{current}", "#{origin}/#{current}")
          else
            history.replaceState({href: current}, "#{current}", "#{origin}/#{current}")
        else # e.type : click or popstate
          # plain
          route_array = plain_routes
          href = e.target.href # TODO the same for hashchange
          # need save history only for 'click' event
          if e.type != "popstate" && push_state_support
            history.pushState({href: href}, "#{href}", href)

          pathname = window.location.pathname
          pathname = "/" if pathname == ""

          current = pathname

        for part in route_array
          f = part[0]
          r = f.match(current)
          if r && !result
            result = true
            flow = part[1]

            if flow.handle_event
              flow.handle_event(null, f.args)
            else
              flow.apply(null, f.args)

        if !result
          if ignore_not_matched_urls
            if is_hash_based_route
              logger.warn("Seems you ignore hash based urls: #{current}")

            logger.debug("ignore_not_matched_urls is enabled, url was not matched: '#{current}'")
            return

          else
            logger.warn("RouteSystem: route '#{current}' not found. Generate 404 event")
            adapter.fire(document, "application:404", current, prev)
            r404 = routes['404'] || routes[404]
            if r404
              if Sirius.Utils.is_function(r404)
                wrapper(r404)(current)
              else
                (new Sirius.Internal.ControlFlow(r404, wrapper)).handle_event(null, current)

            _prevent_default(e)
            return
        else
          _prevent_default(e)

        logger.debug("RouteSystem: Url change to: #{current}")
        adapter.fire(document, "application:urlchange", current, prev)


        return

      @dispatch = dispatcher

      if plain_routes.length != 0
        # bind all <a> element with dispatch function, but bind only when href not contain "#"
        adapter.bind document, @_selector, "click", dispatcher

      window.onhashchange = dispatcher
      if push_state_support
        adapter.bind window, null, "popstate", (e) ->
          # should run only for plain routes, not for hash based!
          # history.state.href contain url which start from "#", when hash change
          #                    contain full address otherwise
          # also when we visit from plain url to hash, then history.state is null
          if history and history.state?
            if history.state.href != undefined
              if history.state.href.indexOf("#") != 0
                dispatcher(e)


      fn()

# @mixin
# A main object, it's a start point all user applications
# @example
#   var routes = {
#     "#/"                : { controller : Controller, action: "action" },
#     "application: run"  : { controller : Controller, action: "run" },
#     "click #my-element" : { controller : Controller, action: "click_action"}
#   }
#   my_logger = function(level, log_source, msg) { console.log("Log: " + msg); }
#
#   Sirius.Application.run({
#     route : routes,
#     log_to: my_logger,
#     enable_logging: true,
#     start: "#/"
#   });
#
Sirius.Application =
  ###
    disable or enable logs
  ###
  enable_logging: Sirius.Logger.Default.enable_logging

  ###
    Minimum log level.
    Default is: `debug`
    Available options: debug, info, warn, error
  ###
  minimum_log_level: Sirius.Logger.Default.minimum_log_level

  ###
    custom log implementation

    @param [String] - log level: [DEBUG, INFO, WARN, ERROR]
    @param [String] - log source information from the framework or user controller, or whatever
    @param msg [String] - message
  ###
  log_to: Sirius.Logger.Default.default_log_function

  ###
    application adapter for javascript frameworks @see Adapter documentation
  ###
  adapter: null
  ###
    true, when application already running
  ###
  running: false
  ###
    user routes
  ###
  route: {}
  ###
    a root url for application
  ###
  start : false

  ###
    a shared methods for controllers
  ###
  controller_wrapper: {
    redirect: Sirius.redirect
  }

  ###
    when true, then all routing will be redefined with hash based routing
    and convert all url href to hash based urls
    "/" => "#/"
    <a href="/posts">posts</a>
    to
    <a href="#/posts">posts</a>
  ###
  use_hash_routing_for_old_browsers : true

  ###
    if true, then if your click on some url it's used browser for redirect to url
    if false, generate 'application:404' event
  ###
  ignore_not_matched_urls: true

  # @private
  _wait: []

  #
  # @return [Object] - promise, which will be use for log information
  get_logger: (log_source) ->
    Sirius.Logger.build(log_source)

  #
  # @return [Function] - promise, when adapter not null then it function will be called
  get_adapter: () ->
    if !@adapter?
      p = new Sirius.Promise()
      @_wait.push(p)
      p
    else
      new Sirius.Promise(@adapter)

  #
  # @method #run(options)
  # @param options [Object] - base options for application
  run: (options = {}) ->
    @_initialize(options)
    return

  _initialize: (options) ->
    # configure logging
    Sirius.Logger.Configuration.configure(options)

    logger = new Sirius.Logger("Sirius.Application")

    # especial for sirius-core where these modules are not available
    if Sirius.BaseModel
      Sirius.BaseModel._run_base_model_validator_registration()

    if Sirius.View
      Sirius.View._run_view_strategy_registration()

    _get_key_or_default = (k, _default) ->
      if options[k]?
        options[k]
      else
        _default

    @running = true
    @adapter = options["adapter"] || new VanillaJsAdapter()
    @route   = options["route"]   || @route
    @ignore_not_matched_urls = _get_key_or_default('ignore_not_matched_urls', @ignore_not_matched_urls)

    @start   = options["start"] || @start

    for key, value of (options["controller_wrapper"] || {})
      @controller_wrapper[key] = value

    @hash_always_on_top = _get_key_or_default('hash_always_on_top', @hash_always_on_top)

    @use_hash_routing_for_old_browsers = _get_key_or_default("use_hash_routing_for_old_browsers",
      @use_hash_routing_for_old_browsers)

    logger.info("Logger enabled? #{Sirius.Logger.Configuration.enable_logging}")
    logger.info("Minimum log level: #{Sirius.Logger.Configuration.minimum_log_level.get_value()}")
    logger.info("Adapter: #{@adapter.name}")
    logger.info("Use hash routing for old browsers: #{@use_hash_routing_for_old_browsers}")
    logger.info("Current browser: #{navigator.userAgent}")
    logger.info("Ignore not matched urls: #{@ignore_not_matched_urls}")

    @push_state_support = history.pushState
    logger.info("History pushState support: #{@push_state_support}")

    if !@push_state_support && @use_hash_routing_for_old_browsers
      logger.warn("You browser does not support pushState, and you disabled hash routing for old browser")

    setting =
      old: @use_hash_routing_for_old_browsers
      support: @push_state_support
      ignore: @ignore_not_matched_urls

    # start
    Sirius.Internal.RouteSystem.create @route, setting, () =>
      for p in @_wait
        p.set_value(@adapter)
      @adapter.fire(document, "application:run", new Date())

    if @start
      Sirius.redirect(@start)



