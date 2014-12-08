
# A class which implement collection interface.
# You might use it as alternative standard javascript arrays.
#
# @example
#
#   class MyModel extends Sirius.BaseModel
#     @attrs: ["id"]
#
#   myCollection = new Sirius.Collection(MyModel, [], {
#     every: 1000,
#     on_remote: () ->
#       json = ... # ajax call
#       return json
#
#     on_remove: (model) ->
#       id = model.id
#       #ajax call with id
#
#     on_add: (model) ->
#       $('list-of-models').append(model.to_html())
#
#   })
#
#  myModel = new MyModel({"id" : 1}
#  myCollection.add(myModel)
#  myCollection.add(new MyModel({"id" : 2})
#  myCollection.add(new MyModel({"id" : 3})
#
#  myCollection.index(myModel) # => 0
#  myCollection.find("id", 1)  # => MyModel Instance
#  myCollection.find("id", 1)  # => [ MyModel Instances ]
#  myCollection.filter( (model) -> model.get("id") > 2 ) # => [ MyModel Instances ]
#  myCollection.first() # => first MyModel instance
#  myCollection.last()  # => last MyModel instance
#
#  myCollection.unsycn() # stop synchronization with server
#  myCollection.sync(3000)   # start sync every 3 second
#
#  myCollection.size() # => 3
#  myCollection.length # => 3 // as property
class Sirius.Collection

  #
  # @param klass [T <: Sirius.BaseModel] - model class for all instances in collection
  # @param klasses [Array] - models, which used for `to_json` @see(Sirius.BaseModel.to_json)
  # @param options [Object] - with keys necessary
  # @attr every [Numberic] - ms for remote call
  # @attr on_add [Function] - callback, which will be call when add new instance to collection
  # @attr on_remove [Function] - callback, which will be call when remove model from collection
  # @attr remote [Function] - callback, which will be call when synchronize collection, must be return json
  constructor: (klass, args...) ->
    if klass.__super__.__name isnt 'BaseModel'
      throw new Error("Collection must be used only with `BaseModel` inheritor")
    @_array = []
    @logger = Sirius.Application.get_logger()
    # klasses, options
    klasses = []
    options = {}
    if args.length == 1
      if Sirius.Utils.is_array(args[0])
        klasses = args[0]
      else
        options = args[0]
    if args.length == 2
      klasses = args[0]
      options = args[1]

    @_klasses = klasses
    @_klass = klass
    @_type  = Sirius.Utils.fn_name(klass)


    @length = 0

    clb = (x) -> x

    @on_add = options.on_add || clb
    @on_remove = options.on_push || clb

    if options.remote
      @remote = =>
        result = options.remote()
        json = JSON.parse(result)
        if Sirius.Utils.is_array(json)
          if json.length != 0
            for model in json then @push(klass.from_json(JSON.stringify(model), @_klasses))
        else
          @push(klass.from_json(result, @_klasses))

    @_timer    = null
    @_start_sync(options.every || 0)


  # @nodoc
  # @private
  _start_sync: (every) ->
    if (every != 0)
      @logger.info("Collection: start synchronization")
      @_timer = setInterval(@remote, every)
    return

  # stop synchronization
  # @return [Void]
  unsync: () ->
    if @_timer
      @logger.info("Collection: end synchronization")
      clearInterval(@_timer)
    return

  # start synchronization
  #
  # @param every [Numeric] - milliseconds
  sync: (every) ->
    @_start_sync(every)

  #
  # alias for #add
  # @param model [T <: Sirius.BaseModel]
  # @return [Void]
  push: (model) ->
    @add(model)


  # add model into collection
  # @param model [T <: Sirius.BaseModel]
  # @return [Void]
  add: (model) ->
    @_add(model)
    @on_add(model)
    return

  # @nodoc
  # @private
  _add: (model) ->
    type = Sirius.Utils.fn_name(model.constructor)

    if @_type isnt type
      msg = "Require `#{@_type}`, but given `#{type}`"
      @logger.error("Collection: #{msg}")
      throw new Error(msg)
    @_array.push(model) #maybe it's a hash ? because hash have a keys, and simple remove, but need a unique id
    @length++

  # remove model from collection
  # @param [T <: Sirius.Model]
  # @return [Void]
  remove: (other) ->
    inx = @index(other)
    if inx != null
      @_array.splice(inx, 1)
      @on_remove(other)
    return

  #
  # Return index of model in collection or null, if not found
  # @param model [T <: Sirius.BaseModel]
  # @return [Numeric | null]
  index: (other) ->
    inx = null
    for model, i in @_array when model.compare(other) then inx = i
    inx

  #
  # find model by key with value
  # @param key [String] - attribute
  # @param value [Any] - actual value
  # @return [Model | null]
  find: (key, value) ->
    @find_all(key, value)[0] || null

  #
  # find all models by key with value
  # @param key [String] - attribute
  # @param value [Any] - actual value
  # @return [Array<Model>]
  find_all: (key, value) ->
    for model in @_array when model.get(key) == value then model

  #
  # filter collection with `fn`, which must return boolean
  # @param fn [Function]
  # @return [Array<Model>]
  filter: (fn = ->) ->
    for model in @_array when fn.call(null, model) then model

  #
  # Iterate over collection with function
  # @param fn [Function]
  each: (fn = ->) ->
    for model in @_array then fn.call(model)

  # return first element in collection
  # @return [Model]
  first: () ->
    @_array[0]

  # return last element in collection
  # @return [Model]
  last: () ->
    @_array[@_array.length - 1]

  # return actual collection
  # @return [Array<Model>]
  all: () ->
    @_array

  # Clear the collection
  clear: () ->
    @length = 0
    @_array = []


  # @return [Numeric] size of collection
  size: () ->
    @_array.length

  from_json: (json) ->
    j = JSON.stringify(json)
    if Sirius.Utils.is_array(j)
      for jj in j
        @_array.push(@_klass.from_json(jj))
        @length++
    else
      @_array.push(@_klass.from_json(json))
      @length++
    @

  # convert collection to json
  # @return [JSON]
  to_json: () ->
    z = for e in @_array then e.to_json()
    JSON.parse(JSON.stringify(z))



