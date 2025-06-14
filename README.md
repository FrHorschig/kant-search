# KantSearch

This project aims to make the works of the philosopher Immanuel Kant easily accessible and searchable. It consists of four parts:

- the [frontend](https://github.com/FrHorschig/kant-search-frontend) provides a website to read and search the text, it is implemented as an [Angular](https://angular.dev/) web application
- the [API specification](https://github.com/FrHorschig/kant-search-api) defines an API to fetch and search the texts using the [OpenAPI specification format](https://swagger.io/)
- the [backend](https://github.com/FrHorschig/kant-search-backend) is a [Go](https://go.dev/) server that implements th API endpoints defined by the OpenAPI specification and provides endpoints for adding and updating texts
- the [database](https://github.com/FrHorschig/kant-search-database) is a [PostgreSQL](https://www.postgresql.org/) database that holds the text data; it also provides the search logic by using the PostgreSQL [full-text search feature](https://www.postgresql.org/docs/current/textsearch.html)

## Contributing

If you want to improve the codebase of one of the submodules, please refer to the relevant submodule README file. If you have other comments or improvements, don't hesitate to get in contact via [email](mailto:frhorschig-coding@mailbox.org) in German or English.

## Installation

Please refer to the README files of the submodules for information about the installation process.

## Development setup

To setup this repository and its submodules, run `scripts/init.bash`.

WARNING: The following setup is made to work with a user level Docker setup, it may or may not work with the default Docker setup

### Dependencies

You need the following software to contribute to the development of the code:

- [Docker](https://www.docker.com/get-started/) for running the database container, sonarqube, sonar-scanner and the OpenAPI Generators
- [Go](https://go.dev/learn/) (Version 1.21 or greater) for compiling the Go code
- [modd](https://github.com/cortesi/modd) for starting the Go backend with live-reloading (has to be installed in ~/go/bin)
- [npm](https://docs.npmjs.com/getting-started/configuring-your-local-environment) for installing and compiling the Angular application and its dependencies
- [make](https://www.gnu.org/software/make/) for using the makefiles that simplify some development tasks (running tests, building Docker containers)

You can start the database container, the backend and the frontend locally by running `scripts/start-live-reloading`. This command initiates all three processes in the same terminal with different output colors; the frontend and backend are started with live-reloading. Note that this script expects to be run from the root of the kant-search repository and requires the submodules to be initialized.

### API code generation

You can generate Go and Typescript code from the OpenAPI specification in kant-search-api locally for easier development. Run the script `scripts/codegen-api.bash` to generate both the Go backend code and the Typescript frontend code. If you only want one or the other, use the `-t` (Typescript) or `-g` (Go) option.

### Local SonarQube analysis

You can use Docker to run a SonarQube analysis locally. Run the script 'run_sonar_scanner.bash' with the option `-s` to start a local SonarQube container. Navigate to [localhost:8000](http://localhost:8000) and wait for SonarQube to start up. Then login as user 'admin' with the password 'admin' and change the password (this has to be done only once at the first setup). After that you can create projects for the front- and backend. If you write the tokens for the projects to the environment variables `SONAR_TOKEN_FRONTEND` and `SONAR_TOKEN_BACKEND`, and put the absolute path to the kant-search repository directory into the environment variable `KANT_SEARCH_ROOT`, you can use the script 'run_sonar_scanner.bash' in the 'scripts' directory to run a SonarScanner container. Analyze the frontend code by using the `-t` (t for Typescript) option of the script or the backend code by using the `-g` (g for Go) option.
