Feature: Login as an administrator
  As a maintainer of the site
  I want basic login behavior to work
  So that I can administer the site

  @javascript
  Scenario: I can log-in and out with javascript
    Given I am logged in as an administrator
    And I am on the dashboard
    Then I should see "Howdy"
    When I log out
    Then I should not see "Howdy"

  Scenario: I can log-in and out without javascript
    Given I am logged in as an administrator
    And I am on the dashboard
    Then I should see "Howdy"
    When I log out
    Then I should not see "Howdy"
