
#
# @class
# @private
class Sirius.Promise

  constructor: (@value) ->
    @fn = () ->

  and_then: (fn) ->
    if @value?
      fn(@value)
    else
      @fn = fn

  set_value: (value) ->
    @value = value
    @fn(value)
