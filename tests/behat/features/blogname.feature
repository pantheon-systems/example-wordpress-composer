Feature: Change blogname and blogdescription
  As a maintainer of the site
  I want to be able to change basic settings
  So that I have control over my site

  Background:
    Given I am logged in as an administrator

  Scenario: Saving blogname and blogdescription
    Given I am on the dashboard
    Given I go to the "Settings > General" menu
    When I fill in "blogname" with "Awesome GitLab WordHat Test Site"
    And I fill in "blogdescription" with "GitLab + Composer + Pantheon = Win!"
    And I press "submit"
    Then I should see "Settings saved."

  Scenario: Verifying blogname and blogdescription
    Given I am on the homepage
    And the cache is cleared
    Then I should see "Awesome GitLab WordHat Test Site" in the ".site-title > a" element
    And I should see "GitLab + Composer + Pantheon = Win!" in the ".site-description" element