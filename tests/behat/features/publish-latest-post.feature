@no_auth
Feature: Visibility of the latest posts
  In order to have confidence that published articles show up
  As a content author
  I want to see the latest post on the home page

  @db
  Scenario: Verify new post on the homepage
    Given there are users:
      | user_login  | user_pass | user_email       | role   |
      | test_author | test      | test@example.com | author |
    And there are posts:
      | post_title      | post_content                     | post_status | post_author |
      | Author article  | The content of my author article | publish     | test_author |
    And I am an anonymous user
    When I am on the homepage
    And the cache is cleared
    Then I should see "Author article"