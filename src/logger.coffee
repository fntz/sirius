###
@class
Base logger class for use in Sirius Application
###
class Sirius.Logger

  # should be passed as parameter
  log_source: null

  class LogLevel
    constructor: (@value, @weight) ->

    gte: (other) ->
      @weight >= other.weight

    get_value: () -> @value


  @Debug = new LogLevel("debug", 10)
  @Info = new LogLevel("info", 20)
  @Warn = new LogLevel("warn", 30)
  @Error = new LogLevel("error", 40)
  @NoLog = new LogLevel("no-log", 100)

  @Levels = [@Debug, @Info, @Warn, @Error]

  @Default =
    enable_logging: false
    minimum_log_level: Logger.Debug.get_value()
    default_log_function: (level, log_source, message) ->
      if console && console.log
        console.log "#{level} [#{log_source}]: #{message}"
      else
        alert "Not supported `console`. You should define own `logger` function for a Sirius.Application"


  # @private
  # @nodoc
  @Configuration =
    # current configuration
    minimum_log_level: null
    log_function: null
    enable_logging: null

    _is_initialized: false

    # should be called in the initialization time
    # options.enable_logging
    # options.minimum_log_level
    # options.log_to
    configure: (options = {}) ->
      enable_logging = options['enable_logging'] || Logger.Default.enable_logging
      level_value = options["minimum_log_level"]

      if level_value
        unless @is_valid_level(level_value)
          level_values =  Logger.Levels.map (x) -> x.get_value()
          throw new Error("Invalid 'minimum_log_level' value: '#{level_value}', available options are: #{level_values.join(", ")}")

      user_log_level = level_value || Logger.Default.minimum_log_level
      @minimum_log_level = if enable_logging
        @_get_logger_from_input(user_log_level)
      else
        Logger.NoLog

      @enable_logging = enable_logging

      @log_function = unless options['log_to']
        Logger.Default.default_log_function
      else
        throw new Error("'log_to' argument must be a function") unless Sirius.Utils.is_function(options['log_to'])
        options['log_to']

      @_is_initialized = true

    ###
      Check if given string is valid log level
    ###
    is_valid_level: (str) ->
      (Logger.Levels.filter (x) -> x.get_value() == str).length != 0

    # @private
    # @nodoc
    _get_logger_from_input: (str) ->
      return Logger.Debug unless str?
      return Logger.Debug unless Sirius.Utils.is_string(str)

      maybe = Logger.Levels.filter((x) => x.get_value() == str.toLowerCase())
      if maybe && maybe.length == 0
        Logger.Debug
      else
        maybe[0]

  ###
    @constructor
    @param {string} - a logger source name
  ###
  constructor: (@log_source) ->
    @_log_queue = []

    unless Sirius.Logger.Configuration._is_initialized
      _timer = setInterval(
        () -> _flush_logs()
        100)

      _flush_logs = () =>
        if Sirius.Logger.Configuration._is_initialized
          for obj in @_log_queue
            @_write(obj.level, obj.message)
          clearInterval(_timer)

  @build: (log_source) ->
    new Sirius.Logger(log_source)

  # debug log writer
  debug: (message) ->
    @_write(Sirius.Logger.Debug, message)

  # info log writer
  info: (message) ->
    @_write(Sirius.Logger.Info, message)

  # warn log writer
  warn: (message) ->
    @_write(Sirius.Logger.Warn, message)

  # error log writer
  error: (message) ->
    @_write(Sirius.Logger.Error, message)

  # @private
  # @nodoc
  _write: (log_level, message) ->
    if Sirius.Logger.Configuration._is_initialized
      if log_level.gte(Sirius.Logger.Configuration.minimum_log_level)
        Sirius.Logger.Configuration
          .log_function(log_level.get_value().toUpperCase(), @log_source, message)
    else
      @_log_queue.push[{level: log_level, message: message}]








