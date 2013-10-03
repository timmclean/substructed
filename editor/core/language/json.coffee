# A grammar definition and parser for the JSON language.
#
# This module defines the types of constructs that may appear
# in the syntax tree of a JSON document.
# The parser also describes how to construct a syntax tree
# from raw JSON text.
#
# See also: editor/core/syntax

define (require) ->
	_ = require 'underscore'

	{
		Syntax
		ConstructTypeAlias
		Construct
		ConstructWithText
		ConstructWithChildren
		ConstructWithNamedChildren
		NamedChildDefinition
	} = require 'editor/core/syntax'

	class StringConstruct extends ConstructWithText
		REGEX = /^(?:[^\\"]|\\["\\/bfnrt]|\\u[0-9a-fA-F]{4})*$/

		isValidInput: (text) ->
			return !!REGEX.exec(text)

	class NumberConstruct extends ConstructWithText
		REGEX = /^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?$/

		isValidInput: (text) ->
			return !!REGEX.exec(text)

	class NullConstruct extends Construct

	class TrueConstruct extends Construct
	class FalseConstruct extends Construct
	BooleanConstruct = new ConstructTypeAlias [TrueConstruct, FalseConstruct]

	class ArrayConstruct extends ConstructWithChildren
		constructor: ->
			super ValueConstruct

	class PropertyConstruct extends ConstructWithNamedChildren
		constructor: ->
			super [
				new NamedChildDefinition('key', StringConstruct)
				new NamedChildDefinition('value', ValueConstruct)
			]
	class ObjectConstruct extends ConstructWithChildren
		constructor: ->
			super PropertyConstruct

	ValueConstruct = new ConstructTypeAlias [
		ArrayConstruct
		ObjectConstruct
		StringConstruct
		NumberConstruct
		BooleanConstruct
		NullConstruct
	]

	constructTypes = [
		NullConstruct
		TrueConstruct
		FalseConstruct
		StringConstruct
		NumberConstruct
		ArrayConstruct
		PropertyConstruct
		ObjectConstruct
	]

	parser = (code) ->
		convertParsed = (parsed) ->
			convertParsedField = (key, value, index) ->
				result = new PropertyConstruct()

				result.setNamedChild 'key', convertParsed key
				result.setNamedChild 'value', convertParsed value

				return result

			if _.isArray parsed
				result = new ArrayConstruct()

				for elem in parsed
					result.appendChild convertParsed elem

				return result

			if _.isObject parsed
				result = new ObjectConstruct()

				for key, value of parsed
					prop = new PropertyConstruct()

					prop.setNamedChild 'key', convertParsed key
					prop.setNamedChild 'value', convertParsed value

					result.appendChild prop

				return result

			if _.isString parsed
				result = new StringConstruct()
				result.text = JSON.stringify(parsed)[1...-1]
				return result

			if _.isNumber parsed
				result = new NumberConstruct()
				result.text = parsed + ''
				return result

			if _.isBoolean parsed
				return if parsed then new TrueConstruct() else new FalseConstruct()

			if _.isNull parsed
				return new NullConstruct()

		return convertParsed JSON.parse(code)

	return new Syntax ValueConstruct, constructTypes, parser
