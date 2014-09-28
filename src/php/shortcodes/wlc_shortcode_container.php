<?php 
// Simple container output
function wlc_shortcode_container( $atts ) {

	// TODO Define container url

    // Extract attributes and set default values
    $container_atts = shortcode_atts( array(
        'url'      => '',
        'listening' => ''
    ), $atts );
    // Escaping atts.
    $esc_url = esc_attr( $container_atts['url'] );
    $esc_listening = esc_attr( $container_atts['listening'] );
    
    // Return container code
	return <<<EOF
	<wl-container uri="$esc_url" stack="stack" listening="$esc_listening">
	</wl-container>
EOF;
}
/**
 * Container rendering callback:
 * Accepted params:
 * $_GET["contentType"]
 * $_GET["contentId"]
 * $_GET["recom"] = true / false, recommendations enabled
 * $_GET["limit"] = integer
 
 */
function wlc_render_container()
{
	
    ob_clean();
    header( "Content-Type: application/json" );
    
    // Use limit or set 10 as default
    $limit = ( isset($_GET["limit"]) ) ? $_GET["limit"] : 10;
    // Check if recommendation filtering has to be performed (default: false)
    $recom_enabled = ( isset($_GET["recom"]) ) ? $recom_enabled : false;
    // Filter contents by content types (wp native and schema.org ones) (default: 'post')
    $content_type = ( isset($_GET["contentType"]) ) ? $_GET["contentType"] : 'post';
    // Scope filtering: it can
    $scope = ( isset($_GET["scope"]) ) ? $_GET["scope"] : false;
    $jsonp = ( isset($_GET["callback"]) ) ? true : false;
    
    $posts_query = array(
        'post_type'       => $content_type,
        'posts_per_page'  => $limit,
        );
    // Retrieve items
    $output = get_posts( $posts_query );
    $output = json_encode( $output );

	echo $output;
    wp_die();
}

add_action( 'wp_ajax_wlc_render', 'wlc_render_container' );
add_action( 'wp_ajax_nopriv_wlc_render', 'wlc_render_container' );

function wlc_shortcode_container_register()
{
    add_shortcode('wlc-container', 'wlc_shortcode_container');
}
add_action('init', 'wlc_shortcode_container_register');