
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


SiriusApplication =
  log: false
  adapter: null
  running: false
  route: {}
  run: (options = {}) ->
    @running = true
    @log     = options["log"]     || @log
    @adapter = options["adapter"] || throw new Error("Specify adapter")
    @route   = options["route"]   || @route

    # start
    SiriusApplication.RouteSystem.create(@route);

