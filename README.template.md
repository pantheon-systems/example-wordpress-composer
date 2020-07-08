# FIXME WordPress

[![Dev Site fix-me](https://img.shields.io/badge/site-fix_me-blue.svg)](http://dev-fix-me.pantheonsite.io/)  
[![Dashboard fix-me](https://img.shields.io/badge/dashboard-fix_me-yellow.svg)](https://dashboard.pantheon.io/sites/FIXME#dev/code)  
[![CircleCI](https://circleci.com/gh/Threespot/fix-me.svg?style=shield&circle-token=94d0633ad856a188c8cf3582fcc8f259269f74f9)](https://circleci.com/gh/Threespot/fix-me)  

## Outline

- [Pantheon Environments](#pantheon-environments)
- [Local Development](#local-development)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Boot WordPress Application](#boot-word-press-application)
  - [Boot Theme (Webpack) Server](#boot-theme-webpack-server)
  - [Pull Files and Database from Pantheon](#pull-files-and-database-from-pantheon)
- [Deploying](#deploying)
  - [Deployment Using Terminus](#deployment-using-terminus)
    - [Test Environment](#test-environment)
    - [Live Environment](#live-environment)
- [Troubleshooting](/docs/troubleshooting.md)

## Pantheon Environments

- **Live** - http://live-fix-me.pantheonsite.io/
- **Test** - http://test-fix-me.pantheonsite.io/
- **Dev** - http://dev-fix-me.pantheonsite.io/

## Local Development

In order to more easily recreate the production environment locally, [Lando](https://lando.dev/) is used for local development. We also use Pantheon’s CLI, Terminus, to sync files and databases.

- **PHP Server** - http://fix-me.lndo.site/
- **Webpack Server** - https://localhost:3000

### Prerequisites

Install all the required local dependencies:

- [Git Version Control](https://git-scm.com/downloads)
- [Docker](https://www.docker.com/products/docker-desktop)
- Lando v3.0.6 ([Windows](https://docs.devwithlando.io/installation/windows.html), [macOS](https://docs.devwithlando.io/installation/macos.html))
- [Terminus](https://pantheon.io/docs/terminus/install/) 2.3.0, Pantheon’s CLI tool
- [Composer](https://getcomposer.org/doc/00-intro.md)
- [Node](https://nodejs.org/en/)  10.21.0
  Note: The sage theme dependencies do not support version of Node greater than 10. We recommend [asdf](https://github.com/asdf-vm/asdf) for managing multiple versions of Node
- Yarn
  ([Windows](https://yarnpkg.com/en/docs/install#windows-stable), [macOS](https://yarnpkg.com/en/docs/install#mac-stable))

You'll also need write access to this repo and be a member of the [Pantheon Project](https://dashboard.pantheon.io/sites/FIXME#dev/code).

### Installation

1. Clone the Repo  
   `$ git clone https://github.com/Threespot/fix-me.git`
1. Install Application Composer Dependencies  
   `$ composer install`
1. Install Theme Composer Dependencies
   - Navigate to the sage theme directory  
     `$ cd web/wp-content/themes/sage`
   - Install Componser deps  
     `$ composer install`
1. Install Theme Node Dependencies
   - Navigate to the sage theme directory  
     `$ cd web/wp-content/themes/sage`
   - Install Node deps  
     `$ yarn install` from the theme directory

### Boot WordPress Application

With all the dependencies installed, from the root project directory run:

```
lando start
```

If this is the first time running this command, Lando will build the necessary Docker containers.

To stop the server run:

```
lando stop
```

Other Lando CLI command can be read here in the [Lando docs](https://docs.lando.dev/basics/usage.html)

### Boot Theme (Webpack) Server

Making CSS or JS updates requires running Webpack to recompile and inject the CSS and JS.

1. Navigate to the theme folder  
   `$ cd /web/wp-content/themes/sage`

1. Install npm dependencies using Yarn  
   `$ yarn install`

1. Start Webpack  
   `$ yarn start`

1. You should now be able to view the site locally at https://localhost:3000
1. To stop the server, press <kbd>Control</kbd> + <kbd>C</kbd>

### Pull Files and Database from Pantheon

Lando is used to pull uploads and data from Pantheon. [See docs here](https://docs.lando.dev/config/pantheon.html#importing-your-database-and-files).

```
lando pull --database=test --files=test --code=none
```

## Deploying

Code committed to the remote `master` branch is automatically deployed to the `dev` environement on Pantheon. After a local branch is pushed, [CircleCI](https://circleci.com/gh/Threespot/fix-me) will build and deploy the files to Pantheon’s [dev environment](https://dashboard.pantheon.io/sites/5118c78c-b29d-467c-b178-2728fe3f293c#dev/code). You can tell CircleCI to not run by adding `[skip ci]` to the commit message.

Code that exists on `dev` can be promoted to the `test` enviroment, and `test` can be promoted to the `live` environment. Details about the application lifecycle can be read [here](https://pantheon.io/agencies/development-workflow/dev-test-live-workflow).
Feature branches with a corresponding pull request will create a multi-dev enviroment used for testing indiviual features. Docs are available [here](https://pantheon.io/docs/multidev)

### Deployment Using Terminus

#### Test Environment

Code will be promoted from `dev` to `test`

```shell
lando composer run-script deploy:test
```

**NOTE:** this composer script will also purge Pantheon's cache.

or

```shell
lando terminus env:deploy fix-me.test
```

#### Live Environment

Code will be promoted from `test` to `live`

```shell
lando composer run-script deploy:live
```

or

```shell
lando terminus env:deploy fix-me.live
```