Feature: Login as an administrator (no-js)
  As a maintainer of the site
  I want basic login behavior to work
  So that I can administer the site

  Scenario: Confirm access to create users
    Given I am logged in as an administrator
    And I am on the dashboard
    And I go to the "Users" menu
    When I click on the "Add New" link in the header
    Then I should be on the "Add New User" screen
