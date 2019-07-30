Feature: Change blogname and blogdescription
  As a maintainer of the site
  I want to be able to change basic settings
  So that I have control over my site

  Scenario: Saving blogname and blogdescription
    Given I am logged in as an administrator
    Given I am on the dashboard
    Then I should be logged in
    When I go to the "Settings > General" menu
    And I take a Chrome screenshot "settings-menu-before-blogname-changes.png"
    And I fill in "blogname" with "Awesome WordHat Test Site!"
    And I fill in "blogdescription" with "Composer + CI + Pantheon is a win!"
    And I press "submit"
    Then I should see "Settings saved."
    And I take a Chrome screenshot "settings-menu-after-blogname-changes.png"

  Scenario: Verifying blogname and blogdescription
    Given I am on the homepage
    And the Pantheon cache has been cleared
    Then I should be on the homepage
    And I should not be logged in
    And I take a Chrome screenshot "homepage-after-blogname-changes.png"
    And I should see "Awesome WordHat Test Site!" in the ".site-title > a" element
    And I should see "Composer + CI + Pantheon is a win!" in the ".site-description" element