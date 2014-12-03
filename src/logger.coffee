
# @class
# Base logger class for use in Sirius Application
class Sirius.Logger

  Levels = ['debug', 'info', 'warn', 'error']

  # @param [Boolean] - true, when log enabled
  # @param [Function] - logger function for application
  constructor: (@log, @logger_function) ->
    for l in Levels
      do(l) =>
        @[l] = (msg) -> @logger_function("#{l.toUpperCase()}: #{msg}")





