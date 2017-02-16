# Example Drops 8 Composer

This repository can be used to set up a Composer-Managed Drupal 8 site on [Pantheon](https://pantheon.io).

[![CircleCI](https://circleci.com/gh/pantheon-systems/example-drops-8-composer.svg?style=svg)](https://circleci.com/gh/pantheon-systems/example-drops-8-composer)

## Overview

This project contains only the canonical resources used to build a Drupal site for use on Pantheon. There are two different ways that it can be used:

- Create a separate canonical repository on GitHub; maintain using a pull request workflow.
- Build the full Drupal site and then install it on Pantheon; maintain using `terminus composer` and on-server development.

The setup instructions vary based on which of these options you select.

## Pull Request Workflow

When using a pull request workflow, only the canonical resources (code, configuration, etc.) exists in the master repository, stored on GitHub. A build step is used to create the full Drupal site and automatically deploy it to Pantheon. Pull requests are the primary means of doing site development; however, new pull requests can be created directly from your Pantheon dashboard in SFTP mode using on-server development. However, the Pantheon repository should be considered as "scratch space" only. The persistent project resources are maintained in the canonical repository; the Pantheon repository is only used to hold the build results to be served.

### Terminus Build Tools Plugin

To get started, first install [Terminus](https://pantheon.io/docs/terminus) and the [Terminus Build Tools Plugin](https://github.com/pantheon-systems/terminus-build-tools-plugin).

### Credentials

The first thing that you need to do is set up credentials to access GitHub, Pantheon and Circle CI. Instructions on creating these credentials can be found on the pages listed below:

- GitHub: https://help.github.com/articles/creating-an-access-token-for-command-line-use/
- Pantheon: https://pantheon.io/docs/machine-tokens/
- Circle CI: https://circleci.com/docs/api/#authentication

These credentials should be exported as environment variables. For example:
```
#!/bin/bash
export GITHUB_TOKEN=[REDACTED]
export TERMINUS_TOKEN=[REDACTED]
export CIRCLE_TOKEN=[REDACTED]
```
If you choose to store these credentials in a bash script, be sure to protect the file to avoid unintentional exposure. Consider encrypting the file. Never commit these credentials to a repository, or place them on an unsecured web server.

To load these credentials:
```
$ source credentials.sh
```

### Create a New Project Quickstart

A single Terminus command to set up the needed GitHub, Pantheon and Circle CI projects is [under development in a Build Tools Plugin pull request](https://github.com/pantheon-systems/terminus-build-tools-plugin/pull/3). See the [updated README](https://github.com/pantheon-systems/terminus-build-tools-plugin/blob/74a922665fd8034019782805bb58a7ecaf2c8cd6/README.md) for more information.

You may also follow the instructions below to do the setup that the tool does automatically.

### Fork this Project

First, [bring up this project in GitHub](https://github.com/pantheon-systems/example-drops-8-composer) and click on the "Fork" button. Pick a suitable name for your new site.

Next, click on the "Clone or Download" button and make a local working copy of your new repository. This is where we will do most of our work. To start out, install the project assets with Composer:
```
$ cd my-site
$ composer install
```

### Create a Pantheon Site

Since our goal is to use Pantheon, we should next [create a new site](https://pantheon.io/docs/create-sites/). Give it a name similar to the one you used for the GitHub repository you forked. You may use Terminus to create the nwe site:
```
$ terminus site:create my-site "My Site" "Drupal 8" --org="My Team"
```

Next, use Terminus to find out the URL to the Pantheon repository, and add a new remote to your local working copy of your canonical repository created in the previous step.
```
$ PANTHEON_REPO=$(terminus connection:info my-site.dev --field=git_url)
$ git remote add pantheon $PANTHEON_REPO
$ git push --force pantheon master
```
### Enable Testing on Circle

Enable the GitHub project for your site in Circle CI. Define the environment variables below in the "environment variables" section under "Project Settings”: 

- TERMINUS_TOKEN: The Terminus Machine token previously created.
- GITHUB_TOKEN: Used by CircleCI to post comments on pull requests.
- TERMINUS_SITE: The name of the Pantheon site that will be used to test your site.
- TEST_SITE_NAME: Used to set the name of the test  site when installing Drupal.
- ADMIN_EMAIL: Used to configure the email address to use when installing Drupal.
- ADMIN_PASSWORD: Used to set the password for the uid 1 user during site installation.
- GIT_EMAIL: Used to configure the git user’s email address for commits we make.

Also, create a [public/private key pair](https://pantheon.io/docs/ssh-keys/) and add the private key to Circle CI, and the public key to your Pantheon site. You may use Terminus to add the public key to your Pantheon site:
```
$ terminus ssh-key:add ~/.ssh/id_rsa.pub
```
At this point, you should be able to click "rebuild" on your last Circle CI build, and all of the tests should run and pass.

## Pantheon "Standalone" Development

This project can also be used to do traditional "standalone" development on Pantheon using on-server development. In this mode, the canonical repository is immediately built out into a full Drupal site, and the results are committed to the Pantheon repository. Thereafter, no canoncial repository is used; all development will be done exclusively using the Pantheon database.

When doing "standalone" development, this project can either be used as an upstream repository, or it can be set up manually. The instructions for doing either follows in the section below.

### As an Upstream

Create a custom upstream for this project following the instructions in the [Pantheon Custom Upstream documentation](https://pantheon.io/docs/custom-upstream/). When you do this, Pantheon will automatically run composer install to populate the web and vendor directories each time you create a site.

### Manual Setup

Enter the commands below to create a a new site on Pantheon and push a copy of this project up to it.
```
$ SITE="my-site"
$ terminus site:create $SITE "My Site" "Drupal 8" --org="My Team"
$ composer create-project pantheon-systems/example-drops-8-composer $SITE
$ cd $SITE
$ composer prepare-for-pantheon
$ git init
$ git add -A .
$ git commit -m "Initial commit"
$ terminus  connection:set $SITE.dev git
$ PANTHEON_REPO=$(terminus connection:info $SITE.dev --field=git_url)
$ git remote add origin $PANTHEON_REPO
$ git push --force origin master
$ terminus drush $SITE.dev -- site-install --site-name="My Drupal Site"
$ terminus dashboard:view $SITE
```
Replace my-site with the name that you gave your Pantheon site. Customize the parameters of the `site:create` and `site-install` lines to suit.

### Installing Drupal

Note that this example repository sets the installation profile to 'standard' in settings.php, so that the installer will not need to modify the settings file. If you would like to install a different profile, modify settings.php appropriately before installing your site.

### Updating Your Site

When using this repository to manage your Drupal 8 site, you will no longer use the Pantheon dashboard to update your Drupal version. Instead, you will manage your updates using Composer. Updates can be applied either directly on Pantheon, by using Terminus, or on your local machine.

#### Update with Terminus

Install [Terminus 1](https://pantheon.io/docs/terminus/) and the [Terminus Composer plugin](https://github.com/pantheon-systems/terminus-composer-plugin).  Then, to update your site, ensure it is in SFTP mode, and then run:
```
terminus composer <sitename>.<dev> update
```
Other commands will work as well; for example, you may install new modules using `terminus composer <sitename>.<dev> require drupal/pathauto`.

#### Update on your local machine

You may also place your site in Git mode, clone it locally, and then run composer commands from there.  Commit and push your files back up to Pantheon as usual.
