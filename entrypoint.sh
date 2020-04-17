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

if [[ -z "$STATUS_CONTEXT" ]]; then
  STATUS_CONTEXT="Required review"
fi

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
sha=$(jq --raw-output .pull_request.head.sha "$GITHUB_EVENT_PATH")

check_for_required_review () {
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

  status="pending"
  description="Pending approval."

  for r in $reviews; do
    review=$(echo "$r" | base64 -d)

    review_login=$(echo "$review" | jq --raw-output '.user["login"]')
    review_state=$(echo "$review" | jq --raw-output '.state')

    # Only care about reviews from required team.
    # These will loop in chronological order, ending with the most recent
    if [[ "${required_team_usernames[@]}" =~ "${review_login}" ]]; then
      if [ "$review_state" == 'APPROVED' ]; then
        status="success"
        description="Accepted!"
      elif [ "$review_state" == 'CHANGES_REQUESTED' ]; then
        status="failure"
        description="Changes requested."
      else
        status="pending"
        description="Pending approval."
      fi
    fi
  done

  curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"state\":\"${status}\", \"target_url\":\"https://github.com/Automattic/jetpack/pull/${number}/commits/${sha}\", \"description\":\"${description}\", \"context\":\"${STATUS_CONTEXT}\" }" \
        "${URI}/repos/${GITHUB_REPOSITORY}/statuses/${sha}"

  echo "$status"
  echo "$description"
}

check_for_required_review
