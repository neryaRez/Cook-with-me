"""External MySQL database access.

When DATABASE_URL is not set, the API runs entirely on in-memory mock data
(see app/routes/recipes.py) and this module stays inactive. When DATABASE_URL
is set (e.g. mysql+pymysql://user:pass@host:3306/dbname), this prepares a
SQLAlchemy engine/session so routes can be switched over to real queries.
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from . import config

engine = create_engine(config.DATABASE_URL, pool_pre_ping=True) if config.USE_DB else None
SessionLocal = sessionmaker(bind=engine) if engine else None


def get_session():
    """Return a new SQLAlchemy session for the external MySQL database.

    Callers should check config.USE_DB before calling this - it raises if
    DATABASE_URL is not configured.
    """
    if SessionLocal is None:
        raise RuntimeError("DATABASE_URL is not configured")
    return SessionLocal()
