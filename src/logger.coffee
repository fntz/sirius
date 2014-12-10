
# @class
# Base logger class for use in Sirius Application
class Sirius.Logger

  @Levels = ['debug', 'info', 'warn', 'error']

  # @param [Boolean] - true, when log enabled
  # @param [Function] - logger function for application
  constructor: (log_enabled, logger_function) ->
    for level in Sirius.Logger.Levels
      do(level) =>
        @[level] = (msg) ->
          if log_enabled
            logger_function(level.toUpperCase(), msg)






