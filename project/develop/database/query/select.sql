
-- 월별 자원 현황
select h.name as host_name,
    date_trunc('month', to_timestamp(t.clock)) as collect_date,
    avg(case when i.name = 'CPU Utilization' then t.value_avg end) as cpu_avg,
    min(case when i.name = 'CPU Utilization' then t.value_max end) as cpu_max,
    avg(case when i.name = 'Memory utilization' then t.value_avg end) as mem_avg,
    min(case when i.name = 'Memory utilization' then t.value_max end) as mem_max,
from host h
    inner join items i on i.hostid = h.hostid
    inner join trends t on t.itemid = i.itemid
where h.status = 0
    and h.flags = 0
    and i.name in ('CPU Utilization', 'Memory utilization')
    and t.clock >= extract(epoch from to_timestamp('2023-04-01', 'YYYY-MM-DD'))::integer
    and t.clock < extract(epoch from to_timestamp('2023-04-16', 'YYYY-MM-DD'))::integer
group by h.name as host_name, date_trunc('month', to_timestamp(t.clock))
;


-- 일별 자원 현황 (주말 체크)

select h.name as host_name,
    date_trunc('day', to_timestamp(t.clock)) as collect_date,
    avg(case when i.name = 'CPU Utilization' then t.value_avg end) as cpu_avg,
    min(case when i.name = 'CPU Utilization' then t.value_max end) as cpu_max,
    avg(case when i.name = 'CPU Utilization' and date_part('dow', to_timestamp(t.clock)) in (0, 6) then t.value_avg end) as cpu_weekend,
    avg(case when i.name = 'Memory utilization' then t.value_avg end) as mem_avg,
    min(case when i.name = 'Memory utilization' then t.value_max end) as mem_max,
    avg(case when i.name = 'Memory utilization' and date_part('dow', to_timestamp(t.clock)) in (0, 6) then t.value_avg end) as mem_weekend
from host h
    inner join items i on i.hostid = h.hostid
    inner join trends t on t.itemid = i.itemid
where h.status = 0
    and h.flags = 0
    and i.name in ('CPU Utilization', 'Memory utilization')
    and t.clock = extract(epoch from CURRENT_DATE - 1)::integer
group by h.name as host_name, date_trunc('day', to_timestamp(t.clock))
;



-- 서버 정보 확인
select *
from custom_assets ca
    inner join host h on h. = ca.host_name
--where ca.host_name = ''
;



