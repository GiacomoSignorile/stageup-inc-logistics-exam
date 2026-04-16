import pandas as pd
import streamlit as st
import oracledb
import db_utils
from app_config import TABLES_PAGE_TITLE
from ui_theme import apply_dashboard_theme, render_section_title


db_utils.ensure_session_state()
apply_dashboard_theme()

render_section_title(
    TABLES_PAGE_TITLE,
    "A compact data room for browsing the core tables and views that power the StageUp object-relational model.",
)


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
            st.caption(f"{len(df)} rows")


if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in to view this page. Please go to **Login**.")
else:
    top_left, top_right = st.columns([1.45, 0.75], gap="large")
    with top_left:
        st.markdown('<div class="stageup-section-title">Data Browser</div>', unsafe_allow_html=True)
        st.markdown(
            """
            <div class="stageup-card">
                <p style="margin:0; color: rgba(30,39,50,0.78); line-height:1.7;">
                    Use the collapsible panels below to inspect the current state of the object-relational schema.
                    The tables are shown first, followed by the reporting views used in the application.
                </p>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with top_right:
        st.markdown('<div class="stageup-section-title">Session</div>', unsafe_allow_html=True)
        st.markdown(
            f"""
            <div class="stageup-card">
                <div style="font-size:1.55rem; font-weight:800; color: var(--stageup-navy);">{st.session_state.logged_in_user}</div>
                <div style="color: rgba(30,39,50,0.72);">Viewing live data from Oracle 21c XE</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    try:
        with st.session_state.db_pool.acquire() as connection:
            st.markdown('<div class="stageup-section-title" style="margin-top:1rem;">Core Tables</div>', unsafe_allow_html=True)
            table_left, table_right = st.columns(2, gap="large")

            with table_left:
                show_query(
                    connection,
                    "Region_TAB",
                    """
                    SELECT RegionCode, RegionName
                    FROM Region_TAB
                    ORDER BY RegionCode
                    """,
                )

                show_query(
                    connection,
                    "Office_TAB",
                    """
                      SELECT o.Name,
                          o.OfficeType,
                          o.NoEmployees,
                          (
                              SELECT DEREF(t.RegionRef).RegionName
                              FROM Team_TAB t
                              WHERE t.OfficeRef = REF(o)
                              FETCH FIRST 1 ROW ONLY
                          ) AS RegionRef,
                          o.Location.City AS City,
                          o.Location.Street AS Street,
                          o.Location.ZipCode AS ZipCode
                      FROM Office_TAB o
                      ORDER BY o.Name
                    """,
                )

                show_query(
                    connection,
                    "Team_TAB",
                    """
                    SELECT TeamCode,
                           TeamName,
                           DEREF(RegionRef).RegionName AS RegionRef,
                           N_Total_Installations,
                          (SELECT COUNT(*) FROM TABLE(CAST(Members AS Member_VA))) AS TeamSize
                    FROM Team_TAB
                    ORDER BY TeamCode
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

            with table_right:
                show_query(
                    connection,
                    "Customer_TAB",
                    """
                    SELECT CustomerCode, FirstName, LastName, Email, CustomerType
                    FROM Customer_TAB
                    ORDER BY CustomerCode
                    """,
                )

                show_query(
                    connection,
                    "Municipality_TAB",
                    """
                    SELECT m.MunicipalityCode,
                           m.MunicipalityName,
                           m.MunicipalityZipCode,
                           DEREF(m.RegionRef).RegionName AS RegionName
                    FROM Municipality_TAB m
                    ORDER BY m.MunicipalityCode
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

            st.markdown('<div class="stageup-section-title" style="margin-top:1rem;">Reporting Views</div>', unsafe_allow_html=True)
            view_left, view_right = st.columns(2, gap="large")
            with view_left:
                show_query(connection, "ViewTeamMembers", "SELECT * FROM ViewTeamMembers ORDER BY TeamCode")
                show_query(connection, "ViewCustomerLocations", "SELECT * FROM ViewCustomerLocations ORDER BY CustomerCode")
                show_query(connection, "ViewCompanyOffices", "SELECT * FROM ViewCompanyOffices ORDER BY OfficeName")
            with view_right:
                show_query(connection, "ViewBookingDetails", "SELECT * FROM ViewBookingDetails ORDER BY BookingID")
                show_query(connection, "ViewCustomerActivity", "SELECT * FROM ViewCustomerActivity ORDER BY CustomerCode")

    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Database Error: {error_obj.message}")
    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
