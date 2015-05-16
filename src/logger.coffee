
# @class
# Base logger class for use in Sirius Application
class Sirius.Logger

  @Levels = ['debug', 'info', 'warn', 'error']

  @Filters = [
      "BaseModel"
      "Binding"
      "Collection"
      "View"
      "Routing"
      "Application"
      "Redirect"
      "Validation"
    ]

  # @param [Boolean] - true, when log enabled
  # @param [Function] - logger function for application
  constructor: (log_enabled, filters, logger_function) ->
    pre_filters = Sirius.Logger.Filters

    # define alias like @logger.application
    for f in pre_filters
      @[Sirius.Utils.underscore(f).toLowerCase()] = f

    for level in Sirius.Logger.Levels
      do(level) =>
        @[level] = (msg, location) ->
          if log_enabled
            # need print only in filter or user
            if filters.indexOf(location) != -1 || (!location? || pre_filters.indexOf(location) == -1)
              msg = if location?
                "[#{location.toUpperCase()}] #{msg}"
              else
                msg
              logger_function(level.toUpperCase(), msg)





