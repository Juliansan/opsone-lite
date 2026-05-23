from opsone_lite.db import get_connection
from opsone_lite.source_health import run_checks


def test_required_tables_exist():
    expected_tables = {
        "customers",
        "products",
        "orders",
        "order_items",
        "payments",
    }

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT table_name
                FROM INFORMATION_SCHEMA.TABLES
                where table_schema = 'commerce'
                """)
            actual_tables = {row[0] for row in cur.fetchall()}

    assert expected_tables.issubset(actual_tables)


def test_source_health_check_pass():
    results = run_checks()
    failed = [result for result in results if not result.passed]

    assert failed == []


