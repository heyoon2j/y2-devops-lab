-- Create Table
-- 자산 테이블
create table msp_custom_assets (
    "name" varchar(128) not null,
    ip_address varchar(16) null,
    account varchar(128) not null,
    service_type 1
    instance_type varchar(50) not null,
    vcpu int4 not null,
    memory int4 not null,
    volume int4 null,
    update_date date,
    constraint pk_custom_assets primary key (name)
);


-- 성능 테이블
create table msp_custom_perf (
    "name" varchar(128) not null,
    collect_date date not null,
    cpu_avg float8 not null,
    cpu_max float8 not null,
    mem_avg float8 not null,
    mem_max float8 not null,
    constraint msp_cusotom_perf_pk primary key (name, collect_date)
    --constraint fk_custom_perf foreign key (host_name) references custom_assets (host_name)
);


