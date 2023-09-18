## Setup

To setup this repository, run `scripts/init.bash`.

## API code generation

To regenerate the API code, run `scripts/api-codegen.bash`. Make sure that the `GO_POST_PROCESS_FILE` environment variable is set to `<path-to-gofmt-executable> -w` and `TS_POST_PROCESS_FILE` to `<path-to-prettier-executable> --write`. Note that this script expects to be run from the `kant-search` directory. It also expects the `USER` environment variable to be set to the current user.

## Development setup

You can start the database container, the backend and the frontend app locally by running `scripts/start_all`. This command initiates all three processes in the same terminal with different output colors. The frontend and backend app are started with live-reloading. Note that this script expects to be run from the `kant-search` directory.

In order for this setup to function correctly, ensure that you have:

- built the database container: go to kant-search-database and run `make`
- have Modd installed in the ~/go/bin/ directory (for live-reloading of the backend application): execute the following command in the backend directory: go install github.com/cortesi/modd/cmd/modd@latest
- have a working python installation (needed for the python virtual environment used in the backend)
