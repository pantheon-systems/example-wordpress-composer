Feature: Visibility of the latest posts
  In order to have confidence that published articles show up
  As a content author
  I want to see the latest post on the home page

Background:
    Given there are users:
      | user_login  | user_pass | user_email       | role   |
      | test_author | test      | test@example.com | author |
    And there are posts:
      | post_title      | post_content                     | post_status | post_author |
      | Author article  | The content of my author article | publish     | test_author |
    And the Pantheon cache has been cleared

  Scenario: Verify new post on the front-end and in the admin
    Given I am an anonymous user
    When I am on the homepage
    Then I should not be logged in
    And I should see "Author article"
    When I am logged in as an administrator
    And I am on the dashboard
    And I go to the "Posts" menu
    Then I should see "Author article"
