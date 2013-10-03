# Provides a set of rules that can be applied to a syntax tree.
#
# Not yet used
#
# This module will eventually be used to declaratively map keystrokes to
# commands based on the state of the syntax tree.

define (require) ->
	_ = require 'underscore'

	# TODO mark name capturing

	class ConstructRule
		# TODO Probably need to change markMap to editorState, or similar
		apply: (construct, markMap) ->
			throw new Error 'All ConstructRule implementations must override `apply`.'

	class TypeRule extends ConstructRule
		constructor: (@type) ->

		apply: (construct, markMap) ->
			if construct.matchesType @type
				return {}

			return null

	class MarkRule extends ConstructRule
		constructor: (@markName) ->

		apply: (construct, markMap) ->
			if markMap[@markName] is construct
				return {}

			return null

	class CaptureRule extends ConstructRule
		constructor: (@captureName, @rule) ->

		apply: (construct, markMap) ->
			result = @rule.apply construct, markMap

			unless result
				return null

			if @captureName of result
				throw new Error """
					Capture name conflict: #{JSON.stringify @captureName}
				"""

			result[@captureName] = construct

			return result

	class FirstChildRule extends ConstructRule
		constructor: (@rule) ->

		apply: (construct, markMap) ->
			if construct.getFirstChild
				firstChild = construct.getFirstChild()

				if firstChild
					return @rule.apply firstChild, markMap

			return null

	class LastChildRule extends ConstructRule
		constructor: (@rule) ->

		apply: (construct, markMap) ->
			if construct.getLastChild
				lastChild = construct.getLastChild()

				if lastChild
					return @rule.apply lastChild, markMap

			return null

	class NamedChildRule extends ConstructRule
		constructor: (@childName, @rule) ->

		apply: (construct, markMap) ->
			if construct.getNamedChild
				child = construct.getNamedChild @childName

				if child
					return @rule.apply child, markMap

			return null

	class RelationRule extends ConstructRule
		constructor: (@proximity, @type, @inclusive, @rule) ->
			unless @type in ['ancestor', 'descendent', 'earlierSibling', 'laterSibling']
				throw new Error 'Unknown relation type: ' + @type

			if @type in 'descendent'
				# TODO Investigate whether this relation type is actually needed.
				#      A descendent rule could require recursing through an entire
				#      subtree -- potentially devastating to performance in large
				#      documents.
				throw new Error 'Descendent relation rules are not available.'

			unless @proximity in ['immediate', 'closestMatching', 'farthestMatching']
				throw new Error 'Unknown proximity: ' + @proximity

		apply: (construct, markMap) ->
			switch @type
				when 'ancestor'
					propName = 'parent'
				when 'earlierSibling'
					propName = 'previousSibling'
				when 'laterSibling'
					propName = 'nextSibling'

			switch @proximity
				when 'immediate'
					if @inclusive
						result = @rule.apply construct, markMap

						if result
							return result

					return @rule.apply construct[propName], markMap

				when 'closestMatching'
					if @inclusive
						possibleMatch = construct
					else
						possibleMatch = construct[propName]

					while possibleMatch
						result = @rule.apply possibleMatch, markMap

						if result
							return result

						possibleMatch = possibleMatch[propName]

					return null

				when 'farthestMatching'
					possibleMatches = []

					if @inclusive
						current = construct
					else
						current = construct[propName]

					while current
						possibleMatches.push current

						current = current[propName]

					current = possibleMatches.pop()
					while current
						result = @rule.apply current, markMap

						if result
							return result

						current = possibleMatches.pop()

					return null

			throw new Error 'Error applying RelationRule.'

	class Wildcard extends ConstructRule
		constructor: ->

		apply: (construct, markMap) ->
			if construct
				return {}

			throw new Error 'No construct provided to rule.'

	# Logical AND
	class Conjunction extends ConstructRule
		constructor: (@rules) ->

		apply: (construct, markMap) ->
			result = {}

			for rule in @rules
				ruleResult = rule.apply construct, markMap

				unless ruleResult
					return null

				for k, v of ruleResult
					if k of result
						throw new Error "Capture name conflict: #{JSON.stringify k}"

					result[k] = v

			return result

	# Logical OR
	class Disjunction extends ConstructRule
		constructor: (@rules) ->

		# TODO Determine if this class is needed

	return {
		ConstructRule
		Wildcard
		Conjunction
		TypeRule
		MarkRule
		CaptureRule
		FirstChildRule
		LastChildRule
		NamedChildRule
		RelationRule
	}
