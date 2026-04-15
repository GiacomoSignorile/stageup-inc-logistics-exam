import pandas as pd
import streamlit as st
import oracledb
import db_utils
from app_config import TABLES_PAGE_TITLE

db_utils.ensure_session_state()

st.title(f"🗄️ {TABLES_PAGE_TITLE}")


def show_query(connection, label, sql):
    with st.expander(label, expanded=False):
        with connection.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            if not rows:
                st.info("No rows found.")
                return

            columns = [desc[0] for desc in cursor.description]
            df = pd.DataFrame(rows, columns=columns)
            st.dataframe(df, width="stretch")
            st.info(f"Showing {len(df)} rows.")


if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in to view this page. Please go to **Login**.")
else:
    st.write(f"Viewing data as: **{st.session_state.logged_in_user}**")

    try:
        with st.session_state.db_pool.acquire() as connection:
            show_query(
                connection,
                "Office_TAB",
                """
                  SELECT o.Name,
                      o.OfficeType,
                      o.NoEmployees,
                      o.Location.City AS City,
                      o.Location.Street AS Street,
                      o.Location.ZipCode AS ZipCode
                  FROM Office_TAB o
                  ORDER BY o.Name
                """,
            )

            show_query(
                connection,
                "Customer_TAB",
                """
                SELECT CustomerCode, Email, CustomerType
                FROM Customer_TAB
                ORDER BY CustomerCode
                """,
            )

            show_query(
                connection,
                "Team_TAB",
                """
                SELECT TeamCode, TeamName, NoInstallations,
                      (SELECT COUNT(*) FROM TABLE(CAST(Members AS Member_VA))) AS TeamSize
                FROM Team_TAB
                ORDER BY TeamCode
                """,
            )

            show_query(
                connection,
                "Location_TAB",
                """
                SELECT l.LocationCode,
                       l.Address.City AS City,
                       l.Address.Street AS Street,
                       l.SetupTimeEstimate,
                       l.EquipmentCapacity,
                       DEREF(l.OwnerRef).CustomerCode AS CustomerCode
                FROM Location_TAB l
                ORDER BY l.LocationCode
                """,
            )

            show_query(
                connection,
                "Equipment_TAB",
                """
                SELECT ItemCode, Description, UnitsAvailable
                FROM Equipment_TAB
                ORDER BY ItemCode
                """,
            )

            show_query(
                connection,
                "Booking_TAB",
                """
                SELECT b.BookingID,
                       b.BookingType,
                       b.BookingDate,
                       b.Duration,
                       b.TotalCost,
                       b.PlacementMode,
                       DEREF(b.AtLocation).LocationCode AS LocationCode,
                      DEREF(b.HandledBy).Name AS HandlingOffice
                FROM Booking_TAB b
                ORDER BY b.BookingID
                """,
            )

            show_query(connection, "ViewTeamMembers", "SELECT * FROM ViewTeamMembers ORDER BY TeamCode")
            show_query(connection, "ViewCustomerLocations", "SELECT * FROM ViewCustomerLocations ORDER BY CustomerCode")
            show_query(connection, "ViewBookingDetails", "SELECT * FROM ViewBookingDetails ORDER BY BookingID")
            show_query(connection, "ViewCompanyOffices", "SELECT * FROM ViewCompanyOffices ORDER BY OfficeName")
            show_query(connection, "ViewCustomerActivity", "SELECT * FROM ViewCustomerActivity ORDER BY CustomerCode")

    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Database Error: {error_obj.message}")
    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
