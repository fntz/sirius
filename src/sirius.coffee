

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

    

