<?php


use PaulGibbs\WordpressBehatExtension\Context\RawWordpressContext;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Behat\Hook\Scope\AfterFeatureScope;
use GuzzleHttp\Pool;
use GuzzleHttp\Client;
use GuzzleHttp\Psr7\Request;

/**
 * Define application features from the specific context.
 */
class FeatureContext extends RawWordpressContext {
    /**
     * Initializes context.
     * Every scenario gets its own context object.
     *
     * @param array $parameters
     *   Context parameters (set them in behat.yml)
     */
    public function __construct(array $parameters = []) {
    // Initialize your context here
    }

    /** @var \Behat\MinkExtension\Context\MinkContext */
    private $minkContext;
    /** @BeforeScenario */
    public function gatherContexts(BeforeScenarioScope $scope)
    {
      $environment = $scope->getEnvironment();
      $this->minkContext = $environment->getContext('Behat\MinkExtension\Context\MinkContext');
    }

    /**
     * @Then I fill in the comment form
     */
    public function iFillInTheCommentForm()
    {
        $time = time();
        $this->minkContext->fillField('Comment', "Great article! " . $time
        );
        $this->minkContext->fillField('Name', "Behat Commenter " . $time);
        $this->minkContext->fillField('Email', $time . "@example.com");
        $this->minkContext->fillField('Website', "http://" . $time . "example.com");
        $this->minkContext->pressButton('Post Comment');
    }

  /**
   * @AfterFeature
   */
   static function afterFeature(AfterFeatureScope $scope) {

     $commentDeleter = new CommentDeleter();
     $commentDeleter->delete_all_comments();
   }
}

function get_comments() {
    $client = new \GuzzleHttp\Client();
    $response = $client->request('GET', BASE_URL_FOR_WP_REST . 'wp-json/wp/v2/comments?status=hold', BASIC_AUTH_OPTIONS);
    return '' . $response->getBody();
}


function get_comment_ids() {

    $comments = json_decode(get_comments());
    $return = [];
    foreach($comments as $comment) {
        $return[] = $comment->id;
    }
    print_r($return);

    return $return;
}

function delete_all_comments() {
    $comment_ids = get_comment_ids();

    $client = new Client();

    $requests = function ($ids) {
        foreach ($ids as $id) {
            yield new Request('DELETE', BASE_URL_FOR_WP_REST . "wp-json/wp/v2/comments/" . $id, ['Authorization' => "Basic " . base64_encode(BASIC_AUTH_OPTIONS['auth'][0] . ':' . BASIC_AUTH_OPTIONS['auth'][1]  )]);
        }
    };

    $pool = new Pool($client, $requests(get_comment_ids()), [
        'concurrency' => 5,
        'fulfilled' => function ($response, $index) {
            // this is delivered each successful response

//            print_r("\n\n");
//            print_r($response);
//
//            print_r("\n\n");
//
//            print_r($index);
        },
        'rejected' => function ($reason, $index) {

//            print_r("\n\n");
//            print_r($reason);
//
//            print_r("\n\n");
//
//            print_r($index);
//        // this is delivered each failed request
        },
    ]);

// Initiate the transfers and create a promise
    $promise = $pool->promise();

// Force the pool of requests to complete.
    $promise->wait();
}

