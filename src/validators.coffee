
#
# @abstract
#
# Base class for implement all Validators
#
class Sirius.Validator
  constructor: () ->
    @logger = Sirius.Application.get_logger()
    @msg = null

  #
  # Return an error when a value is not valid
  # @return [String] - message
  error_message: () ->
    @msg

# Length validator
#
# @example
#   attr0 : length: {min: 10}
#   attr1 : length: {max: 25}
#   attr2 : length: {min: 10, max: 30}
#   attr4 : length: {length: 10}
class Sirius.LengthValidator extends Sirius.Validator
  #
  # @param [Any] value - current value
  # @param [Object] attributes - options for validator [min, max, length]
  #
  # Attribute keys:
  # + min - min length for a `value`
  # + max - max length for a `value`
  # + length - define length which must be have a `value`
  #
  # @return [Boolean]
  validate: (value, attributes) ->
    @logger.info("LengthValidator: start validate '#{value}'", @logger.validation)
    if value?
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
          @msg = "Required length in range [0..#{max}], given: #{actual_length}"
          false
    else
      @msg = "Given null for LengthValidator"
      false


# Validate value which be excluded in a range, range can be defined with `within` option.
#
# @example
#   letter: exclusion: {within: ["A", "B, "C"]}
class Sirius.ExclusionValidator extends Sirius.Validator
  #
  # @param [Any] value for validation
  # @param [Object] attributes - object with range, range should be defined with `within` property
  # @return [Boolean]
  validate: (value, attributes) ->
    @logger.info("ExclusionValidator: start validate '#{value}'", @logger.validation)
    range = attributes['within'] || []
    if range.indexOf(value) == -1
      true
    else
      @msg = "Value #{value} reserved"
      false

# Validate value which be included in a range, which define with `within` option.
#
# @example
#   letter: inclusion: {within: ["A", "B, "C"]}
class Sirius.InclusionValidator extends Sirius.Validator
  #
  # @param [Any] value - value for validation
  # @param [Object] attributes - object with range, range should be defined `within` property
  # @return [Boolean]
  validate: (value, attributes) ->
    @logger.info("InclusionValidator: start validate '#{value}'", @logger.validation)
    range = attributes['within'] || []
    if range.indexOf(value) > -1
      true
    else
      @msg = "Value #{value} should be in range #{range}"
      false

# Format validator
#
# @example
#   name: format: {with: /\w+/}
class Sirius.FormatValidator extends Sirius.Validator
  #
  # @param [Any] value - value for validation
  # @param [Object] attributes - object with format, format should be defined with `format` key.
  # @return [Boolean]
  validate: (value, attributes) ->
    @logger.info("FormatValidator: start validate '#{value}'", @logger.validation)
    format = attributes['with'] || throw new Error("format attribute required")
    if value?
      if format.test(value)
        true
      else
        @msg = "Value #{value} not in current format"
        false
    else
      @msg = "Given null for Format"
      false

# Check if value is a number or an integer number
#
# @example
#   value : numericality : {only_integers: true}
#   value : numericality : {}
class Sirius.NumericalityValidator extends Sirius.Validator
  #
  # @param [Any] value - value for validation
  # @param [Object] attributes - object with `only_integers` property
  # @return [Boolean]
  validate: (value, attributes = {}) ->
    @logger.info("NumericalityValidator: start validate '#{value}'", @logger.validation)
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

# Check if value exist
#
# @example
#   value : presence: true
class Sirius.PresenceValidator extends Sirius.Validator
  #
  # @param [Any] value - value for valiation
  # @param [Boolean] attributes
  # @return [Boolean]
  validate: (value, attributes = true) ->
    @logger.info("PresenceValidator: start validate '#{value}'", @logger.validation)
    if value
      true
    else
      @msg = "Value required"
      false












