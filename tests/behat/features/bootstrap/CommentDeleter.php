<?php

use GuzzleHttp\Pool;
use GuzzleHttp\Client;
use GuzzleHttp\Psr7\Request;

define('BASE_URL_FOR_WP_REST', "http://" . getenv('TERMINUS_ENV')."-".getenv('TERMINUS_SITE') . ".pantheonsite.io/");


/**
 * A quick and dirty class for deleting all comments with the WP REST API.
 * Much faster than doing the same over SSH with Terminus/WPCLI.
 */
class CommentDeleter {



    function __construct(){
      $this->auth_user = getenv('ADMIN_USERNAME');
      $this->auth_pass = getenv('ADMIN_PASSWORD');
      $this->base_url = "http://" . getenv('TERMINUS_ENV')."-".getenv('TERMINUS_SITE') . ".pantheonsite.io/";
    }

    function get_comments() {
        $client = new \GuzzleHttp\Client();
        $response = $client->request('GET', BASE_URL_FOR_WP_REST . 'wp-json/wp/v2/comments?status=hold', ['auth' => [$this->auth_user, $this->auth_pass]]);
        return '' . $response->getBody();
    }

    function get_comment_ids() {

        $comments = json_decode($this->get_comments());
        $return = [];
        foreach($comments as $comment) {
            $return[] = $comment->id;
        }

        return $return;
    }

    function deleteComments() {
        $comment_ids = $this->get_comment_ids();

        $client = new Client();

        $requests = function ($ids) {
            foreach ($ids as $id) {
                yield new Request('DELETE', BASE_URL_FOR_WP_REST . "wp-json/wp/v2/comments/" . $id, ['Authorization' => "Basic " . base64_encode($this->auth_user . ':' . $this->auth_pass  )]);
            }
        };

        $pool = new Pool($client, $requests($this->get_comment_ids()), [
            'concurrency' => 5,
            'fulfilled' => function ($response, $index) {
                // this is delivered each successful response
            },
            'rejected' => function ($reason, $index) {

              // this is delivered each failed request
            },
        ]);

        // Initiate the transfers and create a promise
        $promise = $pool->promise();
        // Force the pool of requests to complete.
        $promise->wait();
    }

}



