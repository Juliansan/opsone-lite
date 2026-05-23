from ast import List
from dataclasses import dataclass
from opsone_lite.db import get_connection


@dataclass(frozen=True)
class SourceHealth:
    name: str
    passed: bool
    observed_values: object
    expected: str


CHECKS = [
    {
        "name": "customers_exist",
        "sql": "select count(*) from commerce.customers",
        "validate": lambda value: value > 0,
        "expected": "at least 1 customer",
    },
    {
        "name": "orders_exist",
        "sql": "select count(*) from commerce.orders",
        "validate": lambda value: value > 0,
        "expected": "at least 1 order",
    },
    {
        "name": "known_order_statuses_only",
        "sql": """
               select count(*)
               from commerce.orders
               where order_status not in ('completed', 'payment_failed', 'cancelled')
               """,
        "validate": lambda value: value == 0,
        "expected": "0 orders outside expected status list",
    },
    {
        "name": "known_payment_statuses_only",
        "sql": """
               select count(*)
               from commerce.payments
               where payment_status not in ('paid', 'failed', 'refunded')
               """,
        "validate": lambda value: value == 0,
        "expected": "0 payments outside expected status list",
    },
    {
        "name": "paid_payments_match_order_items_total",
        "sql": """
               with item_totals as (select order_id,
                                           round(sum(quantity * unit_price), 2) as item_total
                                    from commerce.order_items
                                    group by order_id)
               select count(*)
               from commerce.payments p
                        join item_totals i on p.order_id = i.order_id
               where p.payment_status = 'paid'
                 and p.amount <> i.item_total
               """,
        "validate": lambda value: value == 0,
        "expected": "0 paid payments where amount differs from item total",
    },
]


def run_checks() -> list[SourceHealth]:
    results: List[SourceHealth] = []

    with get_connection() as conn:
        with conn.cursor() as cur:
            for check in CHECKS:
                cur.execute(check["sql"])
                observed_values = cur.fetchone()[0]
                passed = check["validate"](observed_values)
                results.append(
                    SourceHealth(
                        name=check["name"],
                        passed=passed,
                        observed_values=observed_values,
                        expected=check["expected"]
                    )
                )
    return results


def main() -> None:
    results = run_checks()
    failed = [result for result in results if not result.passed]

    for result in results:
        status = "PASS" if result.passed else "FAIL"
        print(
            f"{status} - {result.name}: {result.observed_values} ({result.expected})"
        )

    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
