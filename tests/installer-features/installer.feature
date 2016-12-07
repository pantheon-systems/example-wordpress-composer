Feature: Installer
  In order to know that we can install the site via the installer
  As a website user
  I need to be able to install a Drupal site

  Scenario: Installer is ready
    Given I have wiped the site
    And I am on "/core/install.php"
    Then I should see "Choose language"

  Scenario: Language selection
    Given I am on "/core/install.php"
    And I press "Save and continue"
    Then I should see "Select an installation profile"

  Scenario: Profile selection
    Given I am on "/core/install.php?langcode=en"
    And I press "Save and continue"
    And I wait for the progress bar to finish
    Then I should see "Site name"

  Scenario: Configure site
    Given I am on "/core/install.php?langcode=en&profile=standard"
    And I enter "Example Dot Com Test Site" for "edit-site-name"
    And I enter "john.doe@example.com" for "edit-site-mail"
    And I enter "admin" for "Username"
    And I enter the value of the env var "ADMIN_PASSWORD" for "edit-account-pass-pass1"
    And I enter the value of the env var "ADMIN_PASSWORD" for "edit-account-pass-pass2"
    And I enter "john.doe@example.com" for "edit-account-mail"
    And I press "Save and continue"
    And I visit "/"
    Then I should see "Welcome to Example Dot Com"
