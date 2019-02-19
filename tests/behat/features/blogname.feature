@auth
Feature: Change blogname and blogdescription
  As a maintainer of the site
  I want to be able to change basic settings
  So that I have control over my site

  Scenario: Saving blogname and blogdescription
    Given I am logged in as an administrator
    Given I am on the dashboard
    When I go to the "Settings > General" menu
    And I fill in "blogname" with "Awesome WordHat Test Site"
    And I fill in "blogdescription" with "Composer + CI + Pantheon = Win!"
    And I press "submit"
    Then I should see "Settings saved."

  Scenario: Verifying blogname and blogdescription
    Given I am on the homepage
    Given I am an anonymous user
    When the cache is cleared
    Then I should see "Awesome WordHat Test Site" in the ".site-title > a" element
    And I should see "Composer + CI + Pantheon = Win!" in the ".site-description" element