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
        from: 'text' # class, id, *, default: text
        via: (value) ->
          return "#{value}!!!"

    view.bind(model, pipe_view_to_model)


    pipe_model_to_view = Sirius.Transformer.draw
      "name":
        to: "#my-name"
        via: (value, selector, view) ->
          @view.zoom(selector).set_value(value)
        # or maybe

    model.bind(view, pipe_model_to_view)


  Small notes:
  + Only one pipe
  + Need method for reverse pipe (from view to model -> from model to view)
  + Draw default for simple cases (text to text)


  Questions:
  + How to transformer should works between js objects?

###

class Sirius.Internal.AbstractTransformer

  constructor: (@_path, @_from, @_to) ->
    @logger = Sirius.Application.get_logger()
    @_ln = @logger.transformer # logger name
    @_register()

  _register: () ->


# @private
# @nodoc
class Sirius.Internal.ToFunctionTransformer extends Sirius.Internal.AbstractTransformer

  _register: () ->
    if @_from instanceof Sirius.BaseModel
      @_from._register_state_listener(@_to)
    else
      @_from._register_state_listener(@)
      clb = @_fire_generator()
      top = @_from.get_element()
      for selector, value of @_path
        from_property = value["from"] || Sirius.Internal.DefaultProperty
        new Sirius.Internal.Observer("#{top} #{selector}", selector, from_property, clb)

  _fire_generator: () ->
    view = @_from
    func = @_to

    callback = (result) ->
      func(result, view)

    callback

# @private
# @nodoc
class Sirius.Internal.ToViewTransformer extends Sirius.Internal.AbstractTransformer
  _register: () ->
    clb = @_fire_generator()

    if @_from instanceof Sirius.View
      top = @_from.get_element()
      to = @_path['to']
      for o in to
        [w, attr, selector] = if Sirius.Utils.is_string(o)
          [null, 'text', o]
        else
          [o['from'] || top, o['attribute'] || Sirius.Internal.DefaultProperty, o['selector']]

        top = if top == w
          top
        else if w?
          "#{top} #{w}"
        else
          top

        @logger.debug("Observe '#{top}' -> '#{@_to.get_element()} #{selector}'", @_ln)
        new Sirius.Internal.Observer(top, w, attr, clb)

    else # Model
      @_from._register_state_listener(clb)


  @_default_materializer_method: () ->
    (value, selector, view, attribute = 'text') ->
      view.zoom(selector).render(value).swap(attribute)

  _fire_generator: () ->
    view = @_to
    path = @_path
    logger = @logger
    ln = @_ln

    # view 2 view
    if @_from instanceof Sirius.View
      callback = (result) ->
        to = path['to']
        value = result.text
        for o in to
          if Sirius.Utils.is_string(o)
            via = Sirius.Internal.ToViewTransformer._default_materializer_method()
            via(value, o, view, attribute)

          else # object
            selector = o['selector']
            attr = o['attribute'] || 'text'
            via = o['with'] || Sirius.Internal.ToViewTransformer._default_materializer_method()
            via(value, selector, view, attr)


      callback

    else # model 2 view
      model = @_from
      callback = (attribute, value) ->
        obj = path[attribute]
        if obj
          logger.debug("Apply new value for '#{attribute}' for '#{view.get_element()}', value: #{value} from #{model._klass_name()}", ln)
          to = obj['to']
          attr = obj['attr'] || 'text'
          materializer = obj['with'] || Sirius.Internal.ToViewTransformer._default_materializer_method()

          materializer(value, to, view, attr)

      callback

# @private
# @nodoc
class Sirius.Internal.ToModelTransformer extends Sirius.Internal.AbstractTransformer
  _register: () ->
    @_from._register_state_listener(@)
    clb = @_fire_generator()
    top = @_from.get_element()
    for k, v of @_path
      w = @_path["from"] || "text"
      new Sirius.Internal.Observer("#{top} #{k}", k, w, clb)

  _default_materializer_method: () ->
    (value) -> value

  _fire_generator: () ->
    view = @_from
    path = @_path
    model = @_to
    logger = @logger
    ln = @_ln

    callback = (result) ->

      value = path[result.original]
      if value
        to = value['to']
        from = value['from'] || 'text'
        via = value['via'] || ((value) -> value)
        logger.debug("Apply new value from #{result.from} (#{result.original}) to #{model._klass_name()}.#{to}", ln)
        # result, view, selector, attribute, element
        model.set(to, via(result.text, view, result.original, from, result.element))

    callback


class Sirius.Transformer

  # from
  @_Model :  0
  @_View  :  1

  # to
  # Model, View, Function
  @_Function: 2

  _from: null

  _to: null

  # hash object
  _path: null

  constructor: (from, to) ->
    @logger = Sirius.Application.get_logger()
    @ln = @logger.transformer

    if from instanceof Sirius.BaseModel
      @_from = from
    else if from instanceof Sirius.View
      @_from = from
    else
      throw new Error("Bad argument: Model or View required, '#{typeof from}' given")

    if to instanceof Sirius.BaseModel
      if !(@_from instanceof Sirius.BaseModel)
        @_to = to
      else
        throw new Error("No way to bind two Models: '#{from._klass_name()}' and '#{to._klass_name()}'")
    else if to instanceof Sirius.View
      @_to = to
    else if Sirius.Utils.is_function(to)
      @_to = to
    else
      throw new Error("Bind works only with BaseModel, BaseView or Function, '#{typeof to}' given")


  # @private
  # @nodoc
  # maybe should be a part of model?
  _check_from_model_compliance: (materializer) ->
    if @_from instanceof Sirius.BaseModel
      name = @_from._klass_name()
      attrs = @_from.get_attributes()


      for k, v of materializer
        txt = "Attribute '#{k}' not found in model attributes: '#{name}', available: '[#{attrs}]'"
        is_validator = false
        if k.indexOf(".") != -1               # k is validator attribute
          if k.lastIndexOf("errors") == 0     # start
            tmp = k.split(".") # errors.id.numericality => [errors, id, numericality]

            if tmp.length != 3
              throw new Error("Try to bind '#{k}' from errors properties, but validator is not found, correct definition should be as 'errors.id.numericality'")

            [_, attr, validator_key] = tmp

            unless @_from._is_valid_validator("#{attr}.#{validator_key}")
              throw new Error("Unexpected '#{k}' errors attribute for '#{name}' (check validators)")
            else
              is_validator = true

        throw new Error(txt) if attrs.indexOf(k) == -1 && !is_validator

        # actual bind
        @logger.debug("bind: '#{name}.#{k}' -> #{v['to']}", @ln)

  # @nodoc
  # @private
  _check_to_model_compliance: (materializer) ->
    if @_to instanceof Sirius.BaseModel
      # {id: {to: attr}}
      name = @_to._klass_name()
      for k, v of materializer
        attr = v['to']
        unless attr?
          throw new Error("Failed to create transformer for '#{name}', because '#{JSON.stringify(materializer)}', does not contain 'to'-property")
        else
          attrs = @_to.get_attributes()
          throw new Error("Unexpected '#{attr}' for model binding. Model is: '#{name}', available attributes: '[#{attrs}]'") if attrs.indexOf(attr) == -1
          @logger.debug("bind: '#{k}' -> '#{name}.#{attr}'", @ln)

  # @private
  # @nodoc
  _check_view_to_view_compliance: (materializer) ->
    e = @_from.get_element()
    e1 = @_to.get_element()
    # validate, need 'to'-property
    to = materializer['to']
    unless to
      correct_way = '{"to": "selector"}'
      throw new Error("Define View to View binding with: 'view1.bind(view2, #{correct_way})', but 'to'-property was not found")
    else
      if Sirius.Utils.is_array(to)
        # check that in array string or object with selector property
        for element in to
          unless element['selector']
            correct_help = '{to: [{"selector": "#my-id", "attribute": "data-attr"}]}'
            _e1 = "You defined binding with 'to' as an array of objects, but 'selector' property was not found"
            _e2 = "Correct definition is: #{correct_help}"
            throw new Error("#{_e1} #{_e2}")
          else
            selector = element['selector']
            @logger.debug("bind: '#{e}' -> '#{e1} #{selector}'", @ln)

        return materializer
      else if Sirius.Utils.is_string(to)
        @logger.debug("bind: '#{e}' -> '#{e1} #{to}'")
        materializer['to'] = [to]
        return materializer
      else
        throw new Error("View to View binding must contains 'to' as an array or a string, but #{typeof(to)} given")

  # @private
  # @nodoc
  _check_view_to_function_compliance: (materializer) ->
      # check that 'from' is present
      element = @_from.get_element()

      for k, v of materializer
        unless v['from']
          correct_way = '{"selector": {"from": "text"}}'
          throw new Error("View to Function binding must contain 'from'-property: #{correct_way}")
        else
          f = v['from']
          @logger.debug("bind: '#{element} #{k}' (from '#{f}') -> function", @ln)

      materializer

  # called implicitly with a `materializer` method
  run: (materializer) ->
    throw new Error("Materializer must be object, '#{typeof materializer}' given") unless Sirius.Utils.is_object(materializer)

    unless Sirius.Utils.is_function(@_to)
      throw new Error("Materializer must be non empty object") if Object.keys(materializer).length == 0

    throw new Error("Not all parameters defined for transformer: from: #{@_from}, to: #{@_to}") if !@_from || !@_to

    # checkers
    @_check_from_model_compliance(materializer)
    @_check_to_model_compliance(materializer)

    if @_from instanceof Sirius.View && @_to instanceof Sirius.View
      @_path = @_check_view_to_view_compliance(materializer)
    else if @_from instanceof Sirius.View && Sirius.Utils.is_function(@_to)
      @_path = @_check_view_to_function_compliance(materializer)
    else
      @_path = materializer

    # strategies
    if @_to instanceof Sirius.BaseModel
      new Sirius.Internal.ToModelTransformer(materializer, @_from, @_to)
    else if @_to instanceof Sirius.View
      new Sirius.Internal.ToViewTransformer(materializer, @_from, @_to)
    else if Sirius.Utils.is_function(@_to)
      new Sirius.Internal.ToFunctionTransformer(materializer, @_from, @_to)


  @draw: (object) ->

    logger = Sirius.Application.get_logger()

    logger.debug("Draw Transformer", logger.transformer)

    object






