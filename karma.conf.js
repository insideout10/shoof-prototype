module.exports = function(config){
    config.set({
    basePath : './',

    preprocessors: {
        '**/*.html': [ ],
        '**/*.coffee': ['coffee']
    },

    files : [
      
        // Serve JS files.
        {pattern: 'app/js/*.js', watched: false, served: true, included: false },
        // Serve JSON files.
        {pattern: 'app/data/*.json', watched: false, served: true, included: false },

        'bower_components/jquery/dist/jquery.min.js',
        'bower_components/angular/angular.js',
        'bower_components/angular-mocks/angular-mocks.js',
        'test/coffee/**/*.coffee'
    ],
    autoWatch : true,
    frameworks: ['jasmine'],
    browsers : [
        'Chrome'
    ],
    plugins : [
        'karma-chrome-launcher',
        'karma-jasmine',
        'karma-coffee-preprocessor'
    ]
})}