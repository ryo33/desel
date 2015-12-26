Feature: desel
    Scenario: desel help
    When I successfully run `desel help`
    Then the output should contain "desel - handle Desel"
