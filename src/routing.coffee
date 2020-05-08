###
 Redirect to the given URL.
 @method .Sirius.redirect(url)
 @example
   Controller =
     action: (params) ->
        if (params.length == 0)
          redirect("/") //redirect to the root url
        else
          //code
     }
###
Sirius.redirect = (url) ->
  app = Sirius.Application
  app.get_logger("Redirect").info("Redirect to #{url}")

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

###
  @private
  @class
###
class Sirius.Internal.RouteMatchResult
  constructor: (@is_matched, @args) ->

  with_args: (args) ->
    @args = args
    @

  get_args: () ->
    @args || []

  is_success: () ->
    @is_matched

  success: () ->
    @is_matched = true
    @

  fail: () ->
    @is_matched = false
    @

###
 @private
 Class for mapping URLs.

 Also the class contains extracted parts from an url.
 @example
  /:param1/:param2   => will extract param1, param2 ...
  /[0-9]+            => will extract param, which satisfy given regexp
  /start/*           => will extract all after /start/
###
class Sirius.Internal.RoutePart
  constructor: (route) ->
    @original = route # save orininal for logging
    @is_end   = yes  # when route have an end (ends with `*`)
    @start = null #not used ...
    @parts = []
    # #/abc/dsa/ => ["#", "abc", "dsa"] or ["", "abc", "dsa"]
    parts = route.replace(/\/$/, "").split("/")
    parts[0] = "#" if parts[0] == "" # hack
    # mark, this route not have a length and end
    #  #/title/id/*
    # matched with #/title/id/2014 and #/title/id/2014/2020 ...
    @is_end   = no if parts[parts.length - 1] == "*"
    @parts = parts[0..-1]
    @logger = Sirius.Application.get_logger("Sirius.Internal.RoutePart##{@original}")

  @_is_named_part = (part) ->
    part.indexOf(":") == 0

  @_is_regexp_part = (part) ->
    part.indexOf("[") == 0

  @_is_end_part = (part) ->
    part.indexOf("*") == 0

  ###
    Check if given url is equal `parts` url
    @param url {String} - given url
    @return {Sirius.Internal.RouteMatchResult}

    When returns true, then `args` contain extracted arguments:
    @example
      var rp = new Sirius.Internal.RoutePart("#/post/:title")
      rp.match("#/abc") // => false
      rp.args          // => []
      rp.match("#/post/my-post-title") // => true
      rp.args                          // => ["my-post-title"]
  ###
  match: (url) ->
    @logger.debug("try to match: '#{url}'")
    result = new Sirius.Internal.RouteMatchResult(false, [])

    parts = url.replace(/\/$/, "").split("/")

    parts[0] = "#" if parts[0] == ""

    #when is not end, and parts have a different length, this not the same routes
    # todo end -> is_end
    if @is_end && (parts.length != @parts.length)
      return result.fail()

    #when it has the different lengths, but @parts len > given len
    if (@parts.length > 1) && parts.length < @parts.length
      return result.fail()

    i = -1
    # protect
    args = []
    while i < 10
      i++
      [cp, gp] = [@parts[i], parts[i]]
      break if !cp || !gp
      if Sirius.Internal.RoutePart._is_named_part(cp)
        args.push(parts[i])
        continue
      if Sirius.Internal.RoutePart._is_regexp_part(cp)
        r = new RegExp("^#{cp}$")
        return result.fail() if !r.test(gp)
        args.push(r.exec(gp)[0])
        continue
      if Sirius.Internal.RoutePart._is_end_part(cp)
        # tail
        args = args.concat(parts[i..-1])

        break
      if cp != gp
        return result.fail()

    result.with_args(args).success()


###
 @private
 Helper class, which checks an object for routing, and has methods, which will be used as event listener.
 @example
   "#/my-route" : { controller: Controller, action: "action", before: "before", after: "after", guard: "guard", "data" : ["data"] }
###
class Sirius.Internal.ControlFlow

  ###
   @param params  [Object] - is an object from a route
   @param wrapper [Function] - wrap an action in the function, it used for shared helpers between all controllers
   `params` is a object with have a next keys `controller`, `action`, `before`, `after`, `data`, `guard`.
   @note `controller` is required
   @note `action` is required
   @note `before`must be a string, where the string is a method from the `controller` or an function
   @note `after` must be a string, where the string is a method from the `controller` or an function
   @note `guard` must be a string, where the string is a method from the `controller` or an function
   @note you might create in the controller a method with a name: `before_x`,
   where `x` your an action, then you may not specify `before` into the params,
   it will be automatically find and assigned as a `before` method, the same for an `after` and an `guard`
   @note `data` must be a string, or an array of the strings
  ###
  constructor: (params, wrapper = (x) -> x) ->
    @logger = Sirius.Application.get_logger(@constructor.name)
    controller = params['controller'] || throw new Error("Params must contain a Controller definition")

    act = params['action']

    action = if Sirius.Utils.is_string(act)
      controller[act]
    else if Sirius.Utils.is_function(act)
      act
    else
      msg = "Action must be a string or a function"
      @logger.error(msg)
      throw new Error(msg)
    if !action
      msg = "The action '#{act}' was not found in the controller"
      @logger.error("ControlFlow: #{msg}")
      throw new Error(msg)

    @action = wrapper(action)

    extract = (property, is_guard = false) ->
      param = params[property] # in user definition (explicit)
      param_in_controller = controller["#{property}_#{act}"] # implicit in controller
      err = (a) ->
        new Error("The #{a} method must be a string or a function")

      if Sirius.Utils.is_string(param)
        # check that the controller has necessary attribute and that attribute is a function
        definition = controller[param]
        unless Sirius.Utils.is_function(definition)
          throw err(Sirius.Utils.camelize(property))
        definition
      else if Sirius.Utils.is_function(param)
        param
      else if param # is not a function or a string, but still is defined
        throw err(Sirius.Utils.camelize(property))
      else if param_in_controller
        # the same should be a function
        unless Sirius.Utils.is_function(param_in_controller)
          throw err(Sirius.Utils.camelize(property))
        param_in_controller
      else
        if !is_guard
          ->
        else
          null

    @before = extract('before')
    @after  = extract('after')
    @guard  = extract('guard', true)

    @data = params['data'] || []
    @controller = controller

    return

  ###
   @param e {EventObject|null} - the event object if it is a mouse\key event, and `null` when it's url change event
   @param args {array[any]} - arguments, used only for url changes events

   @note if you have the guard function, the call chain is
    if @guard is true
      - before
      - action
      - after
    otherwise
      - nothing to call
    without the `guard`, a chain is
      - before
      - action
      - after
  ###
  handle_event: (e, args...) ->
    #when `e` is defined then it is an Event,
    # otherwise: the method was called from the url_routes
    # and skip call for CustomEvent
    @logger.debug("Start event processing")
    if e
      data   = if Sirius.Utils.is_array(@data) then @data else [@data]
      result = Sirius.Application.adapter.get_properties(e, data) #FIXME use Promise

      merge  = [].concat([], [e], result)
      # fix bug#4 when event is the custom event we should get args for that event
      @_call_with([].concat([], merge, args...))
    else
      @_call_with([].concat.apply([], args))

  _call_with: (args) ->
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
    @logger.debug("tick")
    @_call_with(null)

class Sirius.Internal.RoutingSetup
  constructor: (settings) ->
    @is_need_redirect_to_hash   = settings["old"]
    @has_push_state_support = settings["support"]
    @is_ignore_not_matched_urls = settings["ignore"]

  @build: (settings) ->
    new Sirius.Internal.RoutingSetup(settings)


###
 @private
 For creating event listeners
###
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

  _scheduler_register: (routes, wrapper, logger) ->
    every = @_every
    scheduler = @_scheduler
    f = @_get_scheduler_params
    # "every 10s" : {controller: ABC, action: "action"}
    for url, action of routes when @_is_scheduler_command(url)
      do(url, action) =>
        handler = if Sirius.Utils.is_function(action)
          wrapper(action)
        else
          () ->
            (new Sirius.Internal.ControlFlow(action, wrapper)).tick()

        units = f(url)

        logger.debug("Define scheduler for '#{url}' with #{JSON.stringify(units)}")

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
      do(url, action) =>
        handler = if Sirius.Utils.is_function(action)
          wrapper(action)
        else
          (e, params...) ->
            (new Sirius.Internal.ControlFlow(action, wrapper)).handle_event(e, params)

        result = url.match(/^([a-zA-Z:]+)(\s+)?(.*)?/)
        event_name = result[1]
        selector   = result[3] || document #when it a custom event: 'custom:event' for example
        adapter.bind(document, selector, event_name, handler)
        logger.debug("define event route: '#{event_name}' for '#{adapter.as_string(selector)}'")

  _get_hash_routes: (routes, wrapper, logger) ->
    for url, action of routes when @_is_hash_route(url)
      logger.info("define hash route: '#{url}' ~> #{action}")
      url    = new Sirius.Internal.RoutePart(url)
      action = if Sirius.Utils.is_function(action)
        wrapper(action)
      else
        new Sirius.Internal.ControlFlow(action, wrapper)
      [url, action]

  _get_plain_routes: (routes, wrapper, logger) ->
    for url, action of routes when @_is_plain_route(url)
      logger.debug("define route: '#{url}' ~> #{action}")
      url    = new Sirius.Internal.RoutePart(url)
      action = if Sirius.Utils.is_function(action)
        wrapper(action)
      else
        new Sirius.Internal.ControlFlow(action, wrapper)
      [url, action]

  _convert_to_hash_routing: (setup, current_routing, logger) ->
    # Sirius.Internal.RoutingSetup
    #  @is_need_redirect_to_hash   = settings["old"]
    #    @has_push_state_support = settings["support"]
    #    @is_ignore_not_matched_urls = settings["ignore"]
    routes = current_routing
    if setup.is_need_redirect_to_hash and !setup.has_push_state_support
      logger.info("Convert plain routing into hash routing")
      # convert to new routing
      urls = [] # save urls into array, for check collision
      route = {}
      for url, action of routes
        if @_is_hash_route(url)
          urls.push(url)
        if @_is_plain_route(url)
          url = "\##{url}"
          if urls.indexOf(url) != -1
            @logger.warn("Routes already defined '#{url}' url")
        route[url] = action
      routes = route
    routes

  ###
    @return {boolean} - flag, defined that the route is matched or not
  ###
  _try_to_call: (array_of_route_definition, current) ->
    result = false
    for [route, control_flow] in array_of_route_definition # route : CF|Function
      unless result
        match_result = route.match(current)
        if match_result.is_success()
          result = true
          # TODO generate control flow for functions too
          if control_flow.handle_event
            control_flow.handle_event(null, match_result.get_args())
          else
            control_flow.apply(null, match_result.get_args())
    result

  ###
   @private
   try to handle 404 event in the application
  ###
  _handle_404_event: (routes, current, prev, wrapper, adapter, logger) ->
    logger.warn("route '#{current}' not found. Generate 404 event")
    adapter.fire(document, "application:404", current, prev)
    r404 = routes['404'] || routes[404]
    if r404
      if Sirius.Utils.is_function(r404)
        wrapper(r404)(current)
      else
        (new Sirius.Internal.ControlFlow(r404, wrapper)).handle_event(null, current)


  ###
    @param routes {Sirius.Internal.RoutingSetup} Setup definition
    @param fn {Function} a callback, which will be called, after the routing initialization
    @event application:urlchange - will be generated, if an url change
    @event application:404 - will be generated, if an url does not match in the defined routing
    @event application:run - will be generated, on the application start
    an setting : old, top, support
  ###
  create: (routes, setup, fn = ->) ->
    logger = Sirius.Application.get_logger("Sirius.Internal.RouteSystem")
    journal = new Sirius.Internal.HistoryJournal(setup)

    current = prev = journal.hash()

    Sirius.Application.get_adapter().and_then (adapter) =>
      routes = @_convert_to_hash_routing(setup, routes, logger)

      # wrap all actions in the controller
      wrapper = (fn) ->
        for key, value of Sirius.Application.controller_wrapper
          @[key] = value

        fn

      # set routing by event
      @_event_register(routes, wrapper, adapter, logger)

      # scheduler
      @_scheduler_register(routes, wrapper, adapter, logger)

      # for cache change obj[k, v] to array [[k,v]]
      array_of_routes = @_get_hash_routes(routes, wrapper, logger)

      plain_routes = @_get_plain_routes(routes, wrapper, logger)

      _prevent_default = (e) ->
        if e.preventDefault
          e.preventDefault()
        else
          e.returnValue = false

      dispatcher = (e) ->
        prev        = current
        route_array = []
        result      = false
        is_hash_based_route = false

        logger.debug("start processing route: '#{current}'")

        if e.type == "hashchange"
          # hashchange
          route_array = array_of_routes
          current = journal.hash()
          origin = journal.origin()
          is_hash_based_route = true

          journal.write({href: current}, "#{current}", "#{origin}/#{current}")

        else # e.type : click or popstate
          # plain
          route_array = plain_routes
          href = e.target.href
          # need save history only for 'click' event
          if e.type != "popstate" && setup.has_push_state_support
            journal.write({href: href}, "#{href}", href)

          pathname = journal.pathname()

          current = pathname

        result = Sirius.Internal.RouteSystem._try_to_call(route_array, current)

        unless result
          if setup.is_ignore_not_matched_urls
            logger.debug("the URL was not matched: '#{current}'")
            return

          else
            Sirius.Internal.RouteSystem._handle_404_event(routes, current, prev, wrapper, adapter, logger)

            _prevent_default(e)
            return
        else
          _prevent_default(e)

        logger.debug("Url changed to: #{current}")
        adapter.fire(document, "application:urlchange", current, prev)

        return

      @dispatch = dispatcher

      if plain_routes.length != 0
        # bind all <a> element with dispatch function, but bind only when href not contain "#"
        adapter.bind document, @_selector, "click", dispatcher

      window.onhashchange = dispatcher
      if setup.has_push_state_support
        adapter.bind window, null, "popstate", (e) ->
        # should run only for the plain routing, but not for hash based!
        # history.state.href contain url which start from "#", when hash change
        #                    contain full address otherwise
        # also when we visit from plain url to hash, then history.state is null
          if history and history.state?
            if history.state.href != undefined
              if history.state.href.indexOf("#") != 0
                dispatcher(e)


      fn()
