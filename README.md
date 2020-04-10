# Required Review 

This GitHub Action will check to see if the required reviewers have accepted the PR. Will fail status checks if not. 

## Usage

This Action subscribes to [Pull request review events](https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent) which fire whenever pull requests are approved. The action requires two environment variables – the label name to add and the number of required approvals. Optionally you can provide a label name to remove.

```workflow
on: pull_request_review
name: Check required reviews
jobs:
  check_required_reviews:
    name: Label when approved
    runs-on: ubuntu-latest
    steps:
    - name: Check for required review approval
      uses: automattic/action-required-review@master
      env:
        REQUIRED_REVIEW_TEAM_ID: "12345"
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

