# Strava KOM finder



## Setup

First make a copy of the provided environment file `cp .env.sample .env` and fill in the variables


#### Database

Create a databae in postgres manually with the `CRETE DATABASE` sql command

Run sequel migrations with `sequel -m web/db/migrations <DATABASE_URI>`



#### TODO

- Cache segment leaderboards in the DB for a few hours at least to speed up lookup
- Add a button to trigger a 'scan' of the map for segments (or auto trigger when the user stops navigating)
- Sort segments based on estimated speed
- Add ability to get more info about trained segments
- Link titles of segments to the strava URL
- Look into limiting training data to only more frequently attempted segments (maybe 2-3 trys at least)
- Handle situation where predicted speed is blow zero :D
- Add ability to ignore segments
- Tidy up interface
- Add error handling :)
