define (require) ->
	syntax = require 'editor/core/syntax'
	{
		Syntax
		NamedChildDefinition
		ConstructTypeAlias
		Construct
		ConstructWithText
		ConstructWithChildren
		ConstructWithNamedChildren
		Blank
	} = syntax

	testUtils = require 'editor/core/testUtils'
	{assertEqual} = testUtils

	assert = require('chai').assert

	assertChildren = (parent, expectedChildren) ->
		toArray = (first, nextPropName) ->
			result = []

			current = first
			while current
				result.push current
				current = current[nextPropName]

			return result

		actualForwards = toArray parent.getFirstChild(), 'nextSibling'
		assert.strictEqual actualForwards.length, expectedChildren.length

		actualBackwards = toArray parent.getLastChild(), 'previousSibling'
		actualBackwards.reverse()
		assert.strictEqual actualBackwards.length, expectedChildren.length

		for i in [0...expectedChildren.length]
			assert actualForwards[i] is expectedChildren[i]
			assert actualBackwards[i] is expectedChildren[i]

	return {
		syntaxHasBlankType: ->
			s = new Syntax null, []
			assert s.findConstructType 'Blank'
		constructTypeInheritance: ->
			class FirstNameConstruct extends ConstructWithText
			class LastNameConstruct extends ConstructWithText

			fn = new FirstNameConstruct()
			ln = new LastNameConstruct()

			assert fn instanceof ConstructWithText
			assert ln instanceof ConstructWithText

			assert fn instanceof FirstNameConstruct
			assert fn not instanceof LastNameConstruct
			assert ln instanceof LastNameConstruct
			assert ln not instanceof FirstNameConstruct

			assert fn.parent is null
			assert fn.nextSibling is null
			assert fn.previousSibling is null
			assert fn.childName is null
		constructInstanceOf: ->
			class FirstNameConstruct extends ConstructWithText
			class LastNameConstruct extends ConstructWithText

			NamePartConstruct = new ConstructTypeAlias [FirstNameConstruct, LastNameConstruct]

			c = new FirstNameConstruct()

			assert c.matchesType(FirstNameConstruct), 'type match'
			assert c.matchesType(NamePartConstruct), 'alias match'
			assert not c.matchesType(LastNameConstruct), 'wrong type match'
		textConstruct: ->
			class FirstNameConstruct extends ConstructWithText

			c = new FirstNameConstruct()
			assert c instanceof FirstNameConstruct
			assert c instanceof ConstructWithText
			assert c instanceof Construct

			assert c.text is null
			c.text = 'test'
			assert c.text is 'test'
		childrenConstruct: ->
			class StatementConstruct extends ConstructWithText

			class BlockConstruct extends ConstructWithChildren
				constructor: ->
					super StatementConstruct

			b = new BlockConstruct()

			assert b instanceof BlockConstruct
			assert b instanceof ConstructWithChildren
			assert b instanceof Construct

			assert b.getFirstChild() is null
			assert b.getLastChild() is null

			s1 = new StatementConstruct()
			s2 = new StatementConstruct()
			s3 = new StatementConstruct()
			s4 = new StatementConstruct()
			s5 = new StatementConstruct()
			s6 = new StatementConstruct()

			do ->
				b.prependChild s1
				assert b.getFirstChild() is s1
				assert b.getLastChild() is s1
				assert s1.childName is null

				b.removeChild s1
				assert b.getFirstChild() is null
				assert b.getLastChild() is null

			do ->
				b.appendChild s1
				assert b.getFirstChild() is s1
				assert b.getLastChild() is s1

				b.removeChild s1
				assert b.getFirstChild() is null
				assert b.getLastChild() is null

			do ->
				b.appendChild s2
				b.insertChildBefore s1, s2
				assert b.getFirstChild() is s1
				assert b.getLastChild() is s2

				b.removeChild s1
				b.removeChild s2

			do ->
				b.appendChild s1
				b.insertChildAfter s2, s1
				assert b.getFirstChild() is s1
				assert b.getLastChild() is s2

				b.removeChild s1
				b.removeChild s2

			do ->
				expected = [s1, s2, s3]

				b.prependChild s3
				b.prependChild s2
				b.prependChild s1

				assertChildren b, expected

				for s in expected
					b.removeChild s

			do ->
				blank1 = new Blank()
				blank2 = new Blank()
				blank3 = new Blank()
				expected = [s1, s2, s3]

				b.appendChild s1
				b.appendChild s2
				b.appendChild s3

				assertChildren b, expected

				expected = [blank1, blank2, blank3]

				b.replaceChild s1, blank1
				b.replaceChild s2, blank2
				b.replaceChild s3, blank3

				for s in expected
					b.removeChild s

			do ->
				expected = [s1, s2, s3]

				b.appendChild s1
				b.appendChild s2
				b.appendChild s3

				assertChildren b, expected

				for s in expected
					b.removeChild s

			do ->
				expected = [s1, s2, s3, s4, s5, s6]

				b.appendChild s3
				b.appendChild s5
				b.insertChildBefore s2, s3
				b.insertChildAfter s4, s3
				b.insertChildBefore s1, s2
				b.insertChildAfter s6, s5

				assertChildren b, expected

				for s in expected
					b.removeChild s
		namedChildrenConstruct: ->
			class StringLiteralConstruct extends ConstructWithText
			class NullConstruct extends Construct

			class NameConstruct extends ConstructWithNamedChildren
				constructor: ->
					super [
						new NamedChildDefinition 'first', StringLiteralConstruct
						new NamedChildDefinition 'middle', StringLiteralConstruct
						new NamedChildDefinition 'last', StringLiteralConstruct
					]

			parent = new NameConstruct()

			firstBlank = parent.getNamedChild 'first'
			assert firstBlank instanceof Blank
			assert firstBlank.childName is 'first'

			middleBlank = parent.getNamedChild 'middle'
			assert middleBlank instanceof Blank
			assert middleBlank.childName is 'middle'

			lastBlank = parent.getNamedChild 'last'
			assert lastBlank instanceof Blank
			assert lastBlank.childName is 'last'

			assertChildren parent, [firstBlank, middleBlank, lastBlank]

			assert.throws ->
				parent.setNamedChild 'middle', new NullConstruct()
			, Error

			assertChildren parent, [firstBlank, middleBlank, lastBlank]

			firstValue = new StringLiteralConstruct()
			parent.setNamedChild 'first', firstValue
			assertChildren parent, [firstValue, middleBlank, lastBlank]

			middleValue = new StringLiteralConstruct()
			parent.setNamedChild 'middle', middleValue
			assertChildren parent, [firstValue, middleValue, lastBlank]

			lastValue = new StringLiteralConstruct()
			parent.setNamedChild 'last', lastValue
			assertChildren parent, [firstValue, middleValue, lastValue]

			assert parent.getNamedChild('first') is firstValue
			assert parent.getNamedChild('middle') is middleValue
			assert parent.getNamedChild('last') is lastValue

			assert firstValue.childName is 'first'
			assert middleValue.childName is 'middle'
			assert lastValue.childName is 'last'

			newBlank = new Blank()
			parent.setNamedChild 'first', newBlank
			assertChildren parent, [newBlank, middleValue, lastValue]

			newBlank2 = new Blank()
			parent.replaceChild newBlank, newBlank2
			assertChildren parent, [newBlank2, middleValue, lastValue]

			assert firstValue.parent is null
			assert firstValue.childName is null
			assert firstValue.previousSibling is null
			assert firstValue.nextSibling is null
		cloning: ->
			class TrueConstruct extends Construct
			class FalseConstruct extends Construct
			BooleanConstruct = new ConstructTypeAlias [TrueConstruct, FalseConstruct]

			class TextConstruct extends ConstructWithText

			class ListConstruct extends ConstructWithChildren
				constructor: ->
					super BooleanConstruct

			class BooleanPairConstruct extends ConstructWithNamedChildren
				constructor: ->
					super [
						new NamedChildDefinition 'left', BooleanConstruct
						new NamedChildDefinition 'right', BooleanConstruct
					]

			tc1 = new TrueConstruct()
			tc2 = tc1.clone()
			assert tc1 isnt tc2
			assert tc1 instanceof TrueConstruct
			assert tc2 instanceof TrueConstruct

			text1 = new TextConstruct()
			text1.text = 'hi'
			text2 = text1.clone()
			assert text1 isnt text2
			assert text1 instanceof TextConstruct
			assert text2 instanceof TextConstruct
			assert text1.text is 'hi'
			assert text2.text is 'hi'

			l1 = new ListConstruct()
			l1.appendChild new TrueConstruct()
			l1.appendChild new FalseConstruct()
			l2 = l1.clone()
			assert l1 isnt l2
			assert l1 instanceof ListConstruct
			assert l2 instanceof ListConstruct
			assert l1.getFirstChild() isnt l2.getFirstChild()
			assert l1.getFirstChild() instanceof TrueConstruct
			assert l2.getFirstChild() instanceof TrueConstruct
			assert l1.getLastChild() isnt l2.getLastChild()
			assert l1.getLastChild() instanceof FalseConstruct
			assert l2.getLastChild() instanceof FalseConstruct

			p1 = new BooleanPairConstruct()
			p1.setNamedChild 'left', new TrueConstruct()
			p1.setNamedChild 'right', new FalseConstruct()
			p2 = p1.clone()
			assert p1 isnt p2
			assert p1 instanceof BooleanPairConstruct
			assert p2 instanceof BooleanPairConstruct
			assert p1.getFirstChild() isnt p2.getFirstChild()
			assert p1.getFirstChild() instanceof TrueConstruct
			assert p2.getFirstChild() instanceof TrueConstruct
			assert p1.getLastChild() isnt p2.getLastChild()
			assert p1.getLastChild() instanceof FalseConstruct
			assert p2.getLastChild() instanceof FalseConstruct
	}
