# Strava KOM finder



## Setup

First make a copy of the provided environment file `cp .env.sample .env` and fill in the variables


#### Database

Create a databae in postgres manually with the `CRETE DATABASE` sql command

Run sequel migrations with `sequel -m web/db/migrations <DATABASE_URI>`
