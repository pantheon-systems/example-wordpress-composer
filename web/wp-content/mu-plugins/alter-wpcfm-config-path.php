<?php
/**
 * Plugin Name: Alter-wpcfm-config-path
 * Plugin URI: http://www.eyesopen.ca
 * Description: Alters the wpcfm config path
 * Version: 0.1
 * Author: Andrew Taylor
 * Author URI: https://pantheon.io
 * PHP Version: 7.0
 * License: GPL-2.0+
 * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
 *
 * @category Must_Use_Plugin
 * @package  ExampleWordPressComposer
 * @author   ataylorme <andrew@pantheon.io>
 * @license  GPL-2.0+ http://www.gnu.org/licenses/gpl-2.0.txt
 * @link     https://pantheon.io
 */

/**
 * Tell wp-cfm where our config files live
 */
add_filter(
    'wpcfm_config_dir', function ( $var ) {
        return DOCROOT . 'private/config';
    } 
);
add_filter(
    'wpcfm_config_url', function ( $var ) {
        return WP_HOME . '/private/config';
    } 
);
