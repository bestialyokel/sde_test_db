
drop table if exists results;

create table results (
    id int,
    response text
);

-- 1
with book_person_count_cte as (
    select b.book_ref, count(*) as person_count 
        from tickets t, bookings b 
        where t.book_ref = b.book_ref 
        group by b.book_ref
)
insert into results(id, response)
select 1, max(person_count) from book_person_count_cte;
-- 1

-- 2
with book_person_count_cte as (
    select b.book_ref, count(*) as person_count 
        from tickets t, bookings b 
        where t.book_ref = b.book_ref 
        group by b.book_ref
)
insert into results(id, response)
select 2, count(*) from book_person_count_cte where person_count > (select avg(person_count) from book_person_count_cte);
-- 2

-- 3
with book_person_count_cte as (
    select b.book_ref, count(*) as person_count 
        from tickets t, bookings b 
        where t.book_ref = b.book_ref 
        group by b.book_ref
), max_passenger_bookings as (
    select * from book_person_count_cte
        where person_count = (select max(person_count) from book_person_count_cte)
),
max_passenger_bookings_tickets as (
    select t.* from tickets t, max_passenger_bookings b where b.book_ref = t.book_ref
)
insert into results(id, response)
select 3, count(*) from max_passenger_bookings b1, max_passenger_bookings b2
where b1.book_ref != b2.book_ref
and NOT EXISTS (
    (
        select t.passenger_id from max_passenger_bookings_tickets t
            where t.book_ref = b1.book_ref 
        EXCEPT 
        select t.passenger_id from max_passenger_bookings_tickets t
            where t.book_ref = b2.book_ref
    ) 
    UNION ALL
    (
        select t.passenger_id from max_passenger_bookings_tickets t
            where t.book_ref = b2.book_ref
        EXCEPT 
        select t.passenger_id from max_passenger_bookings_tickets t
            where t.book_ref = b1.book_ref
    )
);
-- 3

-- 4
with book_person_count_cte as (
    select b.book_ref, count(*) as person_count 
        from tickets t, bookings b 
        where t.book_ref = b.book_ref 
        group by b.book_ref
)
insert into results(id, response)
select 4, 
t.book_ref || '|' || t.passenger_id || '|' || t.passenger_name || '|' || t.contact_data
from tickets t, book_person_count_cte b
where t.book_ref = b.book_ref and b.person_count = 3
order by t.book_ref, t.passenger_id, t.passenger_name, t.contact_data;
-- 4

-- 5
insert into results(id, response)
select 5, max(flights_count) from (
    select b.book_ref, count(*) as flights_count from
        bookings b,
        tickets t,
        ticket_flights tf,
        flights f
    where b.book_ref = t.book_ref 
        and t.ticket_no = tf.ticket_no
        and tf.flight_id = f.flight_id
    group by b.book_ref
) x;
-- 5

-- 6
insert into results(id, response)
select 6, max(flights_count) from (
    select b.book_ref, count(*) as flights_count from
        bookings b,
        tickets t,
        ticket_flights tf,
        flights f
    where b.book_ref = t.book_ref 
        and t.ticket_no = tf.ticket_no
        and tf.flight_id = f.flight_id
    group by b.book_ref, t.passenger_id
) x;
-- 6

-- 7
insert into results(id, response)
select 7, max(flights_count) from (
    select count(*) as flights_count from
        tickets t,
        ticket_flights tf,
        flights f
    where t.ticket_no = tf.ticket_no
        and tf.flight_id = f.flight_id
    group by t.passenger_id
) x;
-- 7


-- 8
with passenger_total_spent as (
    select t.passenger_id, sum(tf.amount) as total_spent from tickets t, ticket_flights tf
        where t.ticket_no = tf.ticket_no
        group by t.passenger_id
),
passengers as (
    select distinct on (passenger_id)
        passenger_id,
        passenger_name,
        contact_data
    from tickets
)
insert into results(id, response)
select 8, 
p.passenger_id || '|' || p.passenger_name || '|' || p.contact_data || '|' total_spent
from passengers p, passenger_total_spent pts 
where p.passenger_id = pts.passenger_id
and pts.total_spent = (select min(total_spent) from passenger_total_spent)
order by p.passenger_id, p.passenger_name, p.contact_data, total_spent;
-- 8

-- 9
with passengers as (
    select distinct on (passenger_id)
        passenger_id,
        passenger_name,
        contact_data
    from tickets
),
flights_duration as (
    select 
    f.flight_id,
    f.status,
    case
        when f.status = 'Arrived' then extract(epoch from (f.actual_arrival - f.actual_departure))
        when f.status = 'Departed' then extract(epoch from (bookings.now() - f.actual_departure))
        else 0
    end as flight_duration
    from flights f
),
passenger_flights_duration as (
    select 
    t.passenger_id,
    sum(fd.flight_duration) as flights_duration_sum
    from tickets t, ticket_flights tf, flights f, flights_duration fd
    where t.ticket_no = tf.ticket_no
    and tf.flight_id = f.flight_id
    and fd.flight_id = f.flight_id
    group by t.passenger_id
)
insert into results(id, response)
select 9,
p.passenger_id || '|' || p.passenger_name || '|' || p.contact_data || '|' || pfd.flights_duration_sum
from passenger_flights_duration pfd, passengers p
where p.passenger_id = pfd.passenger_id
and pfd.flights_duration_sum = (select max(flights_duration_sum) from passenger_flights_duration)
order by p.passenger_id, p.passenger_name, p.contact_data, pfd.flights_duration_sum;
-- 9


-- 10
insert into results(id, response)
select 10, city
from airports a1
group by city
having count(*) > 1
order by city;
-- 10

-- 11
with cities_directions as (
    select
    a1.city as lft_city, a2.city as rgt_city
    from (
        select
        f.departure_airport, f.arrival_airport
        from flights f
        union all
        select
        f.arrival_airport, f.departure_airport
        from flights f
    ) x, airports a1, airports a2
    where arrival_airport != departure_airport
    and a1.airport_code = departure_airport and a2.airport_code = arrival_airport
    group by a1.city, a2.city
),
citites_directions_count as (
    select lft_city, count(*) as cnt from cities_directions fd 
    group by lft_city
)
insert into results(id, response)
select 11, lft_city from citites_directions_count cdc
where cnt = (select min(cnt) from citites_directions_count)
order by lft_city;
-- 11

-- 12
with cities as (
    select city from airports
    group by city
),
cities_directions as (
    select
    a1.city as lft_city, a2.city as rgt_city
    from (
        select
        f.departure_airport, f.arrival_airport
        from flights f
        union all
        select
        f.arrival_airport, f.departure_airport
        from flights f
    ) x, airports a1, airports a2
    where arrival_airport != departure_airport
    and a1.airport_code = departure_airport and a2.airport_code = arrival_airport
    group by a1.city, a2.city
)
insert into results(id, response)
select 12, lft || '|' || rgt from (
    select distinct
    least    (lft_city, rgt_city) as lft,
    greatest (lft_city, rgt_city) as rgt
    from (
        select 
        c1.city as lft_city,
        c2.city as rgt_city 
        from cities c1, cities c2 
        where c1.city != c2.city
        except
        (
        select lft_city, rgt_city from cities_directions
        union
        select rgt_city, lft_city from cities_directions
        )
    ) as x
) y
order by lft, rgt;
-- 12

-- 13
with cities as (
    select city from airports
    group by city
),
cities_directions as (
    select
    a1.city as lft_city, a2.city as rgt_city
    from (
        select
        f.departure_airport, f.arrival_airport
        from flights f
        union all
        select
        f.arrival_airport, f.departure_airport
        from flights f
    ) x, airports a1, airports a2
    where a1.airport_code = departure_airport and a2.airport_code = arrival_airport
    group by a1.city, a2.city
)
insert into results(id, response)
select 13, city from (
    select c2.city from cities c1, cities c2
    where c1.city = 'Москва'
    except
    select rgt_city from cities_directions where lft_city = 'Москва'
) x
order by city;
-- 13

-- 14
with aircraft_flights_completed_cnt as (
    select a.aircraft_code, count(*) as flights_cnt from flights f, aircrafts a
    where f.aircraft_code = a.aircraft_code
    and f.status = 'Arrived'
    group by a.aircraft_code
)
insert into results(id, response)
select 14, a.model from aircrafts a, aircraft_flights_completed_cnt afc
where a.aircraft_code = afc.aircraft_code
and afc.flights_cnt = (select max(flights_cnt) from aircraft_flights_completed_cnt);
-- 14

-- 15
with test as (
    select a.model, count(*) as passenger_cnt from 
        tickets t, 
        ticket_flights tf, 
        flights f, 
        aircrafts a,
        boarding_passes bp
    where t.ticket_no = tf.ticket_no
    and tf.flight_id = f.flight_id
    and f.aircraft_code = a.aircraft_code
    and bp.ticket_no = tf.ticket_no
    and f.status = 'Arrived'
    group by a.model
)
insert into results(id, response)
select 15, model from test
where passenger_cnt = (select max(passenger_cnt) from test);
-- 15

-- 16
with flights_duration as (
    select 
    f.flight_id,
    f.status,
    case
        when f.status = 'Arrived' then extract(epoch from (f.actual_arrival - f.actual_departure))
        when f.status = 'Departed' then extract(epoch from (bookings.now() - f.actual_departure))
        else 0
    end as flight_duration
    from flights f
)
insert into results(id, response)
select 16, (sum(extract(epoch from (f.scheduled_arrival - f.scheduled_departure))) - sum(fd.flight_duration))/60 as diff
from flights f, flights_duration fd
where f.flight_id = fd.flight_id 
and f.status in ('Departed', 'Arrived');
-- 16

-- 17
insert into results(id, response)
select 17, to_city from (
    select a1.city as from_city, a2.city as to_city,
    actual_departure,
    case
        when f.status = 'Arrived' then actual_arrival
        when f.status = 'Departed' then bookings.now()
    end as flight_end_date
    from flights f, airports a1, airports a2
    where f.departure_airport = a1.airport_code
    and f.arrival_airport = a2.airport_code
) x
where from_city = 'Санкт-Петербург'
and '2016-09-13' between actual_departure and flight_end_date
group by from_city, to_city
order by to_city;
-- 17

-- 18
with flights_total_price as (
    select f.flight_id, sum(tf.amount) as sum from flights f, ticket_flights tf, boarding_passes bp
    where f.flight_id = tf.flight_id
    and bp.flight_id = tf.flight_id
    group by f.flight_id
)
insert into results(id, response)
select 18, flight_id from flights_total_price
where sum = (select max(sum) from flights_total_price)
order by flight_id;
-- 18

-- 19
with flights_dow_cnt as (
    select extract(dow from (f.actual_arrival)) as dow, count(*) as cnt from flights f
    where status = 'Arrived'
    group by extract(dow from (f.actual_arrival))
)
insert into results(id, response)
select 19, dow from flights_dow_cnt 
where cnt = (select min(cnt) from flights_dow_cnt)
order by dow;
-- 19

-- 20
insert into results(id, response)
select 20, COALESCE(avg(flights_cnt), 0) from (
    select
    extract(day from f.actual_departure) as day,
    count(*) as flights_cnt
    from flights f, airports a
    where f.departure_airport = a.airport_code
    and a.city = 'Москва'
    and status in ('Departed', 'Arrived')
    and extract(year from f.actual_departure) = 2016
    and extract(month from f.actual_departure) = 9
    group by extract(day from f.actual_departure)
) x;
-- 20

-- 21
with flights_duration as (
    select 
    f.flight_id,
    f.status,
    case
        when f.status = 'Arrived' then extract(epoch from (f.actual_arrival - f.actual_departure))
        when f.status = 'Departed' then extract(epoch from (bookings.now() - f.actual_departure))
        else 0
    end as flight_duration
    from flights f
)
insert into results(id, response)
select 21, city from (
    select 
    a.city,
    avg(fd.flight_duration) as avg_flight_duration
    from flights f, airports a, flights_duration fd
    where f.departure_airport = a.airport_code
    and fd.flight_id = f.flight_id
    group by a.city
) x
where avg_flight_duration > 3
order by avg_flight_duration DESC
LIMIT 5;
-- 21