describe "Application", ->
  warn = "warn"
  debug = "debug"
  error = "error"
  info = "info"
  available = [warn, debug, error, info]


  it "should log, when log is enabled", (done) ->
    queue = []
    options =
      enable_logging: true
      log_to: (level, log_source, message) ->
        if available.indexOf(message) != -1
          queue.push(message)

    logger = Sirius.Application._initialize(options).logger

    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")

    setTimeout(
      () ->
        expect(queue).toEqual(["warn", "debug", "error", "info"])
        done()
      1000
    )



  it "should ignore logs, when log is disabled", (done) ->
    queue = []
    options =
      enable_logging: false
      log_to: (level, log_source, message) ->
        if available.indexOf(message) != -1
          queue.push(message)

    logger = Sirius.Application._initialize(options).logger

    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    setTimeout(
      () ->
        expect(queue).toEqual([])
        done()
      1000
    )


  it "should use log level", (done) ->
    queue = []
    options =
      enable_logging: true
      minimum_log_level: "warn"
      log_to: (level, log_source, message) ->
        if available.indexOf(message) != -1
          queue.push(message)

    logger = Sirius.Application._initialize(options).logger

    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    setTimeout(
      () ->
        expect(queue).toEqual(["warn", "error"])
        done()
      1000
    )


  it "should fail if log level are not valid", ->
    expect(() ->
      options =
        enable_logging: true
        minimum_log_level: "asd"
      Sirius.Application.run options
    ).toThrowError()

