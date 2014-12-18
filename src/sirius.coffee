# Redirect to given url.
# @method .Sirius.redirect(url)
# @example
#   var Controller = {
#     action : function(params) {
#        if (params.length == 0)
#          Sirius.redirect("#"); //redirect to root url
#        else
#          //code
#     }
#
Sirius.redirect = (url) ->
  app = Sirius.Application
  app.logger.info("Redirect to #{url}")
  if url.indexOf("#") == 0
    if app.hash_always_on_top && app.push_state_support
      origin = window.location.origin
      history.replaceState({href: url}, "#{url}", "#{origin}/#{url}")
  else
    if app.push_state_support
      history.pushState({href: url}, "#{url}", url)

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
      @logger.error("ControlFlow: #{msg}")
      throw new Error(msg)
    if !action
      msg = "action #{act} not found in controller #{controller}"
      @logger.error("ControlFlow: #{msg}")
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
    @logger.info("ControlFlow: Start event processing")
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

  _hash_route: (url) ->
    url.toString().indexOf("#") == 0

  _404_route: (url) ->
    url.toString() == "404"

  _plain_route: (url) ->
    url.toString().indexOf("/") == 0

  _event_route: (url) ->
    !@_hash_route(url) && !@_404_route(url) && !@_plain_route(url)
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
    link_transform     = setting["link_transform"]
    active_class       = setting["active_class"]

    current_link = previous_link = null

    Sirius.Application.get_adapter().and_then (adapter) =>
      is_hash_routing = false
      if redirect_to_hash and !push_state_support
        logger.info("RouteSystem: Convert plain routing into hash routing")
        is_hash_routing = true
        # convert to new routing
        urls = [] #save urls into array, for check collision
        route = {}
        for url, action of routes
          urls.push(url) if @_hash_route(url)
          if @_plain_route(url)
            url = "\##{url}"
            if urls.indexOf(url) != -1
              logger.warn("RouteSystem: Routes already have '#{url}' url")
          route[url] = action
        routes = route


      # wrap all controller actions
      wrapper = (fn) ->
        for key, value of Sirius.Application.controller_wrapper
          @[key] = value

        fn

      # set routing by event
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
          logger.info("RouteSystem: define event route: '#{event_name}' for '#{selector}'")
          null

      # for cache change obj[k, v] to array [[k,v]]
      array_of_routes = for url, action of routes when @_hash_route(url)
        logger.info("RouteSystem: define hash route: '#{url}'")
        url    = new Sirius.RoutePart(url)
        action = if Sirius.Utils.is_function(action)
          wrapper(action)
        else
          new Sirius.ControlFlow(action, wrapper)
        [url, action]

      plain_routes = for url, action of routes when @_plain_route(url)
        logger.info("RouteSystem: define route: '#{url}'")
        url    = new Sirius.RoutePart(url)
        action = if Sirius.Utils.is_function(action)
          wrapper(action)
        else
          new Sirius.ControlFlow(action, wrapper)
        [url, action]

      dispatcher = (e) ->
        prev        = current
        route_array = null
        result      = false
        if e.target.location? # then it after back or forward button click
          link_transform(previous_link, current_link) #FIXME
          t = current_link
          current_link = previous_link
          previous_link = t
        else
          previous_link = current_link
          current_link = e.target
          link_transform(current_link, previous_link)
        logger.info("RouteSystem: start processing route: '#{current}'")
        if e.type == "hashchange"
          # hashchange
          route_array = array_of_routes
          current = window.location.hash
          if hash_on_top and push_state_support
            origin = window.location.origin
            history.replaceState({href: current}, "#{current}", "#{origin}/#{current}")
        else
          # plain
          route_array = plain_routes
          href = e.target.href # TODO the same for hashchange
          history.pushState({href: href}, "#{href}", href) if push_state_support
          pathname = window.location.pathname
          pathname = "/" if pathname == ""
          if (e.preventDefault)
            e.preventDefault()
          else
            e.returnValue = false
          current = pathname

        logger.info("RouteSystem: Url change to: #{current}")
        adapter.fire(document, "application:urlchange", current, prev)

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
            return

        if !result
          logger.warn("RouteSystem: route '#{current}' not found. Generate 404 event")
          adapter.fire(document, "application:404", current, prev)
          r404 = routes['404'] || routes[404]
          if r404
            if Sirius.Utils.is_function(r404)
              wrapper(r404)(current)
            else
              (new Sirius.ControlFlow(r404, wrapper)).handle_event(null, current)

        false

      # need convert all plain url into hash based url
      # convert only when
      links = adapter.all(@_selector)
      if redirect_to_hash && !push_state_support
        logger.info("RouteSystem: Found #{links.length} link. Convert href into hash based routing")
        for link in links
          href = link.getAttribute('href')
          if href.indexOf("http") == -1
            new_href = if href.indexOf("/") == 0
              "\##{href}"
            else
              "\#/#{href}"
            logger.info("RouteSystem: Convert '#{href}' -> '#{new_href}'")
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
            dispatcher(e)


      # TODO work with hash routes
      current = if is_hash_routing
        location.hash
      else
        location.pathname

      logger.info("RouteSystem: current url: #{current}")

      # also we need detect current active link if present
      for link in links when adapter.get_attr(link, 'class').split(" ").indexOf(active_class) != -1
        current_link = link

      # need detect current url and set active link for current url
      # if previous already set and it not for current url, then we reset class for url
      for link in links when link.getAttribute('href') == current
        if current_link?
          if current_link != link
            logger.warn("RouteSystem: link with active class: #{active_class} not equal for current url: #{current}")
            adapter.set_attr(link, 'class', active_class)
        else
          adapter.set_attr(link, 'class', active_class)
          current_link = link


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
  default class when click on link.
###
  class_name_for_active_link: 'active'

###
  It's should be function.
  When user click on link, then need add `class_name_for_active_link` for this link

  @example
    class_name_for_active_link: (element, previous) ->
      $(element).addClass('custom-class')
      $(previous).removeClass('custom-class')

###
  transform_link_to_active: (element, previous) ->
    Sirius.Application.get_adapter().and_then (adapter) ->
      adapter.set_attr(element, 'class', Sirius.Application.class_name_for_active_link)
      if previous?
        previous.className = ''



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
          o[l] = (msg) -> q.push([l, msg])
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
    @logger  = new Sirius.Logger(@log, options['logger'] || @default_log_function)
    @start   = options["start"]   || @start

    @class_name_for_active_link = options['class_name_for_active_link'] || @class_name_for_active_link

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
    @transform_link_to_active = options['transform_link_to_active'] || @transform_link_to_active

    @logger.info("Application: Logger enabled? #{@log}")

    @logger.info("Application: Adapter: #{Sirius.Utils.fn_name(@adapter.constructor)}")
    @logger.info("Application: Hash always on top: #{@hash_always_on_top}")
    @logger.info("Application: Use hash routing for old browsers: #{@use_hash_routing_for_old_browsers}")
    @logger.info("Application: Current browser: #{navigator.userAgent}")
    @logger.info("Application: class name for link: #{@class_name_for_active_link}")

    @push_state_support = if history.pushState then true else false
    @logger.info("Application: History pushState support: #{@push_state_support}")

    if !@push_state_support && @use_hash_routing_for_old_browsers
      @logger.warn("Application: You browser not support pushState, and you disable hash routing for old browser")

    setting =
      old: @use_hash_routing_for_old_browsers
      top: @hash_always_on_top
      support: @push_state_support
      active_class: @class_name_for_active_link
      link_transform: @transform_link_to_active

    # start
    Sirius.RouteSystem.create @route, setting, () =>
      for p in @_wait
        p.set_value(@adapter)
      @adapter.fire(document, "application:run", new Date())
      for message in @_messages_queue
        @logger[message[0]].call(null, message[1])

    if @start
      Sirius.redirect(@start)


