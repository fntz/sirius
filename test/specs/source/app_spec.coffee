AppSpecController =
  message: false
  action: () ->
    try
      logger.info("test")
      @message = true
    catch e
      #ignore

  is_logger_available: () ->
    @message

describe "Application", ->
  it "should log, when log is enabled", ->
    queue = []
    Sirius.Application.run
      enable_logging: true
        logger: (level, message) ->
          queue.push("#{level}:#{message}")

    logger = Sirius.Application.get_logger()
    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    expect(queue, ["warn", "debug", "error", "info"])

  it "should ignore logs, when log is disabled", ->
    queue = []
    Sirius.Application.run
      enable_logging: false
      logger: (level, message) ->
        queue.push("#{level}:#{message}")

    logger = Sirius.Application.get_logger()
    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    expect(queue, [])

  it "should use log level", ->
    queue = []
    Sirius.Application.run
      enable_logging: true
      minimum_log_level: "warn"
      logger: (level, message) ->
        queue.push("#{level}:#{message}")

    logger = Sirius.Application.get_logger()
    logger.warn("warn")
    logger.debug("debug")
    logger.error("error")
    logger.info("info")
    expect(queue, ["warn", "error"])

  it "should fail if log level are not valid", ->
    expect(() ->
      Sirius.Application.run
        enable_logging: true
        minimum_log_level: "asd"
    ).toThrowError()

