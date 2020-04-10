
# @class
# Base logger class for use in Sirius Application
class Sirius.Logger

  class LogLevel
    constructor: (@value, @weight) ->

    gte: (other) ->
      @weight >= other.weight

    get_value: () -> @value


  @Debug = new LogLevel("debug", 10)
  @Info = new LogLevel("info", 20)
  @Warn = new LogLevel("warn", 30)
  @Error = new LogLevel("error", 40)

  @Levels = [@Debug, @Info, @Warn, @Error]

  # @private
  # @nodoc
  @_get_logger_from_input: (str) ->
    return @Debug unless str?
    return @Debug unless Sirius.Utils.is_string(str)

    maybe = @Levels.filter((x) => x.get_value() == str.toLowerCase())
    if maybe && maybe.length == 0
      @Debug
    else
      maybe[0]

  ###
    Check if given string is valid log level
  ###
  @is_valid_level: (str) ->
    (Sirius.Logger.Levels.filter (x) -> x.get_value() == str).length != 0

  # @param [Boolean] - true, if log is enabled
  # @param [LogLevel] - minimum level
  # @param [Function] - logger function for application
  constructor: (log_enabled, log_source, minimum_log_level, logger_function) ->
    for level in Sirius.Logger.Levels
      do(level) =>
        value = level.get_value()
        @[value] = (msg) ->
          if log_enabled
            if level.gte(minimum_log_level)
              logger_function(value.toUpperCase(), log_source, msg)





