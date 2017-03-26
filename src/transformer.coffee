###
  Create Binding between Model and View and vice versa
  @see https://github.com/fntz/sirius/issues/31

  This class have own Logger Name [Transformer]
###

Sirius.Transformer =
  Model :  0
  View  :  0

  _from: null

  # Sirius.View
  _view: null

  # Sirius.Model
  _model: null

  # hash object
  _path: null

  # called implicitly with `via` method in binding
  set_from: (from) ->
    if @Model == from || @View == from
      @_from = from
    else
      throw new Error("Unexpected 'from' option for Transformer, required: Model: #{@Model} or View: #{@View}")

  set_model: (m) ->
    @_model = m

  set_view: (v) ->
    @_view = v

  _logger_helper: () ->
    if @_model && @_view
      if @_from == @Model
        "from Model to View"
      else
        "from View to Model"
    else
      "Seems you don't define Model and View for Transformer, check please"

  _validate_state: () ->
    @_model && @_view && @_from

  draw: (object) ->
    logger = Sirius.Application.get_logger()

    logger.info("Draw Transformer: #{@_logger_helper()}")

    if not @_validate_state()
      throw new Error("Define direction (from View to Model, or from Model to View)")

    @_path = object
    







