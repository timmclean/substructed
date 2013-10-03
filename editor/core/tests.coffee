requirejs.config {
	baseUrl: '.'
	paths: {
		'editor': 'editor'
		'underscore': 'lib/underscore-1.5.2'
		'chai': 'lib/chai-1.8.0'
	}
	shim: {
		underscore: {
			exports: '_'
		}
	}
}

suiteNames = [
	'editor/core/syntaxTest'
	'editor/core/constructRuleTest'
	'editor/core/renderTest'
]

requirejs suiteNames, (suites...) ->
	for [suiteName, suite] in _.zip(suiteNames, suites)
		console.log "\nSuite #{suiteName}\n"

		for name of suite
			console.log "Running test #{name}..."
			suite[name]()
			console.log "Completed test #{name}."

	console.log "\nAll tests passed."

	return null
