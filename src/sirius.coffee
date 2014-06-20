

class SiriusUtils
  @is_function: (a) ->
    Object.prototype.toString.call(a) is '[object Function]'

  @is_string: (a) ->
    Object.prototype.toString.call(a) is '[object String]'

  @is_array: (a) ->
    Object.prototype.toString.call(a) is '[object Array]'

  @camelize: (str) ->
    str.charAt(0).toUpperCase() + str.slice(1)

  @underscore: (str) ->
    str.replace(/([A-Z])/g, '_$1').replace(/^_/,"").toLowerCase()
###
  RoutePart is a parser for string route representation
###
class RoutePart
  constructor: (route) ->
    @end   = yes
    @start = null #not used ...
    @parts = []
    @args  = []
    # #/abc/dsa/ => ["#", "abc", "dsa"]
    parts = route.replace(/\/$/, "").split("/")

    # mark, this route not have a length and end
    # example:
    #  #/title/id/*
    # matched with #/title/id/2014 and #/title/id/2014/2020 ...
    @end   = no if parts[parts.length - 1] == "*"

    @parts = parts[0..-1]

  # @param [String] - is a url
  # @return [Boolean] true if matched, otherwise - return false
  match: (url) ->
    @args = []
    parts = url.replace(/\/$/, "").split("/")

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



class ControlFlow
  # obj is a object with controller\action\before\after\data properties
  # required:
  #   controller must be a Object
  #   action is a string
  # before\after might be given as string or find in controller as before_action and after_action methods
  # before\after might be a function
  # data is a string for element (id\class\data-*\...) event routes, otherwise it's a null
  # if it's a function, then before\after\data is a null or empty function ? TODO
  constructor: (params) ->
    controller = params['controller'] || throw new Error("Params must contain a Controller")


    act = params['action']

    @action = if SiriusUtils.is_string(act)
                controller[act]
              else if SiriusUtils.is_function(act)
                act
              else
                throw new Error("Action must be string or function");

    if !SiriusUtils.is_function(@action) && !SiriusUtils.is_string(@action)
      throw new Error("Action must be string or function")

    ###
      extract from `params` before or after function
      when it's a function then return function
      when it's a string it's find by `string` in controller
        when given not a function raise error
        otherwise return this method from controller
      if it's not a function or string throw error
      otherwise find in controller by *_given_action if found a function return it
        else raise error
      by end it's return empty function
    ###
    extract = (property) =>
      p = params[property]
      k = controller["#{property}_#{act}"]
      err = (a) ->
        new Error("#{a} action must be string or function")

      if SiriusUtils.is_string(p)
        t = controller[p]
        throw err(SiriusUtils.camelize(property)) if !SiriusUtils.is_function(t)
        t
      else if SiriusUtils.is_function(p)
        p
      else if p
        throw err(SiriusUtils.camelize(property))
      else if k
        throw err(SiriusUtils.camelize(property)) if !SiriusUtils.is_function(k)
        k
      else
        ->

    @before = extract('before')
    @after  = extract('after')

    @data = params['data'] || null

  # e is a event need extract event target
  handle_event: (e, args...) ->
    @before()

    #when e defined it's a Event, otherwise it's call from url_routes
    if e
      if @data
        @data = if SiriusUtils.is_array(@data) then @data else [@data]
        data = SiriusApplication.adapter.get_property(e, @data)
        @action.apply(null, [].concat([], [e], data))
      else
        @action.apply(null, [e])
    else
      @action.apply(null, args)

    @after(null)



#TODO make it as function
###
  Main Object.

  @example:
    MyController =
      my_action: (id) ->
        #...

      when_click: (event) ->
        #...

    routes =
      '#/action/:id'  : [MyController, "my_action"]
      'click #button" : [MyController, "my_action"]
      404: (current_url) ->
        alert("#{current_url} not found!")

    adapter = new JQueryAdapter();

    SiriusApplication.run({adapter: adapter, route: routes})
###
SiriusApplication =
  ###
    Bind for routes appropriate events and callbacks
  ###
  RouteSystem:
    #
    #@param [Object] is a routes object where keys is a route and value is a array where
    # first element is a controller name, and second element is a action
    # or it's a function
    # @event application:hashchange [current_url, prev_url]
    # @event application:404 when url not found
    # @event application:run after running
    create: (routes, fn = ->) ->
      current = prev = window.location.hash

      for url, action of routes when url.indexOf("#") != 0 && url.toString() != "404"
        do (url, action) =>
          handler = if SiriusUtils.is_function(action)
                     action
                   else
                    (e) ->
                      (new ControlFlow(action)).handle_event(e)

          z = url.match(/^([a-zA-Z:]+)(\s+)?(.*)?/)
          event_name = z[1]
          selector   = z[3] || document #when it a custom event: 'custom:event' for example
          SiriusApplication.adapter.bind(selector, event_name, handler)

      # for cache change obj[k, v] to array [[k,v]]
      array_of_routes = for url, action of routes when url.toString() != "404"
        do (url, action) ->
          url    = new RoutePart(url)
          action = if SiriusUtils.is_function(action) then action else new ControlFlow(action)
          [url, action]

      window.onhashchange = (e) =>
        prev = current
        current = window.location.hash
        result = false

        SiriusApplication.logger("Url change to: #{current}")
        SiriusApplication.adapter.fire(document, "application:hashchange", current, prev)

        #call first matched function
        for part in array_of_routes
          do(part) =>
            f = part[0]
            r = f.match(current)
            if r && !result
              result = true
              z = part[1]
              if z.handle_event
                z.handle_event(null, f.args)
              else
                z.apply(null, f.args)
              return

        #when no results, then call 404 or empty function
        if !result
          SiriusApplication.adapter.fire(document, "application:404", current, prev)
          #FIXME
          r404 = routes['404']
          if r404
            z = new ControlFlow(r404)
            z.handle_event(null, current)

      fn()

  log: false
  #adapter for application @see adapter documentation
  adapter: null
  #boolean
  running: false
  #route object
  route: {}
  #base logger when not support will be call a alert function
  logger: (msg) ->
    return if !@log
    if window.console
      console.log msg
    else
      alert "Not supported `console`"
  run: (options = {}) ->
    @running = true
    @log     = options["log"]     || @log
    @adapter = options["adapter"] || throw new Error("Specify adapter")
    @route   = options["route"]   || @route
    @logger  = options["logger"]  || @logger

    @logger("Logger enabled? #{@log}")
    n = @adapter.constructor.name
    @logger("Adapter: #{n}")
    # start
    SiriusApplication.RouteSystem.create(@route, () =>
      @adapter.fire(document, "application:run", new Date());
    );


