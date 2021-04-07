const core = require( '@actions/core' );
const github = require( '@actions/github' );
const { WError } = require( 'error' );

/**
 * Fetch the labels of a PR.
 *
 * @returns {string[]} Labels.
 */
async function fetchLabels() {
	const octokit = github.getOctokit( core.getInput( 'token', { required: true } ) );

	const owner = github.context.payload.repository.owner.login;
	const repo = github.context.payload.repository.name;
	const prNumber = github.context.payload.pull_request.number;

	try {
        const { data } = await octokit.pulls.get({
            pull_number: prNumber,
            owner,
            repo,
          });
          
          return data.labels.map((label) => label.name);
	} catch ( error ) {
		throw new WError(
			`Failed to query ${ owner }/${ repo } PR #${ pr } labels from GitHub`,
			error,
			{}
		);
	}
}

module.exports = fetchLabels;