import os

import oracledb
import streamlit as st

# Connection parameters are loaded from environment to avoid hardcoding secrets.
SYS_DB_USER = os.getenv("SYS_DB_USER", "SYSTEM")
SYS_DB_PASSWORD = os.getenv("SYS_DB_PASSWORD", os.getenv("ORACLE_PWD", "password123"))
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "1521")
DB_SERVICE_NAME = os.getenv("DB_SERVICE_NAME", "XE")

if "db_pool" not in st.session_state:
    st.session_state.db_pool = None
if "db_connected" not in st.session_state:
    st.session_state.db_connected = False
if "logged_in_user" not in st.session_state:
    st.session_state.logged_in_user = None


def get_all_db_users():
    """Fetches candidate database users for the login dropdown."""
    users = []
    try:
        with oracledb.connect(
            user=SYS_DB_USER,
            password=SYS_DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
            service_name=DB_SERVICE_NAME,
        ) as temp_conn:
            with temp_conn.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT USERNAME FROM ALL_USERS
                    WHERE USERNAME = 'SYSTEM'
                       OR USERNAME LIKE 'C##%'
                    ORDER BY USERNAME
                    """
                )
                for row in cursor:
                    users.append(row[0])
    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Error fetching DB users: {error_obj.message}")
        print(f"Error fetching DB users: {error_obj.message}")
    except Exception as e:
        st.error(f"An unexpected error occurred while fetching DB users: {e}")
        print(f"Unexpected error fetching DB users: {e}")
    return users


def initialize_db_pool(username, password):
    """Initializes the Oracle DB connection pool using user-provided credentials."""
    if st.session_state.db_pool:
        try:
            st.session_state.db_pool.close()
            st.session_state.db_pool = None
        except Exception as e:
            print(f"Warning: Error closing existing DB pool during re-initialization: {e}")

    try:
        pool = oracledb.create_pool(
            user=username,
            password=password,
            host=DB_HOST,
            port=DB_PORT,
            service_name=DB_SERVICE_NAME,
            min=1,
            max=3,
            increment=1,
        )
        st.session_state.db_pool = pool
        st.session_state.db_connected = True
        st.session_state.logged_in_user = username
        st.success(f"Successfully connected to the database as {username}.")
        return True
    except oracledb.Error as e:
        error_obj, = e.args
        st.session_state.db_connected = False
        st.session_state.logged_in_user = None
        st.error(f"Failed to connect to database: {error_obj.message}")
        print(f"Error initializing DB pool for {username}: {error_obj.message}")
        return False
    except Exception as e:
        st.session_state.db_connected = False
        st.session_state.logged_in_user = None
        st.error(f"An unexpected error occurred during connection: {e}")
        print(f"Unexpected error during connection: {e}")
        return False


def close_db_pool():
    """Closes the current database connection pool if it exists."""
    if st.session_state.db_pool:
        try:
            st.session_state.db_pool.close()
            st.session_state.db_pool = None
            st.session_state.db_connected = False
            print("Database connection pool closed.")
        except Exception as e:
            print(f"Error closing DB pool: {e}")


def logout():
    """Logs out the user and closes the database pool."""
    close_db_pool()
    st.session_state.logged_in_user = None
    st.info("You have been logged out.")
    st.rerun()
