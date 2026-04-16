import streamlit as st


def apply_dashboard_theme():
    st.markdown(
        """
        <style>
            :root {
                --stageup-navy: #123b5d;
                --stageup-blue: #2f6f9f;
                --stageup-sky: #dfeef8;
                --stageup-sand: #f5efe6;
                --stageup-ink: #1e2732;
                --stageup-card: rgba(255, 255, 255, 0.86);
                --stageup-border: rgba(18, 59, 93, 0.14);
                --stageup-shadow: 0 18px 45px rgba(18, 59, 93, 0.10);
            }

            .stApp {
                background:
                    radial-gradient(circle at top left, rgba(47, 111, 159, 0.10), transparent 30%),
                    radial-gradient(circle at top right, rgba(245, 239, 230, 0.80), transparent 24%),
                    linear-gradient(180deg, #f8fbfd 0%, #f5f8fb 52%, #eef4f8 100%);
                color: var(--stageup-ink);
            }

            .block-container {
                padding-top: 1.2rem;
                padding-bottom: 2rem;
                max-width: 1500px;
            }

            h1, h2, h3 {
                color: var(--stageup-navy);
                letter-spacing: -0.03em;
            }

            .stageup-hero {
                border: 1px solid var(--stageup-border);
                border-radius: 28px;
                background: linear-gradient(135deg, rgba(255,255,255,0.92), rgba(223,238,248,0.88));
                box-shadow: var(--stageup-shadow);
                padding: 1.4rem 1.5rem;
                margin-bottom: 1.1rem;
            }

            .stageup-hero h1 {
                margin: 0;
                font-size: 3rem;
                line-height: 1.05;
            }

            .stageup-hero p {
                margin: 0.4rem 0 0;
                font-size: 1rem;
                color: rgba(30, 39, 50, 0.74);
                max-width: 850px;
            }

            .stageup-badge {
                display: inline-block;
                padding: 0.34rem 0.7rem;
                border-radius: 999px;
                background: rgba(18, 59, 93, 0.08);
                color: var(--stageup-navy);
                border: 1px solid rgba(18, 59, 93, 0.12);
                font-size: 0.8rem;
                font-weight: 700;
                margin-bottom: 0.6rem;
            }

            .stageup-card {
                background: var(--stageup-card);
                border: 1px solid var(--stageup-border);
                border-radius: 24px;
                box-shadow: var(--stageup-shadow);
                padding: 1rem 1.1rem;
                height: 100%;
            }

            .stageup-kpi {
                font-size: 2rem;
                font-weight: 800;
                color: var(--stageup-navy);
                line-height: 1;
            }

            .stageup-kpi-label {
                margin-top: 0.3rem;
                font-size: 0.86rem;
                color: rgba(30, 39, 50, 0.70);
            }

            .stageup-section-title {
                margin: 0 0 0.75rem;
                font-size: 1.25rem;
                font-weight: 800;
                color: var(--stageup-navy);
            }

            div[data-testid="stDataFrame"] {
                border-radius: 18px;
                overflow: hidden;
                border: 1px solid rgba(18, 59, 93, 0.10);
                box-shadow: var(--stageup-shadow);
            }

            .stExpander {
                border-radius: 18px;
                border: 1px solid rgba(18, 59, 93, 0.10);
                box-shadow: 0 8px 22px rgba(18, 59, 93, 0.05);
            }

            .stButton button,
            div[data-testid="stDownloadButton"] button {
                border-radius: 999px;
                border: 0;
                background: linear-gradient(135deg, var(--stageup-blue), #4a89b8);
                color: white;
                font-weight: 700;
                box-shadow: 0 10px 24px rgba(47, 111, 159, 0.22);
            }

            .stButton button:hover,
            div[data-testid="stDownloadButton"] button:hover {
                opacity: 0.94;
                transform: translateY(-1px);
            }
        </style>
        """,
        unsafe_allow_html=True,
    )


def render_section_title(title: str, subtitle: str | None = None):
    subtitle_html = f"<p>{subtitle}</p>" if subtitle else ""
    st.markdown(
        f"""
        <div class="stageup-hero">
            <div class="stageup-badge">StageUp Inc. Object-Relational Demo</div>
            <h1>{title}</h1>
            {subtitle_html}
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_kpi(label: str, value: str):
    st.markdown(
        f"""
        <div class="stageup-card">
            <div class="stageup-kpi">{value}</div>
            <div class="stageup-kpi-label">{label}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )