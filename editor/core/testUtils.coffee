define (require) ->
	_ = require 'underscore'

	assert = (condition, description, _context) ->
		unless condition
			if _context
				message = "at #{_context}, #{description}"
			else
				message = description

			throw new Error(message)

	getSortedKeys = (obj) ->
		return _.sortBy(_.keys(obj), (k) -> k)

	assertEqual = (actual, expected, _context='root') ->
		if _.isArray expected
			assert _.isArray(actual), "expected array but found #{actual}", _context
			assert(
				actual.length is expected.length,
				"unexpected array length: expected #{expected}, but found #{actual}",
				_context
			)

			for i in [0...expected.length]
				assertEqual actual[i], expected[i], _context + "[#{i}]"
		else if _.isObject expected
			assert _.isObject(actual), "expected object but found #{actual}", _context
			assertEqual getSortedKeys(actual), getSortedKeys(expected), _context + ".keys"

			for k in _.keys(expected)
				assertEqual actual[k], expected[k], _context + "[#{JSON.stringify(k)}]"
		else if _.isString expected
			assert _.isString(actual), "expected string but found #{actual}", _context
			assert(
				actual is expected,
				"expected #{JSON.stringify(expected)} but found #{JSON.stringify(actual)}",
				_context
			)
		else if _.isNumber expected
			assert _.isNumber(actual), "expected number but found #{actual}", _context
			assert(
				actual is expected,
				"expected #{expected} but found #{actual}",
				_context
			)
		else if _.isBoolean expected
			assert _.isBoolean(actual), "expected boolean but found #{actual}", _context
			assert(
				actual is expected,
				"expected #{expected} but found #{actual}",
				_context
			)
		else
			assert(
				actual is expected,
				"expected #{expected} but found #{actual}",
				_context
			)

	return {assertEqual}

