# Wisconsin Irrigation Scheduling Program (WISP)

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/uwent/wisp/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/uwent/wisp/tree/main)

## Description

The Wisconsin Irrigation Scheduling Program (WISP) is an irrigation water management tool developed by the Departments of Biological Systems Engineering and Soil Science at the University of Wisconsin-Madison. WISP is designed to help growers optimize crop water use efficiency by tracking the root zone water balance (water inputs and outputs). WISP incorporates several features from irrigation schedulers that have been used historically in Wisconsin.

WISP uses the checkbook method to track soil moisture on a daily basis given a user defined managed root zone depth. Soil moisture losses through evapotranspiration (ET) (primarily via plant transpiration) and deep drainage (water passing vertically through the managed root zone) are considered along with water inputs that include daily rainfall and irrigation. WISP is a soil moisture management decision support tool and is best used in combination with other information such as soil moisture monitoring and field observations when making irrigation decisions. All inputs with the exception of daily rainfall and irrigation need only be entered once during initial set up with some possible cropping season modification. Should the field crop change new inputs will be needed. The model accommodates multiple farms, pivots (water application device), fields and crops described using a hierarchal structure:

* A farm can be any set of pivots the user chooses (e.g. common ownership, location or management).
* A pivot can have one or more fields growing different crops.
* A field is typically defined by a set of common physical and/or management characteristics (e.g., crop type, soil water holding characteristics or irrigation management) assigned to a land area. Field characteristics can change from year to year.

## Dependencies

`Ruby`
```bash
# install rbenv
sudo apt -y install rbenv

# install ruby-build
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

# or update ruby-build if already installed
git -C "$(rbenv root)"/plugins/ruby-build pull

# may need to force git to use https
# per https://stackoverflow.com/questions/70663523/the-unauthenticated-git-protocol-on-port-9418-is-no-longer-supported
git config --global url."https://github.com/".insteadOf git://github.com/

# install ruby with rbenv
rbenv install 3.2.2 # or latest version

# update bundler to latest
gem install bundler
```

`Postgres` and `gem pg`
```bash
# install postgres
sudo apt -y install postgresql-14 postgresql-client-14 libpq-dev
sudo service postgresql start

# install gem pg
gem install pg

# Set postgres user password to 'password'
sudo su - postgres
psql -c "alter user postgres with password 'password'"
exit
```

## Setup

1. Ensure project dependencies outlined above are satisfied
2. Clone the project
3. Install gems with `bundle install` in project directory
4. Create database and schema with `bundle exec rake db:setup db:seed`
5. Ensure [ag-weather](https://github.com/uwent/ag-weather) is set up and running on port `8080`
6. Run the server with `bundle exec rails s`
7. Launch the site with `localhost:3000`

## Running tests

### RSpec

```bash
bundle exec rspec
```

## Deployment

Work with db admin to authorize your ssh key for the deploy user. Confirm you can access the dev and production servers:

* `ssh deploy@dev.agweather.cals.wisc.edu -p 216`
* `ssh deploy@agweather.cals.wisc.edu -p 216`

Then run the following commands from the main branch to deploy:

* Staging: `cap staging deploy`
* Production: `cap production deploy`

Deployment targets:

* Staging: [https://dev.wisp.cals.wisc.edu/](https://dev.wisp.cals.wisc.edu/)
* Production: [https://wisp.cals.wisc.edu/](https://wisp.cals.wisc.edu/)
