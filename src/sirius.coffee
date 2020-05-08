
# A main object, it's a start point all user applications
# @example
#   var route = {
#     "#/"                : { controller : Controller, action: "action" },
#     "application: run"  : { controller : Controller, action: "run" },
#     "click #my-element" : { controller : Controller, action: "click_action"}
#   }
#   my_logger = function(level, log_source, msg) { console.log("Log: " + msg); }
#
#   Sirius.Application.run({
#     route : route,
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

    _get_key_or_default = (k, _default) ->
      if options[k]?
        options[k]
      else
        _default

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
    logger.info("Adapter: #{@adapter._adapter_name}")
    logger.info("Use hash routing for old browsers: #{@use_hash_routing_for_old_browsers}")
    logger.info("Current browser: #{navigator.userAgent}")
    logger.info("Ignore not matched urls: #{@ignore_not_matched_urls}")

    @push_state_support = history.pushState
    logger.info("History pushState support: !!#{@push_state_support}")

    if !@push_state_support && @use_hash_routing_for_old_browsers
      logger.warn("You browser does not support pushState, and you disabled hash routing for old browser")

    routing_setup = Sirius.Internal.RoutingSetup.build
      old: @use_hash_routing_for_old_browsers
      support: @push_state_support
      ignore: @ignore_not_matched_urls

    # start
    Sirius.Internal.RouteSystem.create @route, routing_setup, () =>
      for p in @_wait
        p.set_value(@adapter)
      @adapter.fire(document, "application:run", new Date())

    if @start
      Sirius.redirect(@start)



