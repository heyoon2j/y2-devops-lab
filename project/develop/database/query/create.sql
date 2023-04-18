-- Create Table
-- 자산 테이블
create table custom_assets (
    host_name VARCHAR()
    account 

    
    update_date DATE NOT NULL,
    primary key (host_name)
);


-- 성능 테이블
CREATE TABLE custom_perf (
    host_name VARCHAR() NOT NULL,
    collect_date DATE NOT NULL,
    cpu_avg DOUBLE() NOT NULL,
    cpu_max DOUBLE() NOT NULL,
    mem_avg DOUBLE() NOT NULL,
    mem_max DOUBLE() NOT NULL,
    primary key (host_name, collect_date)
);
