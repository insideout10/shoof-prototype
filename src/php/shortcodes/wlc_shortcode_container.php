<?php 
// Simple container output
function wlc_shortcode_container( $atts ) {

	// TODO Define container url
    // Extract attributes and set default values
    $container_atts = shortcode_atts( array(
        'uri'       => '',
        'skin'      => '',
        'listening' => '',
        'limit'     => 10,
    ), $atts );
    // Escaping atts.
    $uri = $container_atts['uri'];
    $limit = $container_atts['limit'];
    $skin = $container_atts['skin'];
    $listening = $container_atts['listening'];
	
	$base_url 	= 	admin_url( 'admin-ajax.php' );
    $uri        =	"$base_url?action=wlc_render&skin=$skin&limit=$limit";
    // Return container code
	return <<<EOF
	<wl-container uri="$uri" stack="stack" listening="listening">
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
 * $_GET["skin"] = string
 
 */
function wlc_render_container()
{
	
    ob_clean();
    header( "Content-Type: application/json" );
    
    // Use limit or set 10 as default
    $limit = ( isset($_GET["limit"]) ) ? $_GET["limit"] : 10;
    // Check if recommendation filtering has to be performed (default: false)
    $recom = ( isset($_GET["recom"]) ) ? true : false;
    // Filter contents by content types (wp native and schema.org ones) (default: 'post')
    $content_type = ( isset($_GET["contentType"]) ) ? $_GET["contentType"] : false;
    // Scope filtering: it can
    $scope = ( isset($_GET["contentId"]) ) ? $_GET["contentId"] : false;
    $jsonp = ( isset($_GET["callback"]) ) ? true : false;
    $skin = $_GET["skin"];

    $posts_query = array(
        'posts_per_page'    =>  $limit,
        'post_status'       =>  'publish',
        );
    
    if($content_type) {
        $posts_query['post_type'] = $content_type;
    }
    // Retrieve items
    $posts = get_posts( $posts_query );
    $items = array();

    foreach( $posts as $item )
    {
        $item = array(
            'id'        =>  $item->ID, 
            'title'     =>  $item->post_title,
            'type'      =>  $item->post_type,
            'content'   =>  strip_shortcodes( $item->post_content ),
            'excerpt'   =>  strip_shortcodes( $item->post_excerpt ),
            'uri'       =>  get_permalink($item->ID),
            'thumbnail' =>  wp_get_attachment_url( get_post_thumbnail_id( $item->ID ) ),
            'meta'      =>  get_post_meta( $item->ID ),
            );

        array_push($items, $item);
    } 

    $output = array(
    	'items'	=> 	$items,
    	'skin'  => 	$skin,
    	);

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