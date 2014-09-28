<?php
/*
Plugin Name: Wordlift Rendering Engine
Plugin URI: https://github.com/insideout10/shoof-prototype
Description: M.I.C.O. test plugin
Version: 1.0
Author: Marcello Colacino
Author URI: https://github.com/mcolacino
License: GPL2
*/



function wlc_include_frontend_scripts() {
	wp_enqueue_script(
		'wlc-angular',
		plugins_url( 'js/vendor/angular.min.js', __FILE__ ),
		array( 'jquery' )
	);
	wp_enqueue_script(
		'wlc-angular-geolocation',
		plugins_url( 'js/vendor/angularjs-geolocation.min.js', __FILE__ ),
		array( 'jquery' )
	);
	wp_enqueue_script(
		'wlc-bootstrap',
		plugins_url( 'js/foundation-starter.js', __FILE__ ),
		array( 'jquery' )
	);
	wp_enqueue_script(
		'wlc-engine',
		plugins_url( 'js/wordlift-containers.js', __FILE__ ),
		array( 'jquery' )
	);
}

add_action( 'wp_enqueue_scripts', 'wlc_include_frontend_scripts' );

// Shortcodes
require_once('shortcodes/wlc_shortcode_container.php');

?>