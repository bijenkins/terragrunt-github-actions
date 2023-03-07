#!/bin/bash

function terragruntApply {
  # Gather the output of `terragrunt apply`.
  echo "apply: info: applying Terragrunt configuration in ${tfWorkingDir}"
  applyOutput=$(${tfBinary} apply -auto-approve -input=false ${*} 2>&1)
  applyExitCode=${?}
  applyCommentStatus="Failed"

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${applyExitCode} -eq 0 ]; then
    echo "apply: info: successfully applied Terragrunt configuration in ${tfWorkingDir}"
    echo "${applyOutput}"
    echo
    applyCommentStatus="Success"
  fi

  # Exit code of !0 indicates failure.
  if [ ${applyExitCode} -ne 0 ]; then
    echo "apply: error: failed to apply Terragrunt configuration in ${tfWorkingDir}"
    echo "${applyOutput}"
    echo
  fi

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ]; then
    applyCommentWrapper="#### \`${tfBinary} apply\` ${applyCommentStatus}
<details><summary>Show Output</summary>

\`\`\`
${applyOutput}
\`\`\`

</details>

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`, Workspace: \`${tfWorkspace}\`*"

    applyCommentWrapper=$(stripColors "${applyCommentWrapper}")
    echo "apply: info: creating JSON"
    applyPayload=$(echo "${applyCommentWrapper}" | jq -R --slurp '{body: .}')
    applyCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "apply: info: commenting on the pull request"
    # echo "${applyPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${applyCommentsURL}" > /dev/null
    curl -v -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${applyCommentsURL}" \
    -d "${applyPayload}"
  fi

  exit ${applyExitCode}
}
