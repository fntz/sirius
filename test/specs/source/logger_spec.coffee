describe "Logger", ->
  warn = "warn"
  debug = "debug"
  error = "error"
  info = "info"
  available = [warn, debug, error, info]

  it "should log, when log is enabled", ->
    queue = []
    options =
      enable_logging: true
      log_to: (level, log_source, message) ->
        if available.indexOf(message) != -1
          queue.push(message)

    Sirius.Logger.Configuration.configure(options)
    logger = Sirius.Logger.build("test#1")

    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    expect(queue).toEqual(["warn", "debug", "error", "info"])

  it "should ignore logs, when log is disabled", ->
    queue = []
    options =
      enable_logging: false
      log_to: (level, log_source, message) ->
        if available.indexOf(message) != -1
          queue.push(message)

    Sirius.Logger.Configuration.configure(options)
    logger = Sirius.Logger.build("test#2")

    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    expect(queue).toEqual([])


  it "should use log level",  ->
    queue = []
    options =
      enable_logging: true
      minimum_log_level: "warn"
      log_to: (level, log_source, message) ->
        if available.indexOf(message) != -1
          queue.push(message)

    Sirius.Logger.Configuration.configure(options)
    logger = Sirius.Logger.build("test#3")

    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    expect(queue).toEqual(["warn", "error"])

  it "should fail when log_to is not a function", ->
    expect(() ->
      Sirius.Logger.Configuration.configure({log_to: 123})
    ).toThrowError("'log_to' argument must be a function")

  it "should fail if log level are not valid", ->
    expect(() ->
      options =
        enable_logging: true
        minimum_log_level: "asd"
      Sirius.Logger.Configuration.configure(options)
    ).toThrowError()

