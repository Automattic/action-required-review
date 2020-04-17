# Required Review 

This GitHub Action will check to see if the required reviewers have accepted the PR. Will fail status checks if not. 

## Usage

This Action subscribes to [Pull request review events](https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent) which fire whenever pull requests are approved.

It checks if the PR has been approved by a person from the "required review team", which is a value you must send it. 

Instructions on how to [get your GitHub Team ID](https://developer.github.com/v3/teams/#get-team-by-name).

```workflow
on: pull_request_review
name: Check required reviews
jobs:
  check_required_reviews:
    name: Required review
    runs-on: ubuntu-latest
    steps:
    - name: Check for required review approval
      uses: automattic/action-required-review@master
      env:
        REQUIRED_REVIEW_TEAM_ID: "12345"
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        STATUS_CONTEXT: "Your custom status context." (optional. defaults to "Required review")
```

