# TODO docs

define (require) ->
	_ = require 'underscore'

	class InlineElement
		constructor: (@text) ->

	class BlockElement
		constructor: (@children, @indent=false) ->

	class InlineSectionElement
		constructor: (@name, @text) ->

	class SectionElement
		constructor: (@name, @children) ->

	renderTextElements = (textElems) ->
		lines = []
		currentLineIndent = null
		currentLineChunks = []
		currentChunk = ''

		openSections = []
		openSectionsDuringIndent = []

		flushLineChunk = ->
			if currentChunk
				currentLineChunks.push {
					text: currentChunk
					sections: openSections
				}

			currentChunk = ''

		flushLine = ->
			flushLineChunk()

			if currentLineChunks.length
				if currentLineIndent
					currentLineChunks = [
						{
							text: new Array(4 * currentLineIndent + 1).join(' ')
							sections: openSectionsDuringIndent
						}
						currentLineChunks...
					]

				lines.push {
					chunks: currentLineChunks
					trailingSections: openSections
				}

			currentLineIndent = null
			currentLineChunks = []
			openSectionsDuringIndent = openSections

		renderElems = (elems, currentIndent) ->
			for elem in elems
				if elem instanceof InlineElement
					currentChunk += elem.text

					if currentLineIndent? and currentLineIndent isnt currentIndent
						throw new Error 'Conflicting indentation'

					currentLineIndent = currentIndent
				else if elem instanceof BlockElement
					if elem.indent
						newIndent = currentIndent+1
					else
						newIndent = currentIndent

					flushLine()
					renderElems elem.children, newIndent
					flushLine()
				else if elem instanceof InlineSectionElement
					flushLineChunk()

					currentLineChunks.push {
						text: elem.text
						sections: [openSections..., elem.name]
					}

					if currentLineIndent? and currentLineIndent isnt currentIndent
						throw new Error 'Conflicting indentation'

					currentLineIndent = currentIndent
				else if elem instanceof SectionElement
					flushLineChunk()
					openSections = [openSections..., elem.name]

					renderElems elem.children, currentIndent

					flushLineChunk()

					if openSections[openSections.length - 1] isnt elem.name
						throw new Error("""
							Expected to pop section #{elem.name} but found #{poppedSectionName}
						""")

					openSections = openSections[...-1]

		renderElems textElems, 0
		flushLine()

		return {lines}

	return {
		BlockElement
		InlineElement
		InlineSectionElement
		SectionElement
		renderTextElements
	}
