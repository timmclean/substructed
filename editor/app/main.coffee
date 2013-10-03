# TODO docs

requirejs.config {
	baseUrl: '.'
	paths: {
		'editor': 'editor'
		'handlebars': 'lib/handlebars-1.0.0'
		'jquery': 'lib/jquery-2.0.3'
		'underscore': 'lib/underscore-1.5.2'
	}
	shim: {
		handlebars: {
			exports: 'Handlebars'
		}
		underscore: {
			exports: '_'
		}
	}
}

requirejs ['editor/app/editor'], (editor) ->
	editor()
