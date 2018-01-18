# Strava KOM finder



## Setup

First make a copy of the provided environment file `cp .env.sample .env` and fill in the variables


#### Database

Create a databae in postgres manually with the `CRETE DATABASE` sql command

Run sequel migrations with `sequel -m web/db/migrations <DATABASE_URI>`



#### TODO

- Speed up downloading training data
- Add ability for users to click on paths displayed on the map to highlight the segments (maybe tooltips?)
- Return a 403 for users who are not logged in for anything other than the homepage.
- Add ability to get more info about trained segments
- Look into limiting training data to only more frequently attempted segments (maybe 2-3 trys at least)
- Handle situation where predicted speed is blow zero :D
- Find out why predictions are sometimes very innacurate (200km/h+ is estimated sometimes)
- Add ability to ignore segments (eg: mtb segments)
- Return rate limiting info to the frontend and add warning messages about it.
- Investigate accuracy of estimations
- Tidy up interface
- Add error handling :)
