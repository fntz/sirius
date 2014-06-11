

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
      