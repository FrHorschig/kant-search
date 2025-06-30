# KantSearch

This project aims to make the works of the philosopher Immanuel Kant easily accessible and searchable. It consists of four parts:

- the [frontend](https://github.com/FrHorschig/kant-search-frontend) provides a website to read and search the text, it is implemented as an [Angular](https://angular.dev/) web application
- the [API specification](https://github.com/FrHorschig/kant-search-api) defines an API to fetch and search the texts using the [OpenAPI specification format](https://swagger.io/)
- the [backend](https://github.com/FrHorschig/kant-search-backend) is a [Go](https://go.dev/) server that implements th API endpoints defined by the OpenAPI specification and provides endpoints for adding and updating texts
- the backend uses an [Elasticsearch](https://www.elastic.co/) database for storing and searching the text

## Contributing

If you want to improve this code or the code of one of the submodules, please refer to the relevant submodule README file. If you have any comments or suggestions, don't hesitate to get in contact via [email](mailto:frhorschig-coding@mailbox.org) in German or in English.

## Installation

Both the backend and the frontend are available as Docker containers at [ghcr.io](ghcr.io/frhorschig/kant-search-frontend). You can deploy the kant-search applications by using the `deployment/docker-compose.yml` file by following these steps:
- copy the files in the `deployment` directory to your server
- get a certificate and its key for your domain, put them in `/etc/nginx/ssl/` and name them `hostdomain.crt` and `hostdomain.key` (or rename these strings according to your file names and locations)
- generate the certificates for the internal communication, either automatically by running the `generate-certs.sh` script or manually
- copy the backend configuration files (see README of the backend project for details) in the `config/backend` directory
- copy the frontend configuration files (see README of the frontend project for details) in the `config/frontend` directory and update the `apiUrl` entry according to your domain name
- add values for the variables in the `env.sh` file
- start the applications with `docker-compose up`

If you want to deploy the applications without Docker, please refer to the [Elasticsearch](https://www.elastic.co/docs/solutions/search) documentation and the configuration documentation in the backend and frontend README files.

## Development setup

To setup this repository and its submodules, run `scripts/init.bash`.

WARNING: The following setup is made to work with a user level Docker setup, it may or may not work with the default Docker setup

### Dependencies

You need the following software to contribute to the development of the code:

- [Docker](https://www.docker.com/get-started/) for running the database container, sonarqube, sonar-scanner and the OpenAPI Generators
- [Go](https://go.dev/learn/) (Version 1.24 or greater) for compiling the Go code
- [modd](https://github.com/cortesi/modd) for starting the Go backend with live-reloading (has to be installed in ~/go/bin)
- [delve](https://github.com/go-delve/delve) for starting the Go backend in debugging mode (has to be installed in ~/go/bin)
- [npm](https://docs.npmjs.com/getting-started/configuring-your-local-environment) for installing and compiling the Angular application and its dependencies
- [make](https://www.gnu.org/software/make/) for using the makefiles that simplify some development tasks (running tests, building Docker containers)

You can start the database container, the backend and the frontend locally by running `scripts/start-live-reloading`. This command initiates all three processes in the same terminal with different output colors; the frontend and backend are started with live-reloading. Note that this script expects to be run from the root of the kant-search repository and requires the submodules to be initialized. If you add the `-d` option, the backend application will use the delve debugger to start in debugging mode.

### API code generation

You can generate Go and Typescript code from the OpenAPI specification in kant-search-api locally for easier development. Run the script `scripts/codegen-api.bash` to generate both the Go backend code and the Typescript frontend code. If you only want only one or the other, use the `-t` (Typescript) or `-g` (Go) option.

### Local SonarQube analysis

You can use Docker to mak  a local SonarQube analysis. Run the script 'run_sonar_scanner.bash' with the `-s` option to start a local SonarQube container. Wait for the script to finish, then add the absolute path to the kant-search repository directory to the .env file. Now you can analyze the frontend code by using the script with the `-t` (t for Typescript) option or the backend code with the `-g` (g for Go) option. When the SonarScanner container is finished, navigate to [localhost:8000](http://localhost:8000), login as user 'admin' with the password 'adminnew' (the startup script changes the password to this value) and view the results of the analysis.
