
# @class
# Base logger class for use in Sirius Application
class Sirius.Logger

  class LogLevel
    constructor: (@value, @weight) ->

    gte: (other) ->
      other >= @weight

    get_value: () -> @value


  @Debug = new LogLevel("debug", 10)
  @Info = new LogLevel("info", 20)
  @Warn = new LogLevel("warn", 30)
  @Error = new LogLevel("error", 40)

  @Levels = [@Debug, @Info, @Warn, @Error]

  @Filters = [
      "BaseModel"
      "Binding"
      "Collection"
      "View"
      "Routing"
      "Application"
      "Redirect"
      "Validation"
      "Transformer"
    ]

  @is_valid_level: (str) ->
    (Sirius.Logger.Levels.filter (x) -> x.get_value() == str).length != 0

  # @param [Boolean] - true, when log enabled
  # @param [LogLevel] - minimum level
  # @param [Function] - logger function for application
  constructor: (log_enabled, minimum_log_level, filters, logger_function) ->
    pre_filters = Sirius.Logger.Filters

    # define alias like @logger.application
    for f in pre_filters
      @[Sirius.Utils.underscore(f).toLowerCase()] = f

    for level in Sirius.Logger.Levels
      do(level) =>
        @[level.get_value()] = (msg, location) ->
          if log_enabled
            if level.gte(minimum_log_level)
              # need print only in filter or user
              unless location # => user log
                logger_function(level.toUpperCase(), msg)
              else
                if filters.indexOf(location) != -1 || (!location? || pre_filters.indexOf(location) == -1)
                  msg = "[#{location.toUpperCase()}] #{msg}"
                  logger_function(level.toUpperCase(), msg)





