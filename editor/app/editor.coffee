# A web-based editor based on Substructed.
#
# This JSON-only prototype is intended is a first step
# towards a full, multi-language code editor.

# TODO text tab
# TODO styling
# TODO set up website + blog
# TODO write blog post
# TODO set up GitHub repo

# Future:
# TODO show errors to user
# TODO arrow keys

# Farther future:
# TODO fix scrolling
# TODO prefix commands with number
# TODO selection
# TODO customizable key mappings
# TODO test Unicode support in text fields

define (require) ->
	return ->
		$ = require 'jquery'
		handlebars = require 'handlebars'
		jsonSyntax = require 'editor/core/language/json'
		jsonRenderer = require 'editor/core/language/jsonRenderer'

		{
			ConstructWithText
			ConstructWithChildren
			ConstructWithNamedChildren
			Blank
		} = require 'editor/core/syntax'
		{renderTextElements} = require 'editor/core/render'

		{KeyDispatcher} = require 'editor/app/keyboard'

		buildTree = ->
			return jsonSyntax.parse '''
				{
					"name": "Waterloo",
					"near": [
						"Kitchener",
						"Mississauga",
						"Toronto"
					],
					"population": 98780,
					"area": {
						"unit": "square kilometers",
						"value": 64.10
					},
					"province": "Ontario",
					"country": "Canada",
					"notes": null
				}
			'''

		ObjectConstruct = jsonSyntax.findConstructType 'ObjectConstruct'
		PropertyConstruct = jsonSyntax.findConstructType 'PropertyConstruct'
		ArrayConstruct = jsonSyntax.findConstructType 'ArrayConstruct'
		StringConstruct = jsonSyntax.findConstructType 'StringConstruct'
		NumberConstruct = jsonSyntax.findConstructType 'NumberConstruct'
		TrueConstruct = jsonSyntax.findConstructType 'TrueConstruct'
		FalseConstruct = jsonSyntax.findConstructType 'FalseConstruct'
		NullConstruct = jsonSyntax.findConstructType 'NullConstruct'

		rootConstruct = buildTree()
		selection = rootConstruct.getFirstChild()
		defaultRegisterValue = null
		mode = 'command'

		render = ->
			renderGuide = (title, description, definitions) ->
				html = '<div class="guide">'

				html += '<h1>'
				html += title
				html += '</h1>'

				html += '<p>'
				html += description
				html += '</p>'

				if definitions?.length
					html += '<dl>'

					for def in definitions
						html += '<div class="'
						unless def.available? and def.available is false
							html += 'available'
						html += '">'

						html += '<dt>'
						html += def.keys
						html += '</dt>'

						html += '<dd>'
						html += def.desc
						html += '</dd>'

						html += '</div>'

					html += '</dl>'

				html += '</div>'
				return html

			renderLine = (line) ->
				html = ''

				html += '<div class="line">'

				for chunk in line.chunks
					html += '<span class="'
					html += chunk.sections.join(' ')
					html += '">'

					escapedText = handlebars.Utils.escapeExpression chunk.text
					escapedText = escapedText.split(' ').join('&nbsp;')
					html += escapedText

					html += '</span>'

				html += '<span class="postfill'
				if line.trailingSections?.length
					html += ' '
					html += line.trailingSections.join(' ')
				html += '"></span>'

				html += '</div>'

				return html

			textElems = rootConstruct.render(jsonRenderer, [selection])
			renderedText = renderTextElements textElems

			html = ''

			switch mode
				when 'command'
					isBlank = selection instanceof Blank
					hasText = selection instanceof ConstructWithText
					hasChildren = selection instanceof ConstructWithChildren
					hasNamedChildren = selection instanceof ConstructWithNamedChildren
					parentHasChildren =
						selection.parent? and
						selection.parent instanceof ConstructWithChildren

					html += renderGuide(
						'Command mode',
						'''
							Use command mode to navigate and manipulate the syntax tree.
							A single register (i.e. clipboard) is available for copy/paste.
						''',
						[
							{
								keys: "Enter"
								desc: "move cursor inside the construct under the cursor"
								available: isBlank or hasText or hasChildren or hasNamedChildren
							}
							{
								keys: "Escape"
								desc: "move cursor to parent construct"
								available: selection.parent?
							}
							{
								keys: "J"
								desc: "move cursor to next construct"
								available: selection.nextSibling?
							}
							{
								keys: "Shift-J"
								desc: "move cursor to last construct"
								available: selection.nextSibling?
							}
							{
								keys: "K"
								desc: "move cursor to previous construct"
								available: selection.previousSibling?
							}
							{
								keys: "Shift-K"
								desc: "move cursor to first construct"
								available: selection.previousSibling?
							}
							{
								keys: "D"
								desc: "delete construct under cursor, but keep copy in register"
								available: not isBlank
							}
							{
								keys: "C"
								desc: "same as D, then switch to write mode"
							}
							{
								keys: "O"
								desc: "place blank after construct under cursor and switch to write mode"
								available: parentHasChildren
							}
							{
								keys: "Shift-O"
								desc: "place blank before construct under cursor and switch to write mode"
								available: parentHasChildren
							}
							{
								keys: "N"
								desc: "alias for J Enter"
								available:
									selection.nextSibling? and
									(
										selection.nextSibling instanceof ConstructWithText or
										selection.nextSibling instanceof ConstructWithChildren or
										selection.nextSibling instanceof ConstructWithNamedChildren
									)
							}
							{
								keys: "Y"
								desc: "copy construct under cursor to register"
								available: not isBlank
							}
							{
								keys: "P"
								desc: "place construct in register after construct under cursor"
								available: parentHasChildren and defaultRegisterValue?
							}
							{
								keys: "Shift-P"
								desc: "place construct in register before construct under cursor"
								available: parentHasChildren and defaultRegisterValue?
							}
							{
								keys: "R"
								desc: "swap construct under cursor with construct in register"
								available: defaultRegisterValue?
							}
							{
								keys: "A"
								desc: "append construct in register to children of construct under cursor"
								available: hasChildren and defaultRegisterValue?
							}
						]
					)
				when 'write'
					isOnlyString =
						selection.parent and
						selection.parent instanceof PropertyConstruct and
						selection.childName is 'key'
					isOnlyProperty =
						selection.parent and
						selection.parent instanceof ObjectConstruct
					isAnyValue = (not isOnlyString) and (not isOnlyProperty)

					html += renderGuide(
						"Write mode",
						"Use write mode to insert new constructs into the syntax tree.",
						[
							{
								keys: "Escape"
								desc: "return to command mode"
								available: true
							}
							{
								keys: "O"
								desc: "write an object"
								available: isAnyValue
							}
							{
								keys: "P"
								desc: "write an object property"
								available: isOnlyProperty
							}
							{
								keys: "A"
								desc: "write an array"
								available: isAnyValue
							}
							{
								keys: "S"
								desc: "write a string"
								available: isOnlyString or isAnyValue
							}
							{
								keys: "N"
								desc: "write a number"
								available: isAnyValue
							}
							{
								keys: "T"
								desc: "write true"
								available: isAnyValue
							}
							{
								keys: "F"
								desc: "write false"
								available: isAnyValue
							}
							{
								keys: "X"
								desc: "write null"
								available: isAnyValue
							}
						]
					)
				when 'textConstruct'
					html += renderGuide(
						"Text edit mode",
						"""
							Use text edit mode to change the text content of a construct
							(such as a JSON string or number).
							Most keys produce their literal character in this mode.
						""",
						[
							{
								keys: "Escape"
								desc: "return to command mode"
								available: true
							}
						]
					)
			html += '</div>'

			switch mode
				when 'text'
					html += '<textarea>'
					for line in renderedText.lines
						for chunk in line.chunks
							html += handlebars.Utils.escapeExpression chunk.text

						html += '\n'
					html += '</textarea>'

					$('header .toggleText.button').text 'Back to editor (Ctrl-E)'
				else
					for line in renderedText.lines
						html += renderLine line

					$('header .toggleText.button').text 'Edit as text (Ctrl-E)'

			$('.editor').html html

			if mode is 'text'
				$('.editor > textarea').focus()

			if mode is 'textConstruct'
				textField = $('.editor .selection.editable')
				textField.attr 'contenteditable', 'true'
				textField.focus()

		keyDispatcher = new KeyDispatcher()

		registerKey = (mode, keyName, ctrl, alt, shift, onKey) ->
			keyDispatcher.addListener {
				mode
				keyName
				ctrl
				alt
				shift
				onKey: ->
					onKey()
					render()
			}

		attemptMove = (propName) ->
			if selection[propName]
				selection = selection[propName]

		accessNamedChild = (childName) ->
			if selection.getNamedChild and selection.getNamedChild(childName)
				selection = selection.getNamedChild(childName)
				moveIn()

		registerKey 'command', 'j', no, no, no, ->
			attemptMove 'nextSibling'

		registerKey 'command', 'j', no, no, yes, ->
			if selection.parent?.getLastChild
				selection = selection.parent.getLastChild()

		registerKey 'command', 'k', no, no, no, ->
			attemptMove 'previousSibling'

		registerKey 'command', 'k', no, no, yes, ->
			if selection.parent?.getFirstChild
				selection = selection.parent.getFirstChild()

		registerKey 'command', 'escape', no, no, no, ->
			attemptMove 'parent'
		registerKey 'write', 'escape', no, no, no, ->
			if selection instanceof Blank and selection.parent?.removeChild
				newSel = selection.previousSibling or
						 selection.nextSibling or
						 selection.parent
				selection.parent.removeChild selection
				selection = newSel

			mode = 'command'

		moveIn = ->
			if selection.getFirstChild
				if selection.getFirstChild()
					selection = selection.getFirstChild()
				else
					newSel = new Blank()
					selection.appendChild newSel
					selection = newSel
					mode = 'write'
			else if selection instanceof Blank
				mode = 'write'
			else if selection instanceof ConstructWithText
				mode = 'textConstruct'

		registerKey 'command', 'enter', no, no, no, ->
			moveIn()

		registerKey 'command', 'v', no, no, yes, ->
			accessNamedChild 'key'

		registerKey 'command', 'v', no, no, no, ->
			accessNamedChild 'value'

		findNearestAncestorWithVariableSiblings = ->
			current = selection

			while current?.parent
				if current.parent instanceof ConstructWithChildren
					return current

				current = current.parent

			return null

		registerKey 'command', 'o', no, no, yes, ->
			ancestor = findNearestAncestorWithVariableSiblings()

			if ancestor
				newSel = new Blank()
				ancestor.parent.insertChildBefore newSel, ancestor
				selection = newSel
				mode = 'write'

		registerKey 'command', 'o', no, no, no, ->
			ancestor = findNearestAncestorWithVariableSiblings()

			if ancestor
				newSel = new Blank()
				ancestor.parent.insertChildAfter newSel, ancestor
				selection = newSel
				mode = 'write'

		registerKey 'write', 'o', no, no, no, ->
			writeConstruct new ObjectConstruct()

		registerKey 'command', 'd', no, no, no, ->
			if selection instanceof Blank
				throw new Error 'Cannot delete a blank'

			if selection.parent?.setNamedChild
				newSel = new Blank()
				selection.parent.replaceChild selection, newSel
			else if selection.parent?.removeChild
				newSel = selection.nextSibling or
						 selection.previousSibling or
						 selection.parent
				selection.parent.removeChild selection
			else
				rootConstruct = new Blank()
				newSel = rootConstruct

			defaultRegisterValue = selection
			selection = newSel

		registerKey 'command', 'c', no, no, no, ->
			mode = 'write'

			unless selection instanceof Blank
				newSel = new Blank()

				defaultRegisterValue = selection
				if selection.parent?
					selection.parent.replaceChild selection, newSel
				else
					rootConstruct = newSel

				selection = newSel

		registerKey 'command', 'y', no, no, no, ->
			unless selection instanceof Blank
				defaultRegisterValue = selection.clone()

		registerKey 'command', 'p', no, no, no, ->
			unless defaultRegisterValue
				throw new Error 'Default register is empty.'

			unless selection.parent instanceof ConstructWithChildren
				throw new Error '''
					Cannot paste inside construct with a fixed number of children.
				'''

			newSel = defaultRegisterValue.clone()

			selection.parent.insertChildAfter newSel, selection

			selection = newSel

		registerKey 'command', 'p', no, no, yes, ->
			unless defaultRegisterValue
				throw new Error 'Default register is empty.'

			unless selection.parent instanceof ConstructWithChildren
				throw new Error '''
					Cannot paste inside construct with a fixed number of children.
				'''

			newSel = defaultRegisterValue.clone()

			selection.parent.insertChildBefore newSel, selection

			selection = newSel

		registerKey 'command', 'a', no, no, no, ->
			unless defaultRegisterValue
				throw new Error 'Default register is empty.'

			unless selection instanceof ConstructWithChildren
				throw new Error '''
					Cannot paste inside construct with a fixed number of children.
				'''

			selection.appendChild defaultRegisterValue.clone()

		registerKey 'command', 'r', no, no, no, ->
			unless defaultRegisterValue
				throw new Error 'Default register is empty.'

			newSel = defaultRegisterValue

			unless selection instanceof Blank
				defaultRegisterValue = selection.clone()

			if selection.parent
				selection.parent.replaceChild selection, newSel
			else
				rootConstruct = newSel

			selection = newSel

		writeConstruct = (newConstruct) ->
			if selection.parent
				selection.parent.replaceChild selection, newConstruct
				selection = newConstruct
			else
				rootConstruct = newConstruct
				selection = newConstruct

			mode = 'command'

			moveIn()

			if newConstruct instanceof ConstructWithNamedChildren
				moveIn()

		registerKey 'write', 'p', no, no, no, ->
			writeConstruct new PropertyConstruct()

		registerKey 'write', 'a', no, no, no, ->
			writeConstruct new ArrayConstruct()

		registerKey 'write', 's', no, no, no, ->
			writeConstruct new StringConstruct()

		registerKey 'command', 'n', no, no, no, ->
			if selection.nextSibling
				selection = selection.nextSibling
				moveIn()

		registerKey 'write', 'n', no, no, no, ->
			writeConstruct new NumberConstruct()

		registerKey 'write', 't', no, no, no, ->
			writeConstruct new TrueConstruct()

		registerKey 'write', 'f', no, no, no, ->
			writeConstruct new FalseConstruct()

		registerKey 'write', 'x', no, no, no, ->
			writeConstruct new NullConstruct()

		registerKey 'textConstruct', 'escape', no, no, no, ->
			providedText = $('.editor .selection.editable').text()
			if selection.isValidInput providedText
				selection.text = providedText

			mode = 'command'

		registerKey 'command', 'e', yes, no, no, ->
			toggleTextMode()

		registerKey 'text', 'e', yes, no, no, ->
			toggleTextMode()

		toggleTextMode = ->
			switch mode
				when 'text'
					rootConstruct = jsonSyntax.parse $('.editor > textarea').val()
					selection = rootConstruct
					mode = 'command'
				else
					mode = 'text'

		$ ->
			render()

			$('body').on 'keydown', (event) ->
				keyDispatcher.dispatch event, mode

			$('header .toggleText.button').on 'click', (event) ->
				event.preventDefault()

				toggleTextMode()

				render()
