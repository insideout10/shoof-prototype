module.exports = function(grunt) {
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		
      	coffee: {
      		compile: {
        		options: {
          			join: true,
          			sourceMap: true
      			},
        		files: {
          			'app/js/shoof-ui.js': [
            			'src/coffee/app.shoof.ui.coffee',
            			'src/coffee/app.shoof.ui.skins.coffee',
            			'src/coffee/app.shoof.ui.skins.famous.coffee'
          			]
          		}
          	}
        },
		compass: {
			dist: {
				options: {
					sassDir: 'src/scss',
					cssDir: 'app/css'
				},
			}
		},
		cssmin: {
  			minify: {
    			src: 'app/css/app.shoof.ui.css',
   				dest: 'app/css/app.shoof.ui.min.css'
  			}
		},
		watch: {
			css: {
				files: 'src/scss/*.scss',
				tasks: ['compass']
			},
			coffee: {
    			files: ['src/coffee/*.coffee'],
    			tasks: 'coffee'
  			},
  			cssmin: {
  				files: ['app/css/shoof.ui.css'],
  				tasks: ['cssmin']
			}
		}
	});

	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-compass');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-cssmin');

	grunt.registerTask('default',['cssmin','coffee','watch']);
}