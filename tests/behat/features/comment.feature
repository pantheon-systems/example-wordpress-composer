Feature: Making comments
In order to engage in conversation on the site
As a website vistor
I want to make a comment

  Scenario: Pending message
    Given I am on "?p=1"
    And I fill in "Comment" with "hello"
    And I fill in "Name" with "Tessa2"
    And I fill in "Email" with "test2@example.com"
    And I fill in "Website" with "https://www.pantheon.io"
    And I press "Post Comment"
    Then I should see "Your comment is awaiting moderation."

  Scenario: Pending message
    Given I am on "?p=1"
    And I fill in "Comment" with "hello"
    And I fill in "Name" with "Tessa2"
    And I fill in "Email" with "test2@example.com"
    And I fill in "Website" with "https://www.pantheon.io"
    And I press "Post Comment"
    Then I should see "Duplicate comment detected; it looks as though you’ve already said that!"

  Scenario: Pending message
    Given I am on "?p=1"
    And I fill in the comment form
    Then I should see "Your comment is awaiting moderation."
