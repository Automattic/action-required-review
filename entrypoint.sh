#!/bin/bash
set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Set the GITHUB_REPOSITORY env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

if [[ -z "$REQUIRED_REVIEW_TEAM_ID" ]]; then
  echo "Set the REQUIRED_REVIEW_TEAM_ID env variable."
  exit 1
fi

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

check_for_required_review() {
  body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/reviews?per_page=100")
  reviews=$(echo "$body" | jq --raw-output '.[] | @base64')
  # 887802 is the ID for the Automattic org
  required_team_api=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/organizations/887802/team/${REQUIRED_REVIEW_TEAM_ID}/members")
  required_team=$(echo "$required_team_api" | jq --raw-output '.[] | @base64')

  # Build array of required team usernames
  required_team_usernames=()
  for m in $required_team; do
    member=$(echo "$m" | base64 -d)
    login=$(echo "$member" | jq --raw-output '.login')
    required_team_usernames+=( "$login" )
  done

  pass_fail="fail"
  for r in $reviews; do
    review=$(echo "$r" | base64 -d)
    review_login=$(echo "$review" | jq --raw-output '.user["login"]')
    review_state=$(echo "$review" | jq --raw-output '.state')

    for i in "${required_team_usernames[@]}"; do
      if [ "$i" == "$review_login" ] && [ "$review_state" == 'APPROVED' ]; then
        pass_fail="true"
      fi
    done
  done

  if [ "$pass_fail" == "true" ]; then
    echo "approved!"
    exit 0
  else
    echo "failed!"
    # Intentionally no status exit.
  fi
}

check_for_required_review
