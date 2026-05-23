import psycopg

from opsone_lite.config import settings

def get_connection():
    return psycopg.connect(settings.database_url)


