define (require) ->
	{assertEqual} = require 'editor/core/testUtils'
	{
		BlockElement
		InlineElement
		InlineSectionElement
		SectionElement
		renderTextElements
	} = require 'editor/core/render'

	return {
		renderTextElements: ->
			expected = {
				lines: [
					{
						chunks: [
							{
								text: '['
								sections: ['selection']
							}
						]
						trailingSections: ['selection']
					}
					{
						chunks: [
							{
								text: '    '
								sections: ['selection']
							}
							{
								text: '1,'
								sections: ['selection']
							}
						]
						trailingSections: ['selection']
					}
					{
						chunks: [
							{
								text: '    '
								sections: ['selection']
							}
							{
								text: '2,'
								sections: ['selection']
							}
						]
						trailingSections: ['selection']
					}
					{
						chunks: [
							{
								text: '    '
								sections: ['selection']
							}
							{
								text: '3'
								sections: ['selection']
							}
						]
						trailingSections: ['selection']
					}
					{
						chunks: [
							{
								text: ']'
								sections: ['selection']
							}
						]
						trailingSections: []
					}
				]
			}
			actual = renderTextElements [
				new SectionElement 'selection', [
					new InlineElement '['
					new BlockElement [
						new BlockElement [
							new InlineElement '1,'
						]
						new BlockElement [
							new InlineElement '2,'
						]
						new BlockElement [
							new InlineElement '3'
						]
					], true
					new InlineElement ']'
				]
			]
			assertEqual actual, expected
		emptyInlineSection: ->
			expected = {
				lines: [
					{
						chunks: [
							{
								text: ''
								sections: ['test']
							}
						]
						trailingSections: []
					}
				]
			}
			actual = renderTextElements [
				new InlineSectionElement 'test', ''
			]
			assertEqual actual, expected
	}
