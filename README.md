# StageUp Event Setup Exam Project
> Object-relational Oracle 21c project template for database systems exam practice.

[![CC BY-NC 4.0][cc-by-nc-shield]][cc-by-nc]

[cc-by-nc]: https://creativecommons.org/licenses/by-nc/4.0/
[cc-by-nc-image]: https://licensebuttons.net/l/by-nc/4.0/88x31.png
[cc-by-nc-shield]: https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg

## Project Overview

This repository implements an Oracle object-relational event setup system with a Streamlit demo app.

The current implementation is based on these core entities:

- Office_TAB
- Customer_TAB
- Team_TAB
- Location_TAB
- Equipment_TAB
- Booking_TAB

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Python 3.12](https://www.python.org/downloads/)

### Launching the Database with Docker Compose

1. Clone the repository:
    ```bash
  git clone https://github.com/<your-username>/stageup-inc-logistics-exam.git
  cd stageup-inc-logistics-exam
    ```
2. Create your local environment file:
  ```bash
  cp .env.example .env
  ```
3. Start the Oracle 21c database:
    ```bash
    docker-compose up -d
    ```
4. Wait **a few minutes** for the database to initialize.

### Running the Streamlit Demo

1. Install Python dependencies:
    ```bash
    pip install -r webapp/requirements.txt
    ```
2. Launch the Streamlit app:
    ```bash
    streamlit run webapp/Home.py
    ```
3. Open your browser and go to the URL provided by Streamlit.

## Database Bootstrap Order

The Docker container executes scripts in this order:

1. scripts/00_stageupdba.sql
2. scripts/01_types.sql
3. scripts/02_tables.sql
4. scripts/03_indexes.sql
5. scripts/04_triggers.sql
6. scripts/05_views.sql
7. scripts/06_populatedb.sql
8. scripts/07_triggertests.sql

This order is required because triggers and views depend on tables, and tests depend on populated data.

## Implemented Object Types

The schema uses Oracle object-relational features including object types, REF columns, VARRAY collections, and views built with DEREF.

Main custom types:

- Address_t
- Member_t
- Member_VA
- Team_t
- Office_t
- Customer_t
- Location_t
- Booking_t

## Implemented Tables

- Office_TAB
- Customer_TAB
- Team_TAB
- Location_TAB
- Equipment_TAB
- Booking_TAB

## Implemented Indexes

Indexes are defined in scripts/03_indexes.sql for:

- REF navigation fields in Booking_TAB and Location_TAB
- Team performance sorting
- Booking categorical filtering
- Office type filtering

## Implemented Triggers

Triggers are defined in scripts/04_triggers.sql and include:

- Synchronization of Team_TAB.NoInstallations when Booking_TAB rows are inserted, deleted, or reassigned
- Team insertion/update constraints on NoInstallations changes

See scripts/01_types.sql through scripts/07_triggertests.sql for full DDL, data population, and validation tests.

## Streamlit Demo Home Page

Below is a screenshot of the Streamlit demo application's home page:

![Streamlit Demo Home Page](images/home.png)

## Login Page

To access the demo application, use credentials defined in your `.env` file:

- `SYS_DB_USER` / `SYS_DB_PASSWORD` for the user list lookup
- Schema user password (for example `STAGEUPDBA_PWD`) for app login

> **Tip:** If the current date from the database is displayed correctly in the demo app, your connection to the Oracle 21c database is working as expected.

![Streamlit Demo Login Page](images/login.png)

## Tables Overview

The following screenshot displays all database tables as shown in the demo application after automatic population by Docker:

![Tables Overview](images/tables.png)

> If some tables appear empty, it means you logged in before the population process was completed. Please close the streamlit demo and do the whole procedure by the start.

## Streamlit Pages

The application exposes the following pages in webapp/pages:

- 1_Login.py: user login and connection test
- 2_Tables.py: raw tables and view previews
- 3_Register_New_Product_Batch.py: create new booking
- 4_Place_New_Order.py: edit booking details
- 5_Team_Performance.py: team and booking analytics
- 6_Assign_Delivery_To_Team.py: reassign booking team
- 7_View_Team_Deliveries.py: team booking report
- 8_List_Expired_Batches.py: upcoming bookings report

## Notes

- The data population script generates realistic synthetic data for demo/testing.
- Trigger tests intentionally include expected failures to validate constraints.
- Equipment stock updates are currently manual because no direct Booking-to-Equipment relation is modeled.

## License

This work is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License][cc-by-nc].

For a copy of the license, please visit https://creativecommons.org/licenses/by-nc/4.0/

[![CC BY-NC 4.0][cc-by-nc-image]][cc-by-nc]
