
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
    create: (routes, fn) ->
      current = prev = window.location.hash

      is_f = (f) ->
        Object.prototype.toString.call(f) == '[object Function]'


      #TODO: add filters: before\after\wrap
      #[Controller, "method"] => Controller[method]
      a2f = (a) ->
        throw "#{a} must be array or function" if Object.prototype.toString.call(a) isnt '[object Array]'
        throw "#{a} must contain two elements: Controller and method" if a.length != 2
        [controller, action] = a
        throw "Controller must be a Object" if typeof controller isnt 'object'
        throw "Action must be a String" if Object.prototype.toString.call(action) isnt '[object String]'
        f = controller[action]
        throw "Action must be a Function" if Object.prototype.toString.call(f) isnt '[object Function]'
        f

      for url, action of routes when url.indexOf("#") != 0 && url.toString() != "404"
        do (url, action) =>
          action = if is_f(action) then action else a2f(action)
          z = url.match(/^([a-zA-Z:]+)(\s+)?(.*)?/)
          event_name = z[1]
          selector   = z[3] || document #when it a custom event: 'custom:event' for example
          SiriusApplication.adapter.bind(selector, event_name, action)

      # for cache change obj[k, v] to array [[k,v]]
      array_of_routes = for url, action of routes when url.toString() != "404"
        do (url, action) ->
          url    = new RoutePart(url)
          action = if is_f(action) then action else a2f(action)
          [url, action]

      empty = () ->

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
              part[1].apply(null, f.args)
              return


        #when no results, then call 404 or empty function
        if !result
          SiriusApplication.adapter.fire(document, "application:404", current, prev)
          (if routes['404'] then a2f(routes['404']) else empty)(current)

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


