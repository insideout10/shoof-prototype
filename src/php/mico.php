<?php
/*
Plugin Name: Mico
Plugin URI: https://github.com/insideout10/shoof-prototype
Description: M.I.C.O. test plugin
Version: 1.0
Author: Marcello Colacino
Author URI: https://github.com/mcolacino
License: GPL2
*/



function mico_include_frontend_scripts() {
	wp_enqueue_script(
		'wordlift-containers',
		plugins_url( 'js/wordlift-containers.js' , __FILE__ ),
		array( 'jquery' )
	);
}

add_action( 'wp_enqueue_scripts', 'mico_include_frontend_scripts' );
?>