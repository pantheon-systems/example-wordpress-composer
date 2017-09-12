<?php


use PaulGibbs\WordpressBehatExtension\Context\RawWordpressContext;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Behat\Hook\Scope\AfterFeatureScope;


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
        $this->minkContext->fillField('Comment', "Great article!" . $time
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
       exec('terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- comment delete $(terminus -n wp $TERMINUS_SITE.$TERMINUS_ENV -- comment list --format=ids) > /dev/null &');

   }
}
