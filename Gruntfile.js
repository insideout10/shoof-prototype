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
          			'app/js/wordlift-containers.js': [
            			'src/coffee/app.wordlift.containers.engine.coffee',
            			'src/coffee/app.wordlift.ui.skins.famous.coffee',
            			'src/coffee/app.wordlift.ui.skins.foundation.coffee'
          			],
          			'app/js/foundation-starter.js': [
            			'src/coffee/starters/foundation.coffee'
          			],
          			'app/js/famous-starter.js': [
            			'src/coffee/starters/famous.coffee'
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
    			src: 'src/scss/wordlift-containers.scss',
   				dest: 'app/css/wordlift-containers.min.css'
  			}
		},
		watch: {
			compass: {
				files: ['**/*.{scss}'],
       			tasks: ['compass:dev']
			},
			css: {
				files: 'src/scss/*.scss',
				tasks: ['compass']
			},
			coffee: {
    			files: ['src/coffee/*.coffee'],
    			tasks: 'coffee'
  			},
  			cssmin: {
  				files: ['app/css/wordlift-containers.css'],
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