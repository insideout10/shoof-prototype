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
          	],
          }
        }
      },
    copy : {
      dist: {
        files: [
          { src: 'app/js/wordlift-containers.js', dest: 'src/php/js/wordlift-containers.js'},
          { src: 'app/js/foundation-starter.js', dest: 'src/php/js/foundation-starter.js'},
          { src: 'app/js/famous-starter.js', dest: 'src/php/js/famous-starter.js'},          
          { src: 'app/css/wordlift-containers.css', dest: 'src/php/css/wordlift-containers.css'}
        ]
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
		watch: {
			compass: {
				files: ['src/scss/*.scss'],
       	tasks: ['compass']
			},
			coffee: {
    			files: ['src/coffee/*.coffee'],
    			tasks: 'coffee'
  		},
      copy: {
        files: ['app/js/*.js', 'app/css/*.css'],
        tasks: ['copy']
      }
		}
	});

	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-compass');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-copy');

	grunt.registerTask('default',['compass', 'coffee','copy', 'watch']);
}