
drop table if exists results;

create table results (
    id int,
    response text
);

-- 1
with book_person_count_cte as (
    select b.book_ref, count(distinct t.passenger_id) as person_count 
        from tickets t, bookings b 
        where t.book_ref = b.book_ref 
        group by b.book_ref
)
insert into results(id, response)
select 1, max(person_count) from book_person_count_cte;
-- 1

-- 2
with book_person_count_cte as (
    select b.book_ref, count(distinct t.passenger_id) as person_count 
        from tickets t, bookings b 
        where t.book_ref = b.book_ref 
        group by b.book_ref
)
insert into results(id, response)
select 2, count(*) from book_person_count_cte where person_count > (select avg(person_count) from book_person_count_cte);
-- 2

-- 3
with book_person_count_cte as (
    select b.book_ref, count(distinct t.passenger_id) as person_count 
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
    select b.book_ref, count(distinct t.passenger_id) as person_count 
        from tickets t, bookings b 
        where t.book_ref = b.book_ref 
        group by b.book_ref
)
insert into results(id, response)
select 4, book_ref || '|' || string_agg(user_data, '|') from (
    select
    t.book_ref,
    t.passenger_id || '|' || t.passenger_name || '|' || t.contact_data as user_data
    from tickets t, book_person_count_cte b
    where t.book_ref = b.book_ref and b.person_count = 3
    order by t.book_ref, t.passenger_id, t.passenger_name, t.contact_data
) x
group by book_ref;
-- 4

-- 5
insert into results(id, response)
select 5, max(flights_count) from (
    select b.book_ref, count(*) as flights_count from
        bookings b,
        tickets t,
        ticket_flights tf
    where b.book_ref = t.book_ref 
        and t.ticket_no = tf.ticket_no
    group by b.book_ref
) x;
-- 5

-- 6
insert into results(id, response)
select 6, max(flights_count) from (
    select b.book_ref, count(*) as flights_count from
        bookings b,
        tickets t,
        ticket_flights tf
    where b.book_ref = t.book_ref 
        and t.ticket_no = tf.ticket_no
    group by b.book_ref, t.passenger_id
) x;
-- 6

-- 7
insert into results(id, response)
select 7, max(flights_count) from (
    select count(*) as flights_count from
        tickets t,
        ticket_flights tf
    where t.ticket_no = tf.ticket_no
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
passenger_flights_duration as (
    select 
    t.passenger_id,
    sum(f.actual_duration) as flights_duration_sum
    from tickets t, ticket_flights tf, flights_v f
    where t.ticket_no = tf.ticket_no
    and tf.flight_id = f.flight_id
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
with citites_directions_count as (
    select arrival_city, count(*) as cnt from (
        select departure_city, arrival_city from routes r 
        group by departure_city, arrival_city
    ) x
    group by arrival_city
)
insert into results(id, response)
select 11, arrival_city from citites_directions_count cdc
where cnt = (select min(cnt) from citites_directions_count)
order by arrival_city;
-- 11

-- 12
with cities as (
    select city from airports
    group by city
)
insert into results(id, response)
select 12, 
    lft || '|' || rgt from (
    select distinct
    least    (lft_city, rgt_city) as lft,
    greatest (lft_city, rgt_city) as rgt
    from (
        select 
        c1.city as lft_city,
        c2.city as rgt_city 
        from cities c1, cities c2 
        except
        (
        select arrival_city, departure_city from routes group by arrival_city, departure_city
        union
        select departure_city, arrival_city from routes group by departure_city, arrival_city
        )
    ) as x
) y
order by lft, rgt;
-- 12

-- 13
with cities as (
    select city from airports
    group by city
)
insert into results(id, response)
select 13, city from (
    select city from cities
    except
    select arrival_city from routes where departure_city = 'Москва'
    group by arrival_city
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
insert into results(id, response)
select 16, extract(epoch from (sum(f.scheduled_arrival - f.scheduled_departure) - sum(f.actual_duration)))/60 as diff
from flights_v f
where f.status in ('Departed', 'Arrived');
-- 16

-- 17
insert into results(id, response)
select 17, arrival_city from (
    select 
        f.departure_city, 
        f.arrival_city,
        f.actual_departure,
        f.actual_duration
    from flights_v f
) x
where departure_city = 'Санкт-Петербург'
and '2016-09-13' between actual_departure and actual_departure + actual_duration 
group by departure_city, arrival_city
order by arrival_city;
-- 17

-- 18
with flights_total_price as (
    select f.flight_id, sum(tf.amount) as sum from flights f, ticket_flights tf
    where f.flight_id = tf.flight_id
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
    from flights_v f
    where f.departure_city = 'Москва'
    and status in ('Departed', 'Arrived')
    and extract(year from f.actual_departure) = 2016
    and extract(month from f.actual_departure) = 9
    group by extract(day from f.actual_departure)
) x;
-- 20

-- 21
insert into results(id, response)
select 21, departure_city from (
        select departure_city from (
        select 
        departure_city,
        avg(f.actual_duration) as avg_flight_duration
        from flights_v f
        group by departure_city
    ) x
    where extract(epoch FROM avg_flight_duration)/3600 > 3
    order by avg_flight_duration DESC
    limit 5
) x
order by departure_city;
-- 21