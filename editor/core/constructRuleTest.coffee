define (require) ->
	assert = require('chai').assert

	constructRule = require 'editor/core/constructRule'
	{
		Wildcard
		Conjunction
		TypeRule
		MarkRule
		CaptureRule
		FirstChildRule
		LastChildRule
		NamedChildRule
		RelationRule
	} = constructRule

	testUtils = require 'editor/core/testUtils'
	{assertEqual} = testUtils

	syntax = require 'editor/core/syntax'
	{
		Syntax
		ConstructTypeAlias
		ConstructWithText
		ConstructWithChildren
		ConstructWithNamedChildren
		NamedChildDefinition
		Blank
	} = syntax

	class StatementConstruct extends ConstructWithText

	class StatementPairConstruct extends ConstructWithNamedChildren
		constructor: ->
			super [
				new NamedChildDefinition 'first', StatementConstruct
				new NamedChildDefinition 'second', StatementConstruct
			]

	class ArrayConstruct extends ConstructWithChildren
		constructor: ->
			super ValueConstruct
	class ListConstruct extends ConstructWithChildren
		constructor: ->
			super ValueConstruct

	ValueConstruct = new ConstructTypeAlias [
		ArrayConstruct
		ListConstruct
		StatementConstruct
	]

	return {
		wildcard: ->
			r = new Wildcard()
			s1 = new StatementConstruct()
			assertEqual r.apply(s1, {}), {}
		typeRule: ->
			r = new TypeRule Blank
			assertEqual r.apply(new Blank(), {}), {}
			assert r.apply(new StatementConstruct(), {}) is null

			r = new TypeRule StatementConstruct
			assertEqual r.apply(new StatementConstruct(), {}), {}
			assert r.apply(new Blank(), {}) is null
		markRule: ->
			r = new MarkRule 'test'
			s1 = new StatementConstruct()
			assert r.apply(s1, {}) is null
			assertEqual r.apply(s1, {test: s1}), {}
		captureRule: ->
			mr = new MarkRule 'test'
			r = new CaptureRule 'target', mr

			s1 = new StatementConstruct()

			assert r.apply(s1, {}) is null
			assert r.apply(s1, {test: s1}).target is s1
		firstLastChildRules: ->
			root = new ArrayConstruct()
			s1 = new StatementConstruct()
			root.appendChild s1
			s2 = new StatementConstruct()
			root.appendChild s2
			s3 = new StatementConstruct()
			root.appendChild s3

			do ->
				mr = new MarkRule 'test'
				r = new FirstChildRule mr

				assert r.apply(s1, {test: s1}) is null
				assert r.apply(s2, {test: s1}) is null
				assert r.apply(s3, {test: root}) is null
				assert r.apply(root, {test: s2}) is null
				assertEqual r.apply(root, {test: s1}), {}

			do ->
				mr = new MarkRule 'test'
				r = new LastChildRule mr

				assert r.apply(s1, {test: s3}) is null
				assert r.apply(s2, {test: s3}) is null
				assert r.apply(s3, {test: root}) is null
				assert r.apply(root, {test: s2}) is null
				assertEqual r.apply(root, {test: s3}), {}
		namedChildRule: ->
			root = new StatementPairConstruct()
			s1 = new StatementConstruct()
			root.setNamedChild 'first', s1
			s2 = new StatementConstruct()
			root.setNamedChild 'second', s2

			do ->
				mr = new MarkRule 'test'
				r = new NamedChildRule 'first', mr

				assert r.apply(s1, {test: s1}) is null
				assert r.apply(s2, {test: s1}) is null
				assert r.apply(root, {test: s2}) is null
				assertEqual r.apply(root, {test: s1}), {}

			do ->
				mr = new MarkRule 'test'
				r = new NamedChildRule 'second', mr

				assert r.apply(s1, {test: s2}) is null
				assert r.apply(s2, {test: s2}) is null
				assert r.apply(root, {test: s1}) is null
				assertEqual r.apply(root, {test: s2}), {}
		relationRuleImmediate: ->
			root = new ArrayConstruct()

			section1 = new ArrayConstruct()
			statement1 = new StatementConstruct()
			section1.appendChild statement1
			statement2 = new StatementConstruct()
			section1.appendChild statement2
			statement3 = new StatementConstruct()
			section1.appendChild statement3
			root.appendChild section1

			section2 = new ArrayConstruct()
			statement4 = new StatementConstruct()
			section2.appendChild statement4
			statement5 = new StatementConstruct()
			section2.appendChild statement5
			statement6 = new StatementConstruct()
			section2.appendChild statement6
			root.appendChild section2

			do ->
				mr = new MarkRule 'test'
				r = new RelationRule 'immediate', 'ancestor', false, mr

				assert r.apply(statement4, {test: statement4}) is null
				assertEqual r.apply(statement4, {test: section2}), {}

			do ->
				mr = new MarkRule 'test'
				r = new RelationRule 'immediate', 'ancestor', true, mr

				assert r.apply(statement2, {test: root}) is null
				assertEqual r.apply(statement2, {test: section1}), {}
				assertEqual r.apply(statement2, {test: statement2}), {}

			do ->
				mr = new MarkRule 'test'
				r = new RelationRule 'immediate', 'earlierSibling', false, mr

				assert r.apply(statement4, {test: statement4}) is null
				assert r.apply(statement4, {test: statement3}) is null
				assertEqual r.apply(statement5, {test: statement4}), {}

			do ->
				mr = new MarkRule 'test'
				r = new RelationRule 'immediate', 'earlierSibling', true, mr

				assert r.apply(statement3, {test: statement1}) is null
				assertEqual r.apply(statement2, {test: statement1}), {}
				assertEqual r.apply(statement2, {test: statement2}), {}

			do ->
				mr = new MarkRule 'test'
				r = new RelationRule 'immediate', 'laterSibling', false, mr

				assert r.apply(statement6, {test: statement6}) is null
				assert r.apply(statement3, {test: statement4}) is null
				assertEqual r.apply(statement5, {test: statement6}), {}

			do ->
				mr = new MarkRule 'test'
				r = new RelationRule 'immediate', 'laterSibling', true, mr

				assert r.apply(statement1, {test: statement3}) is null
				assertEqual r.apply(statement2, {test: statement3}), {}
				assertEqual r.apply(statement2, {test: statement2}), {}
		relationRuleClosestMatching: ->
			root = new ListConstruct()

			statement0 = new StatementConstruct()
			root.appendChild statement0

			bigSection = new ListConstruct()

			section1 = new ArrayConstruct()
			statement1 = new StatementConstruct()
			section1.appendChild statement1
			statement2 = new StatementConstruct()
			section1.appendChild statement2
			statement3 = new StatementConstruct()
			section1.appendChild statement3
			bigSection.appendChild section1

			section2 = new ArrayConstruct()
			statement4 = new StatementConstruct()
			section2.appendChild statement4
			statement5 = new StatementConstruct()
			section2.appendChild statement5
			statement6 = new StatementConstruct()
			section2.appendChild statement6
			bigSection.appendChild section2

			root.appendChild bigSection

			do ->
				tr = new TypeRule ListConstruct
				cr = new CaptureRule 'target', tr
				r = new RelationRule 'closestMatching', 'ancestor', false, cr

				assert r.apply(statement1, {}).target is bigSection
				assert r.apply(bigSection, {}).target is root
				assert r.apply(root, {}) is null

			do ->
				tr = new TypeRule ListConstruct
				cr = new CaptureRule 'target', tr
				r = new RelationRule 'closestMatching', 'ancestor', true, cr

				assert r.apply(statement1, {}).target is bigSection
				assert r.apply(bigSection, {}).target is bigSection
				assert r.apply(root, {}).target is root
		relationRuleFarthestMatching: ->
			root = new ListConstruct()

			c1 = new ListConstruct()
			root.appendChild c1
			c2 = new StatementConstruct()
			root.appendChild c2
			c3 = new ArrayConstruct()
			root.appendChild c3
			c4 = new ListConstruct()
			root.appendChild c4
			c5 = new ListConstruct()
			root.appendChild c5

			do ->
				tr = new TypeRule ListConstruct
				cr = new CaptureRule 'target', tr
				r = new RelationRule 'farthestMatching', 'laterSibling', false, cr

				assert r.apply(c1, {}).target is c5
				assert r.apply(c2, {}).target is c5
				assert r.apply(c5, {}) is null
				assert r.apply(root, {}) is null

			do ->
				tr = new TypeRule ListConstruct
				cr = new CaptureRule 'target', tr
				r = new RelationRule 'farthestMatching', 'laterSibling', true, cr

				assert r.apply(c1, {}).target is c5
				assert r.apply(c2, {}).target is c5
				assert r.apply(c5, {}).target is c5
				assert r.apply(root, {}).target is root
		conjuction: ->
			root = new ListConstruct()

			c1 = new ListConstruct()
			root.appendChild c1
			c2 = new StatementConstruct()
			root.appendChild c2

			do ->
				r = new Conjunction [new Wildcard(), new TypeRule(ListConstruct)]
				assertEqual r.apply(c1, {}), {}
				assert r.apply(c2, {}) is null

			do ->
				r = new Conjunction [new TypeRule(ListConstruct), new Wildcard()]
				assertEqual r.apply(c1, {}), {}
				assert r.apply(c2, {}) is null

			do ->
				r = new Conjunction [new TypeRule(ListConstruct), new TypeRule(ListConstruct)]
				assertEqual r.apply(c1, {}), {}
				assert r.apply(c2, {}) is null
	}
