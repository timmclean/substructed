module.exports = (grunt) ->
	child_process = require 'child_process'
	require('load-grunt-tasks')(grunt)

	grunt.initConfig {
		clean: {
			all: [
				'build'
				'tmp'
			]
		}
		coffee: {
			all: {
				files: [
					{
						expand: true
						src: 'editor/**/*.coffee'
						dest: 'build'
						ext: '.js'
					}
				]
			}
		}
		stylus: {
			all: {
				files: [
					{
						expand: true
						src: 'editor/**/*.styl'
						dest: 'build'
						ext: '.css'
					}
				]
			}
		}
		copy: {
			all: {
				files: [
					{
						expand: true
						src: [
							'editor/**/*.js'
							'lib/**/*.js'
						]
						dest: 'build'
					}
					{
						expand: true
						src: [
							'editor/**/*.css'
							'lib/**/*.css'
						]
						dest: 'build'
					}
					{
						expand: true
						src: 'index.html'
						dest: 'build'
					}
				]
			}
		}
		connect: {
			all: {
				options: {
					base: 'build'
					port: 8000
				}
			}
		}
		watch: {
			core: {
				files: [
					'editor/core/**'
				]
				tasks: ['buildcore', 'testcore']
			}
			app: {
				files: [
					'index.html'
					'editor/app/**'
					'editor/core/**'
				]
				tasks: ['buildapp']
			}
		}
	}

	grunt.registerTask 'buildapp', [
		'clean:all'
		'coffee:all'
		'stylus:all'
		'copy:all'
	]
	grunt.registerTask 'devapp', [
		'buildapp'
		'connect:all'
		'watch:app'
	]
	grunt.registerTask 'buildcore', [
		'clean:all'
		'coffee:all'
		'copy:all'
	]
	grunt.registerTask 'devcore', [
		'buildcore'
		'testcore'
		'watch:core'
	]

	grunt.registerTask 'testcore', (target) ->
		done = @async()

		proc = child_process.spawn 'r.js', ['editor/core/tests.js'], {
			cwd: 'build'
			stdio: 'inherit'
		}
		proc.on 'close', ->
			done()
