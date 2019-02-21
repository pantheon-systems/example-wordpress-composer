<?php

declare(strict_types=1);

namespace PantheonSystems\WordHatHelpers\Contexts;

use Behat\Behat\Context\Context;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\MinkExtension\Context\MinkContext;
use PaulGibbs\WordpressBehatExtension\Context\RawWordpressContext;
use PaulGibbs\WordpressBehatExtension\Context\UserContext;
use PaulGibbs\WordpressBehatExtension\Context\EditPostContext;
use PaulGibbs\WordpressBehatExtension\Context\Traits\ContentAwareContextTrait;
use PaulGibbs\WordpressBehatExtension\Context\Traits\UserAwareContextTrait;
use Behat\Mink\Exception\ExpectationException;
use RuntimeException;

/**
 * Define application features from the specific context.
 */
class PantheonContext extends RawWordpressContext
{
    use ContentAwareContextTrait;
    use UserAwareContextTrait;

    private $previous_url;

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
            $this->previous_url = ( $this->userLoggedIn() ) ? $this->getAdminURL() : $this->getFrontendURL();
        };
        return $this->previous_url;
    }

    /**
     * Log into WordPress as an admin
     *
     * Example: Given I am a WordPress admin
     *
     * @Given /^(?:I am|they are) a WordPress admin$/
     *
     * @throws \RuntimeException
     * 
     * @return void
     */
    public function loginAsWordPressAdmin()
    {

        // No admin user has been found yet
        $found_user = null;

        // Get the users list sent to WordHat
        $users = $this->getWordpressParameter('users');

        // Loop through the users
        foreach ($users as $user) {
            // Look for an admin
            if ( in_array( 'administrator', $user['roles'], true ) ) {
                $found_user = $user;
                break;
            }
        }

        // Error if no admin user was found
        if ( null === $found_user ) {
            throw new \RuntimeException("No admin user found. Make sure to supply users to WordHat in the Behat configuration");
        }

        // Stash the username and password
        $username = $found_user['username'];
        $password = $found_user['password'];

        // $user_id = $this->getUserIdFromLogin( $username );
        // wp_set_auth_cookie( $user_id, true, is_ssl() );

        // Verify the session
        $session = $this->verifySession();

        // Stash the current URL to redirect back to
        $this->setPreviousURL();

        // Check if already logged in
        if ( $this->userLoggedIn() ) {
            $this->logOut();
        }

        // Go to the WordPress login URL
        $this->visitPath( 'wp-login.php?redirect_to=' . urlencode( $this->getPreviousURL() ) );

        // Store the current page object
        $page = $session->getPage();

        // Attempt to fill out the login form
        try {
            // Verify the login form exists
            $login_form = $page->find('css', '#loginform');

            if ( null === $login_form ) {
                throw new \RuntimeException("No login form found at /wp-login.php");
            }
            
            // Fill in username
            $user_login_field = $page->find('css', '#user_login');
            $user_login_field->focus();
            $user_login_field->setValue($username);
            $page->fillField('user_login', $username);
            $session->executeScript(
                "jQuery('#user_login').val('$username');"
            );

            // Verify the username is filled in correctly
            if( $user_login_field->getValue() !== $username ) {
                throw new \RuntimeException("The admin username password could not be entered into the login form");
            }
            
            // Fill in password
            $user_pass_field = $page->find('css', '#user_pass');
            $user_pass_field->focus();
            $user_pass_field->setValue($password);
            $page->fillField('user_pass', $password);
            $session->executeScript(
                "jQuery('#user_pass').val('$password');"
            );


            // Verify the password is filled in correctly
            if( $user_pass_field->getValue() !== $password ) {
                throw new \RuntimeException("The admin password could not be entered into the login form");
            }
            
            // Remember the login
            $page->checkField('rememberme');

            // Submit the form
            $submit_button = $page->find('css', '#wp-submit');
            $submit_button->focus();
            $submit_button->click();

            // Wait for the login form to disappear, giving up after 5 seconds.
            $session->wait( 5000, "!document.getElementById('loginform')" );
        } catch (DriverException $e) {
            // This may fail if the user has not loaded any site yet.
        }

        // Error if the user isn't logged in
        if ( ! $this->userLoggedIn() ) {
            throw new ExpectationException(
                "Failed to login as admin user $username.",
                $this->getSession()->getDriver()
            );
        }
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
        if( $this->userLoggedIn() ) {
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
        if( ! $this->userLoggedIn() ) {
            throw new ExpectationException(
                'A user is not logged in. This should not have happened.',
                $this->getSession()->getDriver()
            );
        }
    }

    /**
     * Take a screenshot
     *
     * Example: And I take a screenshot
     * Example: And I take a screenshot "some-page.png"
     *
     * @Then /^(?:|I )take a screenshot "(?P<file_name>[^"]+)"$/
     * @Given I take a screenshot
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
        if ( $this->userLoggedIn() ) {
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

    /**
     * Is the user logged in?
     *
     * @return boolean
     */
    public function userLoggedIn(): bool
    {
        // Verify the session
        $session = $this->verifySession();

        // Stash the current URL
        $current_url = $session->getCurrentUrl();

        // If we are on the dashboard then we must be logged in
        if ( false !== stripos( $current_url, 'wp/wp-admin' ) ) {
            return true;
        }

        // Stash the current page object
        $page = $session->getPage();

        // Look for a selector to determine if the user is logged in.
        try {
            $body_element = $page->find('css', 'body');
            // If the page doesn't have a body element the user is not logged in
            if( null === $body_element ) {
                return false;
            }
            $is_logged_in = (
                $body_element->hasClass('logged-in') || 
                $body_element->hasClass('wp-admin')
            );
            return $is_logged_in;
        } catch (DriverException $e) {
            // This may fail if the user has not loaded any site yet.
        }

        // If there aren't any logged in body classes no user is logged in
        return false;
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

        // Stash the current URL to redirect back to
        $this->setPreviousURL();
        
        // Are we currently logged in?
        $logged_in = $this->userLoggedIn();

        if( $this->userLoggedIn() ) {
            $clear_cache_link = $page->find('css', '#wp-admin-bar-clear-page-cache > a');
            if( null !== $clear_cache_link ) {
                $clear_cache_link->click();
            }
        }

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