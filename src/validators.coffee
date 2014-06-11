

class Validator
  constructor: () ->
    @msg = null

  error_message: () ->
    @msg

class LengthValidator extends Validator
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


class ExclusionValidator extends Validator
  validate: (value, attributes) ->
    range = attributes['within'] || []
    if range.indexOf(value) == -1
      true
    else
      @msg = "Value #{value} reserved"
      false


class InclusionValidator extends Validator
  validate: (value, attributes) ->
    range = attributes['within'] || []
    if range.indexOf(value) > -1
      true
    else
      @msg = "Value #{value} should be in range #{range}"
      false

class FormatValidator extends Validator
  validate: (value, attributes) ->
    format = attributes['with'] || throw new Error("format attribute required")
    if format.test(value)
      true
    else
      @msg = "Value #{value} not for current format"
      false

class NumericalityValidator extends Validator
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


        











