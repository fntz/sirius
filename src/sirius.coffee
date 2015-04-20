# Redirect to given url.
# @method .Sirius.redirect(url)
# @example
#   var Controller =
#     action : (params) ->
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
      Sirius.RouteSystem.dispatch.call(null, {type: 'redirect', target: {href: url}})

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
class Sirius.RoutePart
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
  #   var rp = new Sirius.RoutePart("#/post/:title")
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
        r = new RegExp("^#{cp}$");
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
# Helper class, which check object for route, and have a method, which used as event listener.
# @example
#   "#/my-route" : { controller: Controller, action: "action", before: "before", after: "after", guard: "guard", "data" : ["data"] }
#
class Sirius.ControlFlow

  # @param params  [Object] - object from route
  # @param wrapper [Function] - wrap action in this function, used for shared helpers between all controllers
  # `params` is a object with have a next keys `controller`, `action`, `before`, `after`, `data`, `guard`.
  # @note `controller` required
  # @note `action` required
  # @note `before`must be a string, where string is a method from `controller` or function
  # @note `after` must be a string, where string is a method from `controller` or function
  # @note `guard` must be a string, where string is a method from `controller` or function
  # @note you might create in controller method with name: `before_x`, where `x` you action, then you may not specify `before` into params, it automatically find and assigned as `before` method, the same for `after` and `guard`
  # @note `data` must be a string, or array of string
  constructor: (params, wrapper = (x) -> x) ->
    @logger = Sirius.Application.get_logger()
    controller = params['controller'] || throw new Error("Params must contain a Controller")

    act = params['action']

    action = if Sirius.Utils.is_string(act)
                controller[act]
              else if Sirius.Utils.is_function(act)
                act
              else
                msg = "Action must be string or function"
                @logger.error("ControlFlow: #{msg}", @logger.control_flow)
                throw new Error(msg)
    if !action
      msg = "action #{act} not found in controller #{controller}"
      @logger.error("ControlFlow: #{msg}", @logger.control_flow)
      throw new Error(msg)

    @action = wrapper(action)

    extract = (property, is_guard = false) =>
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
    @logger.info("ControlFlow: Start event processing", @logger.control_flow)
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

# @mixin
# @private
# Object, for creating event listeners
Sirius.RouteSystem =

  _selector: "a:not([href^='#'])"
  _hash_selector: "a[href^='#']"

  _hash_route: (url) ->
    url.toString().indexOf("#") == 0

  _404_route: (url) ->
    url.toString() == "404"

  _plain_route: (url) ->
    url.toString().indexOf("/") == 0

  _event_route: (url) ->
    !@_hash_route(url) && !@_404_route(url) && !@_plain_route(url)

  _event_register: (routes, wrapper, adapter, logger) ->
    for url, action of routes when @_event_route(url)
      do(url, action) ->
        handler = if Sirius.Utils.is_function(action)
          wrapper(action)
        else
          (e, params...) ->
            (new Sirius.ControlFlow(action, wrapper)).handle_event(e, params)

        z = url.match(/^([a-zA-Z:]+)(\s+)?(.*)?/)
        event_name = z[1]
        selector   = z[3] || document #when it a custom event: 'custom:event' for example
        adapter.bind(document, selector, event_name, handler)
        logger.info("RouteSystem: define event route: '#{event_name}' for '#{selector}'", logger.route_system)

  _get_hash_routes: (routes, wrapper, adapter, logger) ->
    for url, action of routes when @_hash_route(url)
      logger.info("RouteSystem: define hash route: '#{url}'", logger.route_system)
      url    = new Sirius.RoutePart(url)
      action = if Sirius.Utils.is_function(action)
        wrapper(action)
      else
        new Sirius.ControlFlow(action, wrapper)
      [url, action]

  _get_plain_routes: (routes, wrapper, adapter, logger) ->
    for url, action of routes when @_plain_route(url)
      logger.info("RouteSystem: define route: '#{url}'", logger.route_system)
      url    = new Sirius.RoutePart(url)
      action = if Sirius.Utils.is_function(action)
        wrapper(action)
      else
        new Sirius.ControlFlow(action, wrapper)
      [url, action]
#
  # @param routes [Object] object with routes
  # @param fn [Function] callback, which will be called, after routes will be defined
  # @event application:urlchange - generate, when url change
  # @event application:404 - generate, if given url not matched with given routes
  # @event application:run - generate, after application running
  # setting : old, top, support
  create: (routes, setting, fn = ->) ->
    logger = Sirius.Application.get_logger()
    current = prev = window.location.hash
    hash_on_top        = setting["top"]
    redirect_to_hash   = setting["old"]
    push_state_support = setting["support"]

    Sirius.Application.get_adapter().and_then (adapter) =>
      if redirect_to_hash and !push_state_support
        logger.info("RouteSystem: Convert plain routing into hash routing", logger.route_system)
        # convert to new routing
        urls = [] #save urls into array, for check collision
        route = {}
        for url, action of routes
          urls.push(url) if @_hash_route(url)
          if @_plain_route(url)
            url = "\##{url}"
            if urls.indexOf(url) != -1
              logger.warn("RouteSystem: Routes already have '#{url}' url", logger.route_system)
          route[url] = action
        routes = route


      # wrap all controller actions
      wrapper = (fn) ->
        for key, value of Sirius.Application.controller_wrapper
          @[key] = value

        fn

      # set routing by event
      @_event_register(routes, wrapper, adapter, logger)

      # for cache change obj[k, v] to array [[k,v]]
      array_of_routes = @_get_hash_routes(routes, wrapper, adapter, logger)

      plain_routes = @_get_plain_routes(routes, wrapper, adapter, logger)

      # optimize this function
      dispatcher = (e) ->
        prev        = current
        route_array = []
        result      = false

        logger.info("RouteSystem: start processing route: '#{current}'", logger.route_system)

        if e.type == "hashchange"
          # hashchange
          route_array = array_of_routes
          current = window.location.hash
          origin = window.location.origin
          if push_state_support
            history.pushState({href: current}, "#{current}", "#{origin}/#{current}")
          else
            history.replaceState({href: current}, "#{current}", "#{origin}/#{current}")
        else # e.type : click or popstate
          # plain
          route_array = plain_routes
          href = e.target.href # TODO the same for hashchange
          # need save history only for 'click' event
          if e.type != "popstate"
            history.pushState({href: href}, "#{href}", href) if push_state_support
          pathname = window.location.pathname
          pathname = "/" if pathname == ""
          if e.preventDefault
            e.preventDefault()
          else
            e.returnValue = false
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
          logger.warn("RouteSystem: route '#{current}' not found. Generate 404 event", logger.route_system)
          adapter.fire(document, "application:404", current, prev)
          r404 = routes['404'] || routes[404]
          if r404
            if Sirius.Utils.is_function(r404)
              wrapper(r404)(current)
            else
              (new Sirius.ControlFlow(r404, wrapper)).handle_event(null, current)
          return

        logger.info("RouteSystem: Url change to: #{current}", logger.route_system)
        adapter.fire(document, "application:urlchange", current, prev)


        return

      @dispatch = dispatcher

      # need convert all plain url into hash based url
      # convert only when
      links = adapter.all(@_selector)
      if redirect_to_hash && !push_state_support
        logger.info("RouteSystem: Found #{links.length} link. Convert href into hash based routing", logger.route_system)
        for link in links
          href = link.getAttribute('href')
          if href.indexOf("http") == -1
            new_href = if href.indexOf("/") == 0
              "\##{href}"
            else
              "\#/#{href}"
            logger.info("RouteSystem: Convert '#{href}' -> '#{new_href}'", logger.route_system)
            link.setAttribute('href', new_href)

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



      if array_of_routes.length != 0 && plain_routes.length != 0
        logger.warn("RouteSystem: Seems you use plain routing and hashbased routing at the same time", logger.route_system)

      fn()


# @mixin
# A main object, it's a start point all user applications
# @example
#   var routes = {
#     "#/"                : { controller : Controller, action: "action" },
#     "application: run"  : { controller : Controller, action: "run" },
#     "click #my-element" : { controller : Controller, action: "click_action"}
#   }
#   my_logger = function(msg) { console.log("Log: " + msg); }
#
#   Sirius.Application.run({ route : routes, logger: my_logger, log: true, start: "#/" });
#
Sirius.Application =
  ###
    when true, logs will be written
  ###
  log: false
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
    add logger into controller wrapper
  ###
  mix_logger_into_controller: true

  ###
    when, false, then hash will be add into last for url, for true, no
    false:
      "http://example.com/" - start
      "http://example.com/another" - change to another url
      "http://example.com/another#hash" - change to hash
    true
      "http://example.com/" - start
      "http://example.com/another" - change to another url
      "http://example.com/#/hash" - change to hash
  ###
  hash_always_on_top : true

  ###
    when true, then all routing will be redefined with hash based routing
    and convert all url href to hash based urls
    "/" => "#/"
    <a href="/posts">posts</a>
    to
    <a href="#/posts">posts</a>
  ###
  use_hash_routing_for_old_browsers : true

  #
  # @method #logger(msg) - logger, default it's write message to console.log, may be redefined
  # @param [String] - log level: [DEBUG, INFO, WARN, ERROR]
  # @param msg [String] - message
  default_log_function: (level, msg) ->
    if console && console.log
      console.log "#{level}: #{msg}"
    else
      alert "Not supported `console`. You should define own `logger` function for Sirius.Application"

  ###
   Array with classes for logs
   Possible classes:
      BaseModel   = 0
      BindHelper  = 1
      Collection  = 2
      Observer    = 3
      View        = 4
      RouteSystem = 5
      ControlFlow = 6
      Application = 7
      Redirect    = 8
      Validator   = 9

   Use as:

    ```
       log_filters : [0, 1, 2]
       # or
       lf = Sirius.Logger.Location
       log_filters : [lf.BaseModel, lf.Application, lf.View]
       # or
       log_filters : ['BaseModel', 'Application', 'View']
    ```
    @note If you use Sirius.Logger in you controller, not need define this controller for filters.
  Just use it.
    @note empty array eq without filter (log all)
  ###
  log_filters: []

  # @private
  _wait: []

  _messages_queue: []
  #
  # @return [Object] - promise, which will be use for log information
  get_logger: () ->
    if !@logger
      lvls = Sirius.Logger.Levels
      o = {}
      q = @_messages_queue
      for l in lvls
        do(l) ->
          o[l] = (msg, location) -> q.push([l, msg, location])
      o
    else
      @logger

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
    @running = true
    @log     = options["log"]     || @log
    @adapter = options["adapter"] || throw new Error("Specify adapter")
    @route   = options["route"]   || @route
    @mix_logger_into_controller = options['mix_logger_into_controller'] || @mix_logger_into_controller
    @log_filters = options["log_filters"] || @log_filters

    # check filters
    if @log_filters.length > 0
      lf = Sirius.Logger.Filters
      user_filter = @log_filters
      # when pass numbers
      if typeof(@log_filters[0]) == "number" #fixme check all collection
        max = user_filter.sort()[user_filter.length-1]
        min = user_filter.sort()[0]
        if min < 0
          throw new Error("Undefined index for log filters #{min}")
        if max > lf.length
          throw new Error("Undefined index for log filters #{max}")
        @log_filters = user_filter.map (index) -> lf[index]
      else
        xs = @log_filters.filter (x) -> lf.indexOf(x) == -1
        if xs.length != 0
         throw new Error("Check log filters given `#{user_filter}`. Allow #{lf}")
    else
      @log_filters = Sirius.Logger.Filters


    @logger  = new Sirius.Logger(@log, @log_filters, options['logger'] || @default_log_function)
    @start   = options["start"]   || @start


    for key, value of (options["controller_wrapper"] || {})
      @controller_wrapper[key] = value

    @hash_always_on_top = if options["hash_always_on_top"]?
                            options["hash_always_on_top"]
                          else
                            @hash_always_on_top

    @use_hash_routing_for_old_browsers = if options["use_hash_routing_for_old_browsers"]?
                                           options["use_hash_routing_for_old_browsers"]
                                         else
                                           @use_hash_routing_for_old_browsers

    @logger.info("Logger enabled? #{@log}", @logger.application)
    @logger.info("Log filters: #{@log_filters}", @logger.application)
    @logger.info("Adapter: #{Sirius.Utils.fn_name(@adapter.constructor)}", @logger.application)
    @logger.info("Hash always on top: #{@hash_always_on_top}", @logger.application)
    @logger.info("Use hash routing for old browsers: #{@use_hash_routing_for_old_browsers}", @logger.application)
    @logger.info("Current browser: #{navigator.userAgent}", @logger.application)

    @push_state_support = if history.pushState then true else false
    @logger.info("History pushState support: #{@push_state_support}", @logger.application)

    if !@push_state_support && @use_hash_routing_for_old_browsers
      @logger.warn("You browser not support pushState, and you disable hash routing for old browser", @logger.application)

    @logger.info("Mix logger in controllers #{@mix_logger_into_controller}", @logger.application)

    if @mix_logger_into_controller
      if @controller_wrapper['logger']
        throw new Error("Logger method already in `controller_wrapper`")
      l = @logger
      @controller_wrapper['logger'] = {
        info  : l.info
        debug : l.debug
        warn  : l.warn
        error : l.error
      }



    setting =
      old: @use_hash_routing_for_old_browsers
      top: @hash_always_on_top
      support: @push_state_support

    # start
    Sirius.RouteSystem.create @route, setting, () =>
      for p in @_wait
        p.set_value(@adapter)
      @adapter.fire(document, "application:run", new Date())
      for message in @_messages_queue
        @logger[message[0]].call(null, message[1], message[2])

    if @start
      Sirius.redirect(@start)



