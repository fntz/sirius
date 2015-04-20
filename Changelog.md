=== 0.7.1 

tests for prototypejs

=== 0.7.2 

Logger improvement

New options for `run`: `log_filters`

In `log_filters` need define filters for logs from different places of Sirius. Example:

```coffee
# BaseModel   = 0
# BindHelper  = 1
# Collection  = 2
# Observer    = 3
# View        = 4
# RouteSystem = 5
# ControlFlow = 6
# Application = 7
# Redirect    = 8
# Validator   = 9
 
Sirius.Application.run
  log_filters: [0, 1, 9] # in console logs only from BaseModel, BindHelper, and Validators
  # or 
  log_filters: ["BaseModel", "Application", "View"]
```

`mix_logger_into_controller` - add logger into you controller:

```coffee

Sirius.Application.run
  mix_logger_into_controller : true # by defualt
  routes: 
    application:run : () ->
      logger.info("run!!!") # => INFO: run!!!
      logger.debug("seems all ok") # => DEBUG: seems all ok
      logger.warn("oops") # => WARN: oops
      logger.error("ERROR") # => ERROR: ERROR
      # or 
      logger.info("run!!!", "MyRunController") # => INFO: [MyRunController] run!!!
      # etc...

```

`data-bind-to`, `data-bind-from` removed from code. Use object setting like

```js
model.bind(view, {
  '.model-id'         : {from: "id", to: "data-name"}
  '.model-title'      : {from: "title", to: "data-name"}
  '.model-description': {from: "description", to: "data-name"}
})

```














