# Wisconsin Irrigation Scheduling Program (WISP)
[![Circle CI](https://circleci.com/gh/uwent/wisp.svg?style=svg&circle-token=ac949534b314e7ad331b2373135f52a52fba512b)](https://circleci.com/gh/uwent/wisp)

## Description
The Wisconsin Irrigation Scheduling Program (WISP) is an irrigation water management tool developed by the Departments of Biological Systems Engineering and Soil Science at the University of Wisconsin-Madison. WISP is designed to help growers optimize crop water use efficiency by tracking the root zone water balance (water inputs and outputs). WISP incorporates several features from irrigation schedulers that have been used historically in Wisconsin.
WISP uses the checkbook method to track soil moisture on a daily basis given a user defined managed root zone depth. Soil moisture losses through evapotranspiration (ET) (primarily via plant transpiration) and deep drainage (water passing vertically through the managed root zone) are considered along with water inputs that include daily rainfall and irrigation. WISP is a soil moisture management decision support tool and is best used in combination with other information such as soil moisture monitoring and field observations when making irrigation decisions. All inputs with the exception of daily rainfall and irrigation need only be entered once during initial set up with some possible cropping season modification. Should the field crop change new inputs will be needed. The model accommodates multiple farms, pivots (water application device), fields and crops described using a hierarchal structure:
* A farm can be any set of pivots the user chooses (e.g. common ownership, location or management).
* A pivot can have one or more fields growing different crops.
* A field is typically defined by a set of common physical and/or management characteristics (e.g., crop type, soil water holding characteristics or irrigation management) assigned to a land area. Field characteristics can change from year to year.

## Dependencies

Ruby version `2.7.x`

Rails version `6.1.x`

Postgres

## Setup
1. Clone the project
2. Install dependencies
```
bundle install
```
3. Create database and schema and load seeds
```
bundle exec rails db:create db:schema:load db:seed
```
4. Start server
```
bundle exec rails s
```
5. Point your browser to `localhost:3000`

## Running tests
```
bundle exec rspec
```

## Deployment
Work with db admin to authorize your ssh key for the deploy user, then run the following commands from the master branch:

### Staging:
```
cap staging deploy
```
### Production:
```
cap production deploy
```
