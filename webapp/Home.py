import streamlit as st
import db_utils
from app_config import APP_SUBTITLE, APP_TITLE


st.title(f"📦 {APP_TITLE}")
st.markdown(APP_SUBTITLE)

if st.session_state.logged_in_user:
    st.success(f"You are logged in as: **{st.session_state.logged_in_user}**")
    st.markdown("Use the sidebar to navigate through operations and reports.")
else:
    st.warning("Please open **Login** in the sidebar to connect to the database.")

st.markdown("---")

if st.session_state.db_connected:
    st.info("Database connection pool is active.")
else:
    st.info("Database connection pool is inactive.")
