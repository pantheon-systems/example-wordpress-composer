Feature: Change blogname and blogdescription (no-js)
  As a maintainer of the site
  I want to be able to change basic settings
  So that I have control over my site

  Background:
    Given I am logged in as an admin
    Given I am on the dashboard


  Scenario: Saving blogname
    Given I go to menu item "Settings > General"
    When I fill in "blogname" with "Awesome WordHat Test Site"
    And I press "submit"
    And I should see "Settings saved."
    And I am on the homepage
    Then I should see "Awesome WordHat Test Site" in the "h1 a" element

  Scenario: Saving blogdescription
    Given I go to menu item "Settings > General"
    When I fill in "blogdescription" with "GitHub + Composer + CircleCi + Pantheon = Win!"
    And I press "submit"
    And I should see "Settings saved."
    And I am on the homepage
    Then I should see "GitHub + Composer + CircleCi + Pantheon = Win!" in the ".site-description" element
