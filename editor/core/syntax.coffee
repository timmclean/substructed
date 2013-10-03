# TODO docs

define (require) ->
	_ = require 'underscore'

	{InlineElement, SectionElement} = require 'editor/core/render'

	class Syntax
		constructor: (@rootConstructType, constructTypes, @_parser) ->
			@_constructTypes = {Blank}

			for ct in constructTypes
				@_constructTypes[ct.name] = ct

		findConstructType: (typeName) ->
			if typeName not of @_constructTypes
				throw new Error("""
					No construct type with name #{JSON.stringify typeName}.
				""")

			return @_constructTypes[typeName]

		parse: (code) ->
			return @_parser code

	class NamedChildDefinition
		constructor: (@name, @constructType) ->

	class ConstructTypeAlias
		constructor: (@aliasedTypes) ->
			unless _.isArray @aliasedTypes
				throw new Error "Expected array but received #{@aliasedTypes}"

		isInstance: (construct) ->
			for type in @aliasedTypes
				if construct.matchesType type
					return true

			return false

	class Construct
		constructor: ->
			# These fields are set by parent construct
			@parent = null
			@nextSibling = null
			@previousSibling = null
			@childName = null

		matchesType: (type) ->
			if type instanceof ConstructTypeAlias
				return type.isInstance @

			return @ instanceof type

		isRoot: ->
			if @parent or @nextSibling or @previousSibling
				return false

			return true

		assertRoot: ->
			if not @isRoot
				throw new Error('Construct must be cloned before reuse')

		assertChild: (construct) ->
			if construct.parent isnt @
				throw new Error('This is not my child!')

		clone: -> new @constructor()

		render: (renderer, selectedConstructs) ->
			if @ in selectedConstructs
				return [
					new SectionElement(
						'selection'
						renderer[@constructor.name](@, selectedConstructs)
					)
				]

			return renderer[@constructor.name](@, selectedConstructs)

	class ConstructWithText extends Construct
		constructor: ->
			super()

			@text = null

		clone: ->
			result = new @constructor()
			result.text = @text
			return result

		isValidInput: (text) ->
			throw new Error 'Subclasses must provide input validator.'

	class ConstructWithChildren extends Construct
		constructor: (@childType) ->
			super()

			@_firstChild = null
			@_lastChild = null

		_assertCorrectChildType: (newChild) ->
			unless newChild.matchesType(@childType) or newChild instanceof Blank
				throw new Error("""
					New child construct is not of type #{@childType.name}
				""")

		clone: ->
			result = new @constructor()

			currentChild = @_firstChild
			while currentChild
				result.appendChild currentChild.clone()
				currentChild = currentChild.nextSibling

			return result

		getFirstChild: ->
			return @_firstChild

		getLastChild: ->
			return @_lastChild

		prependChild: (newChild) ->
			newChild.assertRoot()
			@_assertCorrectChildType newChild

			newChild.parent = @

			childAfter = @_firstChild

			if childAfter
				newChild.nextSibling = childAfter
				childAfter.previousSibling = newChild
			else
				if @_lastChild
					throw new Error "Last child but no first child."

				@_lastChild = newChild

			@_firstChild = newChild

			return

		appendChild: (newChild) ->
			newChild.assertRoot()
			@_assertCorrectChildType newChild

			newChild.parent = @

			childBefore = @_lastChild
			if childBefore
				childBefore.nextSibling = newChild
				newChild.previousSibling = childBefore
			else
				if @_firstChild
					throw new Error "First child but no last child."

				@_firstChild = newChild

			@_lastChild = newChild

			return

		insertChildBefore: (newChild, existingChild) ->
			newChild.assertRoot()
			@_assertCorrectChildType newChild
			@assertChild existingChild

			newChild.parent = @

			childBefore = existingChild.previousSibling
			childAfter = existingChild

			if childBefore
				childBefore.nextSibling = newChild
			else
				@_firstChild = newChild

			newChild.previousSibling = childBefore
			newChild.nextSibling = childAfter

			childAfter.previousSibling = newChild

			return

		insertChildAfter: (newChild, existingChild) ->
			newChild.assertRoot()
			@_assertCorrectChildType newChild
			@assertChild existingChild

			newChild.parent = @

			childBefore = existingChild
			childAfter = existingChild.nextSibling

			childBefore.nextSibling = newChild

			newChild.previousSibling = childBefore
			newChild.nextSibling = childAfter

			if childAfter
				childAfter.previousSibling = newChild
			else
				@_lastChild = newChild

			return

		replaceChild: (existingChild, newChild) ->
			newChild.assertRoot()
			@_assertCorrectChildType newChild
			@assertChild existingChild

			newChild.parent = @

			childBefore = existingChild.previousSibling
			childAfter = existingChild.nextSibling

			if childBefore
				childBefore.nextSibling = newChild
			else
				@_firstChild = newChild

			newChild.previousSibling = childBefore
			newChild.nextSibling = childAfter

			if childAfter
				childAfter.previousSibling = newChild
			else
				@_lastChild = newChild

			return

		removeChild: (existingChild) ->
			@assertChild existingChild

			childBefore = existingChild.previousSibling
			childAfter = existingChild.nextSibling

			if childBefore
				childBefore.nextSibling = childAfter
			else
				@_firstChild = childAfter

			if childAfter
				childAfter.previousSibling = childBefore
			else
				@_lastChild = childBefore

			existingChild.parent = null
			existingChild.previousSibling = null
			existingChild.nextSibling = null

			return

	class ConstructWithNamedChildren extends Construct
		constructor: (@childDefinitions) ->
			super()

			if @childDefinitions.length < 1
				throw new Error("A construct cannot have zero named children.")

			@_childDefinitionMap = {}
			for def in @childDefinitions
				@_childDefinitionMap[def.name] = def

			children = {}

			previous = null
			for c in @childDefinitions
				current = new Blank()
				current.parent = @
				current.childName = c.name

				if previous
					previous.nextSibling = current
					current.previousSibling = previous

				children[c.name] = current
				previous = current

			@_children = children

		_assertCorrectChildType: (name, newChild) ->
			requiredType = @_childDefinitionMap[name].constructType

			unless newChild.matchesType(requiredType) or newChild instanceof Blank
				throw new Error("""
					New child construct is not of type #{requiredType}
				""")

		clone: ->
			result = new @constructor()

			for def in @childDefinitions
				result.setNamedChild def.name, @_children[def.name].clone()

			return result

		getNamedChild: (name) ->
			return @_children[name] or null

		setNamedChild: (name, newChild) ->
			newChild.assertRoot()
			@_assertCorrectChildType name, newChild

			oldChild = @_children[name]

			unless oldChild
				throw new Error("Undefined child name #{JSON.stringify name}")

			childBefore = oldChild.previousSibling
			childAfter = oldChild.nextSibling

			oldChild.parent = null
			oldChild.childName = null
			oldChild.previousSibling = null
			oldChild.nextSibling = null

			newChild.parent = @
			newChild.childName = name

			if childBefore
				childBefore.nextSibling = newChild

			newChild.previousSibling = childBefore
			newChild.nextSibling = childAfter

			if childAfter
				childAfter.previousSibling = newChild

			@_children[name] = newChild

			return

		replaceChild: (existingChild, newChild) ->
			@assertChild existingChild

			@setNamedChild existingChild.childName, newChild

			return

		getFirstChild: ->
			firstChildName = _.first(@childDefinitions).name
			return @_children[firstChildName]

		getLastChild: ->
			lastChildName = _.last(@childDefinitions).name
			return @_children[lastChildName]

			NamedChildrenConstruct.__proto__ = NamedChildrenConstructType.prototype
			NamedChildrenConstruct.typeName = typeName

			return NamedChildrenConstruct

	class Blank extends Construct
		render: (renderer, args...) ->
			blankRenderer = (c) ->
				return [
					new InlineElement ' \u25C6 ' # unicode diamond
				]

			return super({Blank: blankRenderer}, args...)

	return {
		Syntax
		NamedChildDefinition
		ConstructTypeAlias
		Construct
		ConstructWithText
		ConstructWithChildren
		ConstructWithNamedChildren
		Blank
	}
