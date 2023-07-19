## Setup

To setup this repository, run `scripts/init.bash`.

## API code generation

To regenerate the API code, run `scripts/api-codegen.bash`. Make sure that the `GO_POST_PROCESS_FILE` environment variable is set to `<path-to-gofmt-executable> -w` and `TS_POST_PROCESS_FILE` to `<path-to-prettier-executable> --write`.

## Development setup

You can start the database container, the backend and the frontend app locally by running `scripts/start_all`. This command initiates all three processes in the same terminal with different output colors. The frontend and backend app are started with live-reloading.

In order for this setup to function correctly, ensure that you have built the database container, have Modd installed in the ~/go/bin/ directory (needed for starting the backend with live-reloading) and have a working python installation (needed for the python virtual environment used in the backend). To install Modd, execute the following command in the backend directory: go install github.com/cortesi/modd/cmd/modd@latest.
