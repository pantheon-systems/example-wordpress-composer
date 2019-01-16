Feature: Login as an administrator (no-js)
  As a maintainer of the site
  I want basic login behavior to work
  So that I can administer the site

  Scenario: Confirm access to create users
    Given I am logged in as an admin
    When I am on the dashboard
    And I go to menu item "Users > Add New"
    Then I should see "Add New User"
