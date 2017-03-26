###
  Create Binding between Model and View and vice versa
  @see https://github.com/fntz/sirius/issues/31

  This class have own Logger Name [Transformer]

  i.e. Pipe

  note only one `pipe` between one model class and view class

  @example

    #Base Idea

    <input id='my-name' type='text' />

    class MyModel extends Sirius.Model
      @attrs: ['name']

    view = new Sirius.View("#my-name")

    model = new MyModel()


    pipe_view_to_model = Sirius.Transformer.draw
      "#my-name":
        to: 'name'
        via: (html_element) ->
          value = fetch_value_from_element(html_element)
          return "#{value}!!!"

    pipe_model_to_view = Sirius.Transformer.draw
      "name":
        to: "#my-name"
        via: (value, selector, view) ->
          @view.zoom(selector).set_value(value)
        # or maybe




  Small notes:
  + Only one pipe
  + Need method for reverse pipe (from view to model -> from model to view)
  + Draw default for simple cases (text to text)


  Questions:
  + How to transformer should works between js objects?

###


# @private
# @nodoc
class Sirius.ToViewTransformer
  constructor: (@_path, @_model) ->
    @logger = Sirius.Application.get_logger()
    @_ln = @logger.transformer # logger name
    @_model._register_state_listener(@)

  # Check that this works for inputs
  _default_via_method: () ->
    (value, selector, view) ->
      view.zoom(selector).render(value).swap()


  fire: (attribute, value) ->
    value = @_path[attribute]

    if value
      @logger.debug("Apply new value for '#{attribute}' for '#{@_view.get_element()}', value: #{value}", @_ln)
      to = value['to']
      via = value['via'] || @_default_via_method()
      via(value, selector, @_view)

# @private
# @nodoc
class Sirius.ToModelTransformer
  constructor: (@_path, @_model, @_view) ->






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

  _from_model: () ->
    if @Model == @_from
      true
    else
      false

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
    # TODO add validation for to and via methods
    logger = Sirius.Application.get_logger()

    logger.info("Draw Transformer: #{@_logger_helper()}")

    if not @_validate_state()
      throw new Error("Define direction (from View to Model, or from Model to View)", logger.transformer)


    @_path = object

    if @_from_model()
      Sirius.ToViewTransformer(object, @_model, @_view)
    else
      Sirius.ToModelTransformer(object, @_model, @_view)



