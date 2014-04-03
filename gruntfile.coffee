Q = require 'q'
glob = require 'glob'
child = (require 'child_process')
Rsync = require 'rsync'
fs = require 'fs'

# some local config you should setup
# this will prob need more attention than the gunr specific config
config =
	# set the remote path (medivac host in this example)
	remotePath: 'medivac:~/tmpapp'
	# location of stylesheets
	stylePath: "#{__dirname}/src/styles/*.less"
	styleBuildPath: "#{__dirname}/build/public/stylesheets/style.css"
module.exports = (grunt) ->

	opt =
		buildFolder: "#{__dirname}/build"
		pkg: grunt.file.readJSON('package.json')

	grunt.initConfig opt

	grunt.registerTask 'concat', ->
		ok = this.async()
		rf = Q.denodeify(fs.readFile)

		glob(config.stylePath, (er, files) ->
			Q.all(files.map((item) ->
				rf(item)
			)).done((sources) ->
				merged = sources.map (src) ->
					src.toString()
				console.log arguments
				ok()
			)
		)

	grunt.registerTask 'movetodir', 'build into ./build', ->

		ok = this.async()
		cp = spawn 'cp', ['-rfv', __dirname + '/src', __dirname + '/build']

		cp.then((d)->
			grunt.log.writeln d.output
			ok()
		, (d) ->
			grunt.log.writeln d.error
			ok()
		)

	grunt.registerTask 'clean', 'clean ./build directory', ->

		ok = this.async()
		rm = spawn 'rm', ['-rfv', __dirname + '/build']
		mkBuildDir = spawn 'mkdir', [__dirname + '/build']

		#TODO building the project structure should prob be encoded by some tree object
		Q.fcall(rm)
		.then(mkBuildDir)
		.then((d)->
			grunt.log.writeln d.output
			ok()
		, (d) ->
			grunt.log.writeln d.error
			ok()
		)

	grunt.registerTask 'default', ['clean', 'movetodir', 'concat']

	# move build dir contents to the server
	grunt.registerTask 'deploy', ->

		ok = this.async()
		rsync = Rsync()
		.shell('ssh')
		.flags('az')
		.source('./build')
		.destination(config.remotePath)

		rsync.execute( ->
			grunt.log.writeln(arguments).ok()
			ok()
		)

#make a promisified and nice to use spawn function
spawn = (cmd_name, args) ->

	later = Q.defer()

	cmd = child.spawn cmd_name, args
	error_buffers = []
	output_buffers = []

	join_buffer = (buff_array) ->
		buff_array.map( (item) ->
			item.toString()
		).join('')

	cmd.stderr.on 'data', (dat) ->
		error_buffers.push dat

	cmd.stdin.on 'data', (dat) ->
		output_buffers.push dat

	cmd.on 'close', (code) ->
		response =
			output: join_buffer(output_buffers)
			error: join_buffer(error_buffers)
		if code == 0
			later.resolve response
		else
			later.reject response

	#promise you results will come when the process finishes
	later.promise
