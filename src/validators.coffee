
# Base Validator class
class Sirius.Validator
  constructor: () ->
    @msg = null

  error_message: () ->
    @msg


# validate length for attribute
# @example
#   name: length: {min : 3, max: 10}
#   title: length : {length: 10 }
class Sirius.LengthValidator extends Sirius.Validator
  #@param [Any] value - current value
  #@param [Object] attributes object with [mix, max, length] keys
  #@return [Boolean]
  validate: (value, attributes) ->
    max = attributes['max'] || Number.POSITIVE_INFINITY
    min = attributes['min'] || Number.NEGATIVE_INFINITY
    length  = attributes['length']
    actual_length = value.length

    if length
      if actual_length == length
        true
      else
        @msg = "Required length: #{length}, given: #{actual_length}"
        false
    else
      if ((actual_length >= min) && (actual_length <= max))
        true
      else
        @msg = "Required length in range [#{min}..#{max}], given: #{actual_length}"
        false

#
# validate that value in not a `within` range
# @example
#   name: exclusion: {within: ["A", "B, "C"]}
class Sirius.ExclusionValidator extends Sirius.Validator
  #@param [Any] value
  #@param [Object] attributes - object with [within] key and range
  #@return [Boolean]
  validate: (value, attributes) ->
    range = attributes['within'] || []
    if range.indexOf(value) == -1
      true
    else
      @msg = "Value #{value} reserved"
      false

#
# check that value must exist in range
# @example
#   name: inclusion: {within: ["A", "B, "C"]}
class Sirius.InclusionValidator extends Sirius.Validator
  #@param [Any] value
  #@param [Object] attributes - object with [within] key and range
  #@return [Boolean]
  validate: (value, attributes) ->
    range = attributes['within'] || []
    if range.indexOf(value) > -1
      true
    else
      @msg = "Value #{value} should be in range #{range}"
      false
#
# check that value given format
#   name: format: {with: /\w+/}
#
class Sirius.FormatValidator extends Sirius.Validator
  #@param [Any] value
  #@param [Object] attributes - object with [with] key and regexp
  #@return [Boolean]
  validate: (value, attributes) ->
    format = attributes['with'] || throw new Error("format attribute required")
    if format.test(value)
      true
    else
      @msg = "Value #{value} not for current format"
      false

#
# check if value is a number or integer number
# @example
#  value : numericality : {only_integers: true}
#  value : numericality : {}
class Sirius.NumericalityValidator extends Sirius.Validator
  #@param [Any] value
  #@param [Object] attributes - object with [only_integers?] key
  #@return [Boolean]
  validate: (value, attributes = {}) ->
    if attributes['only_integers']
      if /^\d+$/.test(value)
        true
      else
        @msg = "Only allows integer numbers"
        false

    else
      if /^\d+(?:\.\d{1,})?$/.test(value)
        true
      else
        @msg = "Only allows numbers"
        false

#
# check if value exist
# @example:
#  value : presence: true
class Sirius.PresenceValidator extends Sirius.Validator
  #@param [Any] value
  #@param [Boolean] attributes
  #@return [Boolean]
  validate: (value, attributes = true) ->
    if value
      true
    else
      @msg = "Value required"
      false












