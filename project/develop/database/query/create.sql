-- Create Table
-- 자산 테이블
create table custom_assets (
    host_name varchar(128) not null,
    ip_address varchar(16) not null,
    account_name varchar(128) not null,
    vcpu int4 not null,
    memory int4 not null,
    volume int4 not null,
    update_date date,
    constraint pk_custom_assets primary key (host_name),
);


-- 성능 테이블
create table custom_perf (
    host_name varchar(128) not null,
    collect_date date not null,
    cpu_avg float8 not null,
    cpu_max float8 not null,
    cpu_weekend float8,
    mem_avg float8 not null,
    mem_max float8 not null,
    mem_weekend float8,
    constraint pk_cusotom_perf primary key (host_name, collect_date)
    --constraint fk_custom_perf foreign key (host_name) references custom_assets (host_name)
);
