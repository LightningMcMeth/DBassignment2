USE assignment1;

create index opt_orders_client_id
  on opt_orders(client_id);

EXPLAIN ANALYZE
WITH cte AS (
	SELECT o.client_id, o.order_date, c.id, o.order_id
		FROM opt_orders AS o
		JOIN opt_clients AS c
		WHERE (o.order_date BETWEEN '2021-03-12' AND '2023-01-01') AND o.order_id > 600
		LIMIT 15000
)

SELECT 
    CONCAT("Total client count: ", (SELECT COUNT(client_id) FROM cte)) AS total_client_count,
    CONCAT("Oldest order: ", (SELECT MIN(order_date) FROM cte)) AS oldest_order_date,
    CONCAT("Most recent order: ", (SELECT MAX(order_date) FROM cte)) AS most_recent_order_date;

   
-> Rows fetched before execution  (cost=0..0 rows=1) (actual time=200e-6..300e-6 rows=1 loops=1)
-> Select #2 (subquery in projection; run only once)
    -> Aggregate: count(cte.client_id)  (cost=571e+6..571e+6 rows=1) (actual time=39.7..39.7 rows=1 loops=1)
        -> Table scan on cte  (cost=571e+6..571e+6 rows=15000) (actual time=37.4..39 rows=15000 loops=1)
            -> Materialize CTE cte if needed  (cost=571e+6..571e+6 rows=15000) (actual time=37.4..37.4 rows=15000 loops=1)
                -> Limit: 15000 row(s)  (cost=571e+6 rows=15000) (actual time=28.1..30.7 rows=15000 loops=1)
                    -> Inner hash join (no condition)  (cost=571e+6 rows=5.71e+9) (actual time=28.1..29.8 rows=15000 loops=1)
                        -> Covering index scan on c using PRIMARY  (cost=0.432 rows=103173) (actual time=0.0359..0.0423 rows=3 loops=1)
                        -> Hash
                            -> Filter: ((o.order_date between '2021-03-12' and '2023-01-01') and (o.order_id > 600))  (cost=99690 rows=55310) (actual time=0.024..26.3 rows=5591 loops=1)
                                -> Index range scan on o using PRIMARY over (600 < order_id)  (cost=99690 rows=497840) (actual time=0.0176..12.4 rows=15508 loops=1)
-> Select #4 (subquery in projection; run only once)
    -> Aggregate: min(cte.order_date)  (cost=571e+6..571e+6 rows=1) (actual time=3.71..3.71 rows=1 loops=1)
        -> Table scan on cte  (cost=571e+6..571e+6 rows=15000) (actual time=0.006..2.07 rows=15000 loops=1)
            -> Materialize CTE cte if needed (query plan printed elsewhere)  (cost=571e+6..571e+6 rows=15000) (never executed)
-> Select #6 (subquery in projection; run only once)
    -> Aggregate: max(cte.order_date)  (cost=571e+6..571e+6 rows=1) (actual time=3.19..3.19 rows=1 loops=1)
        -> Table scan on cte  (cost=571e+6..571e+6 rows=15000) (actual time=0.0095..1.8 rows=15000 loops=1)
            -> Materialize CTE cte if needed (query plan printed elsewhere)  (cost=571e+6..571e+6 rows=15000) (never executed)


-- unoptimized query

EXPLAIN ANALYZE
SELECT 
    CONCAT("Total client count: ", (
        SELECT COUNT(o.client_id)
        FROM opt_orders AS o
        JOIN opt_clients AS c ON o.client_id = c.id
        WHERE (o.order_date BETWEEN '2021-03-12' AND '2023-01-01') AND o.order_id > 600
        LIMIT 15000
    )) AS total_client_count,

    CONCAT("Oldest order: ", (
        SELECT MIN(o.order_date)
        FROM opt_orders AS o
        JOIN opt_clients AS c ON o.client_id = c.id
        WHERE (o.order_date BETWEEN '2021-03-12' AND '2023-01-01') AND o.order_id > 600
        LIMIT 15000
    )) AS oldest_order_date,

    CONCAT("Most recent order: ", (
        SELECT MAX(o.order_date)
        FROM opt_orders AS o
        JOIN opt_clients AS c ON o.client_id = c.id
        WHERE (o.order_date BETWEEN '2021-03-12' AND '2023-01-01') AND o.order_id > 600
        LIMIT 15000
    )) AS most_recent_order_date;

-> Rows fetched before execution  (cost=0..0 rows=1) (actual time=200e-6..300e-6 rows=1 loops=1)
-> Select #2 (subquery in projection; run only once)
    -> Limit: 15000 row(s)  (cost=124580 rows=1) (actual time=2846..2846 rows=1 loops=1)
        -> Aggregate: count(o.client_id)  (cost=124580 rows=1) (actual time=2846..2846 rows=1 loops=1)
            -> Nested loop inner join  (cost=119049 rows=55310) (actual time=0.0513..2809 rows=362263 loops=1)
                -> Filter: ((o.order_date between '2021-03-12' and '2023-01-01') and (o.order_id > 600) and (o.client_id is not null))  (cost=99690 rows=55310) (actual time=0.0303..1416 rows=362263 loops=1)
                    -> Index range scan on o using PRIMARY over (600 < order_id)  (cost=99690 rows=497840) (actual time=0.0228..623 rows=999400 loops=1)
                -> Single-row covering index lookup on c using PRIMARY (id=o.client_id)  (cost=0.25 rows=1) (actual time=0.00361..0.00364 rows=1 loops=362263)
-> Select #3 (subquery in projection; run only once)
    -> Limit: 15000 row(s)  (cost=124580 rows=1) (actual time=2706..2706 rows=1 loops=1)
        -> Aggregate: min(o.order_date)  (cost=124580 rows=1) (actual time=2706..2706 rows=1 loops=1)
            -> Nested loop inner join  (cost=119049 rows=55310) (actual time=0.0329..2636 rows=362263 loops=1)
                -> Filter: ((o.order_date between '2021-03-12' and '2023-01-01') and (o.order_id > 600) and (o.client_id is not null))  (cost=99690 rows=55310) (actual time=0.0232..1337 rows=362263 loops=1)
                    -> Index range scan on o using PRIMARY over (600 < order_id)  (cost=99690 rows=497840) (actual time=0.0198..577 rows=999400 loops=1)
                -> Single-row covering index lookup on c using PRIMARY (id=o.client_id)  (cost=0.25 rows=1) (actual time=0.00336..0.00339 rows=1 loops=362263)
-> Select #4 (subquery in projection; run only once)
    -> Limit: 15000 row(s)  (cost=124580 rows=1) (actual time=2687..2687 rows=1 loops=1)
        -> Aggregate: max(o.order_date)  (cost=124580 rows=1) (actual time=2687..2687 rows=1 loops=1)
            -> Nested loop inner join  (cost=119049 rows=55310) (actual time=0.0248..2616 rows=362263 loops=1)
                -> Filter: ((o.order_date between '2021-03-12' and '2023-01-01') and (o.order_id > 600) and (o.client_id is not null))  (cost=99690 rows=55310) (actual time=0.0178..1310 rows=362263 loops=1)
                    -> Index range scan on o using PRIMARY over (600 < order_id)  (cost=99690 rows=497840) (actual time=0.0154..580 rows=999400 loops=1)
                -> Single-row covering index lookup on c using PRIMARY (id=o.client_id)  (cost=0.25 rows=1) (actual time=0.00339..0.00342 rows=1 loops=362263)

