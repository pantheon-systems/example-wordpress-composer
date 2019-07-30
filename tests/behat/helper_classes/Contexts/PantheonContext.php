<?php

declare(strict_types=1);

namespace PantheonSystems\WordHatHelpers\Contexts;

use PaulGibbs\WordpressBehatExtension\Context\RawWordpressContext;
use PaulGibbs\WordpressBehatExtension\Context\Traits\ContentAwareContextTrait;
use PaulGibbs\WordpressBehatExtension\Context\Traits\UserAwareContextTrait;
use PaulGibbs\WordpressBehatExtension\PageObject\LoginPage;
use Behat\Mink\Exception\ExpectationException;
use RuntimeException;
use FailAid\Context\FailureContext;

/**
 * Define application features from the specific context.
 */
class PantheonContext extends RawWordpressContext
{
    use ContentAwareContextTrait;
    use UserAwareContextTrait;

    private $previous_url;

    /**
     * Login form page object.
     *
     * @var LoginPage
     */
    public $login_page;

    /**
     * Constructor.
     *
     * @param LoginPage $login_page The page object representing the login page.
     */
    public function __construct(LoginPage $login_page)
    {
        parent::__construct();
        $this->login_page = $login_page;
    }

    private function getAdminURL()
    {
        return $this->getWordpressParameter('site_url') . ('/wp-admin/index.php');
    }

    private function getFrontendURL()
    {
        return $this->getMinkParameter('base_url');
    }

    private function getPreviousURL()
    {
        if( null === $this->previous_url ) {
            $this->previous_url = ( $this->loggedIn() ) ? $this->getAdminURL() : $this->getFrontendURL();
        };
        return $this->previous_url;
    }

    /**
     * Verify that a user is not logged in
     *
     * Example: Then I should not be logged in
     *
     * @Then /^(?:I|they) should not be logged in$/
     *
     * @throws ExpectationException
     */
    public function iShouldNotBeLoggedIn()
    {
        if( $this->loggedIn() ) {
            throw new ExpectationException(
                'A user is logged in. This should not have happened.',
                $this->getSession()->getDriver()
            );
        }
    }

    /**
     * Verify that a user is logged in
     *
     * Example: Then I should be logged in
     *
     * @Then /^(?:I|they) should be logged in$/
     *
     * @throws ExpectationException
     */
    public function iShouldBeLoggedIn()
    {
        if( ! $this->loggedIn() ) {
            throw new ExpectationException(
                'A user is not logged in. This should not have happened.',
                $this->getSession()->getDriver()
            );
        }
    }

    /**
     * Take a screenshot
     *
     * Example: And I take a Chrome screenshot
     * Example: And I take a Chrome screenshot "some-page.png"
     *
     * @Then /^(?:|I )take a Chrome screenshot "(?P<file_name>[^"]+)"$/
     * @Given I take a Chrome screenshot
     */
    public function takeScreenshot($file_name=null)
    {
        $driver = $this->getSession()->getDriver();
        $ss_path = 'behat-screenshots/' . date('Y-m-d');
        if (!file_exists($ss_path)) {
            mkdir($ss_path, 0777, true);
        }
        if ( null == $file_name ) {
            $file_name = 'screenshot-' . date('Y-m-d-H-i-s') . '.png';
        }
        $driver->captureScreenshot($ss_path . '/' . $file_name);
    }

    private function setPreviousURL()
    {
        // Verify the session
        $session = $this->verifySession();

        // Set previous URL to the current URL
        $this->previous_url = $session->getCurrentUrl();
    }

    private function goToPreviousURL()
    {
        // Verify the session
        $session = $this->verifySession();

        // Go back to the previous URL
        $session->visit($this->getPreviousURL());
    }

    public function logOut( $redirect=true )
    {

        // Verify the session
        $session = $this->verifySession();

        if( $redirect ) {
            // Stash the current URL
            $previous_url = $session->getCurrentUrl();
        }

        // Logout
        $this->getElement('Toolbar')->logOut();

        // Error if the user is still logged in
        if ( $this->loggedIn() ) {
            throw new ExpectationException(
                "Failed to log out.",
                $this->getSession()->getDriver()
            );
        }

        if( $redirect ) {
            // Go to the previous URL
            $session->visit($previous_url);
        }

    }

    protected function getAdminUser()
    {
        $found_user = null;
        $users      = $this->getWordpressParameter('users');

        foreach ($users as $user) {
            if (in_array('administrator', $user['roles'], true)) {
                $found_user = $user;
                break;
            }
        }

        if ($found_user === null) {
            throw new RuntimeException("No admin users found.");
        }

        return $found_user;
    }

    /**
     * Log into WordPress as an admin
     *
     * @throws \RuntimeException
     * 
     * @return void
     */
    protected function loginAsWordPressAdmin()
    {
        // Get the admin user
        $found_user = $this->getAdminUser();

        // Login to WordPress with the admin user details
        $this->logIn($found_user['username'], $found_user['password']);

        FailureContext::addState('username', $found_user['username']);
    }

    /**
     * Clear Pantheon page cache.
     *
     * Example: When the Pantheon cache is cleared
     * Example: Given the Pantheon cache has been cleared
     * Example: And the Pantheon cache has been cleared
     *
     * @When the Pantheon cache is cleared
     * @Given the Pantheon cache has been cleared
     * @And the Pantheon cache has been cleared
     */
    public function clearPantheonCache()
    {

        // Verify the session
        $session = $this->verifySession();

        // Get the current page from the session
        $page = $session->getPage();

        // Are we currently logged in?
        $logged_in = $this->loggedIn();

        // If logged in
        if( $logged_in ) {
            $clear_cache_link = $page->find('css', '#wp-admin-bar-clear-page-cache > a');
            // Attempt to use the clear cache button in the toolbar
            if( null !== $clear_cache_link ) {
                // If the clear cache button was used, we are done here
                $clear_cache_link->click();
                return;
            }
        }

        // Stash the current URL to redirect back to
        $this->setPreviousURL();

        // Log in as an admin if not already logged in
        if (! $logged_in) {
            $this->loginAsWordPressAdmin();
        }

        // Visit the Pantheon page cache admin page
        $this->visitPath('wp-admin/options-general.php?page=pantheon-cache');

        // Make sure that is a valid page
        $status_code = $session->getStatusCode();
        if( 200 !== $status_code ) {
            throw new \Exception(
                "Unable to visit the Pantheon page cache options page"
            );
        }

        // Find the clear cache button
        $submit_buttons = $page->findAll('css', '#submit');

        $clearCacheButton = null;

        foreach( $submit_buttons as $submit_button ) {
            if ( $submit_button->getValue() === 'Clear Cache' ) {
                $clearCacheButton = $submit_button;
            }
        }

        // Error if it is not found
        if ( null === $clearCacheButton ) {
            throw new \Exception(
                "Unable to clear the Pantheon cache. No clear cache button was found."
            );
        }

        // Click the clear cache button
        $clearCacheButton->click();

        // Get the current URL
        $current_url = $this->getSession()->getCurrentUrl();

        // Confirm the cache clear URL
        if( false === stripos( $current_url, 'cache-cleared=true') ) {
            throw new \Exception(
                "Unable to clear the Pantheon cache"
            );
        }

        // If we weren't previously logged in, log back out
        if (! $logged_in) {
            $this->logOut();
        }

        // Go back to the previous URL
        $this->goToPreviousURL();

    }

    /**
     * Verify a properly started mink session
     *
     * @return Session Returns Mink session.
     */
    private function verifySession() {
        // Start a session if needed
        $session = $this->getSession();
        if ( ! $session->isStarted() ) {
            $session->start();
        }

        // Stash the current URL
        $current_url = $session->getCurrentUrl();

        // If we aren't on a valid page
        if( 'about:blank' === $current_url ) {
            // Go to the home page
            $session->visit($this->getFrontendURL());
        }

        // Return the session
        return $session;
    }

}