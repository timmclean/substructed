# A very basic renderer for JSON documents.
#
# This module provides a way of rendering a JSON syntax tree
# to text.
# It is expected that future implementations of this renderer
# will provide the ability to customize the formatting details
# of the output (allowing, for example, comma-first style).

define (require) ->
	{
		BlockElement
		InlineElement
		InlineSectionElement
		SectionElement
	} = require 'editor/core/render'

	mapConstructChildren = (construct, fn) ->
		result = []

		currentChild = construct.getFirstChild()
		i = 0

		while currentChild
			result.push fn(currentChild, i)
			currentChild = currentChild.nextSibling
			i++

		return result

	return {
		ObjectConstruct: (c, args...) ->
			if c.getFirstChild() is null
				return [new InlineElement('{}')]

			lastChild = c.getLastChild()

			return [
				new InlineElement '{'
				new BlockElement(
					mapConstructChildren(c, (child) =>
						new BlockElement(
							if child is lastChild
								child.render(@, args...)
							else
								[
									child.render(@, args...)...
									new InlineElement(',')
								]
						)
					), true
				)
				new InlineElement '}'
			]
		PropertyConstruct: (c, args...) -> [
			c.getNamedChild('key').render(@, args...)...
			new InlineElement ': '
			c.getNamedChild('value').render(@, args...)...
		]
		ArrayConstruct: (c, args...) ->
			if c.getFirstChild() is null
				return [new InlineElement('[]')]

			lastChild = c.getLastChild()

			return [
				new InlineElement '['
				new BlockElement(
					mapConstructChildren(c, (child) =>
						new BlockElement(
							if child is lastChild
								child.render @, args...
							else
								[
									child.render(@, args...)...
									new InlineElement(',')
								]
						)
					), true
				)
				new InlineElement ']'
			]
		StringConstruct: (c, args...) -> [
			new InlineElement '"'
			new InlineSectionElement 'editable', (c.text or '')
			new InlineElement '"'
		]
		NumberConstruct: (c, args...) -> [
			new InlineSectionElement 'editable', (c.text or '0')
		]
		TrueConstruct: (c, args...) -> [new InlineElement('true')]
		FalseConstruct: (c, args...) -> [new InlineElement('false')]
		NullConstruct: (c, args...) -> [new InlineElement('null')]
	}
