-- Везде pt = parent type, pid = parent_id
-- Надо ли трэкать источники получения данных?

-- This is to enable geometry type
create extension postgis;

drop table if exists vehicle;
drop table if exists job;
drop table if exists property;
drop table if exists organization;
drop table if exists relation;
drop table if exists social_network;
drop table if exists phone;
drop table if exists email;
drop table if exists person_media;
drop table if exists media;
drop table if exists person_incident;
drop table if exists incident;
drop table if exists address;
drop table if exists person;
drop table if exists source;
-- Upload related
drop table if exists upload;
drop table if exists file;

drop type if exists vehicle_type;

drop function if exists update_timestamp_column;

create type vehicle_type as enum (
    'Car',
    'Motorcycle',
    'Truck',
    'Boat'
);

-- Предполагаю, что объект может иметь несколько источников (например в результате кластеризации).
-- В свою очередь источник может быть источником для нескольких объектов. Поэтому связывать предполагаю через links
create table source(
    id bigserial primary key,
    src text not null,
    check (length(src) <= 2048)
);

create table person(
    id bigserial primary key,
    -- Полное имя, если не структурировано четко в ФИО
    full_name varchar(255),
    -- Фамилия
    last_name varchar(100),
    -- Имя или первая буква
    first_name varchar(100),
    -- Отчество или первая буква
    middle_name varchar(100),
    gender varchar(30),
    birth_date date,
    -- город, деревня и тд
    origin_place varchar(255),
    -- город, где человек был последний раз замечен
    last_known_location varchar(255),
    identity_number varchar(32),
    -- номер с серией, например AB123456
    passport_number varchar(50),
    passport_issue_date date,
    passport_issue_place varchar(255),
    -- военное, милицейское и др звание.
    rank varchar(100),
    source_id bigint references source(id),
    notes text,

    check (length(notes) <= 4096)
);

create table address(
    id bigserial primary key,
    country varchar(2),
    city varchar(100),
    -- область
    region varchar(100),
    -- Район
    district varchar(100),
    -- street address - улица, дом, квартира.
    street varchar(100),
    building varchar(100),
    block varchar(100),
    appartment varchar(10),

    from_date date,
    -- Если актуальный адрес, то to_date=null
    to_date date,

    -- Владелец или постоялец. Надо, чтобы прилинковать местонахождение или владение.
    owner_id bigint references person(id),

    -- геолокация
    position geometry(Point, 4326),
    -- радиус для неточных позиций
    radius real,
    -- spatial index(position),
    source_id bigint references source(id),
    notes text,

    check (length(notes) <= 4096)
);

create table property(
    id bigserial primary key,
    type varchar(50) not null,
    address_id bigint references address(id),
    source_id bigint references source(id),
    notes text,

    check (length(notes) <= 4096)
);

create table vehicle(
    id bigserial primary key,

    type vehicle_type,
    brand varchar(100),
    model varchar(100),
    license_plate varchar(10),
    color varchar(50),

    from_date date,
    -- Если по-прежнему используется, то to_date=null
    to_date date,

    production_year smallint,
    registration_year smallint,

    vin varchar(50),

    person_id bigint references person(id),
    owner_id bigint references person(id),
    source_id bigint references source(id),

    notes text,

    check (length(notes) <= 4096)
);

-- Предприятия. Для военных - часть или другое подразделение. Надо ли иерархия?
create table organization(
    id bigserial primary key,
    name varchar(255) not null,
    division varchar(255),
    address_id bigint references address(id),
    source_id bigint references source(id),
    notes text,

    check (length(notes) <= 4096)
);

-- Таблица должностей. Также включает владение предприятием или долей.
create table job(
    id bigserial primary key,
    employee_id bigint not null references person(id),
    employer_id bigint references organization(id),
    -- должность
    position varchar(255),
    -- TODO: даты, похоже, должны иметь погрешность. Например точная дата, год/месяц или только год.
    from_date date,
    to_date date,
    source_id bigint references source(id),
    notes text,

    check (length(notes) <= 4096)
);

create table relation(
    id bigserial primary key,
    type varchar(50),
    from_person_id bigint not null references person(id),
    to_person_id bigint not null references person(id),
    from_date date,
    -- Если по-прежнему в силе, то to_date=null
    to_date date,
    source_id bigint references source(id)
);

-- 1 person to N social
create table social_network(
    id bigserial primary key,
    owner_id bigint references person(id),
    url text,
    -- vk, fb, ok ...
    net_name varchar(50) not null,
    -- id внутри сети, обычно часть url
    netid varchar(255) not null,
    source_id bigint references source(id),

    check (length(url) <= 2048)
);

-- Впринципе Привязка может осуществляеться связыванием через links.
-- Телефоны можно привязывать к person, address, job,
create table phone(
    id bigserial primary key,
    -- pt tinyint,
    -- pid bigint,
    number varchar(255) not null,
    normalized varchar(255),
    carrier varchar(100),
    owner_id bigint references person(id),

    from_date date,
    -- Если по-прежнему в силе, то to_date=null
    to_date date,

    source_id bigint references source(id)
);

-- Привязка, как в телефонах, но пока с помощью fk
create table email(
    id bigserial primary key,
    -- pt tinyint,
    -- Parent id
    -- pid int,
    email varchar(254) not null,
    owner_id bigint references person(id),

    from_date date,
    -- Если по-прежнему в силе, то to_date=null
    to_date date,

    source_id bigint references source(id)
);

-- С медиа я не определился. Надо смотреть на источники, откуда будем собирать данные
-- Варианты:
-- 1. Привязать как ресурс к Person, Event ...
-- 2. Использовать в Person, Event html в описании.
create table media(
    id bigserial primary key,
    -- pt tinyint,
    -- pid int,
    type varchar(50) not null,
    description varchar(1024),
    hash varchar(255),
    file_name varchar(100),
    url varchar(1024),
    -- Откуда мы этот файл взяли
    original_url varchar(1024),
    timestamp timestamp,
    owner_id bigint references person(id),
    source_id bigint references source(id),

    notes text,

    check (length(notes) <= 4096)
);

create table person_media(
    person_id bigint not null references person(id),
    media_id bigint not null references media(id),
    source_id bigint references source(id)
);

create table incident(
    id bigserial primary key,
    -- pt tinyint,
    -- pid int,
    type varchar(50) not null,
    name varchar(255),
    description text,
    from_time timestamp,
    to_time timestamp,
    time_precision real,
    position geometry(Point, 4326),

    source_id bigint references source(id),

    notes text,

    check (length(description) <= 4096),
    check (length(notes) <= 4096)
);

create table person_incident(
    person_id bigint not null references person(id),
    incident_id bigint not null references incident(id),
    source_id bigint references source(id),
);

create table post(
    id bigserial primary key,
    -- false by default
    finished boolean not null,

    created timestamp not null default now(),
    updated timestamp
);

create table file(
    id bigserial primary key,
    sha256 bytea not null,
    filesize bigint not null,
    mime_type varchar(256),
    extension varchar(256),
    post_id bigint not null references post(id),

    created timestamp not null default now(),
    updated timestamp,

    unique(sha256, filesize)
);

---- Ссылки надо делать двунаправленными, чтобы разрешить обход графа в обе стороны
---- Сейчас связями связаны:
---- Person и Address
---- Event и anyof(Person, Address, Phone,
---- Person -> Person, родственные связи. name - тип связи (жена, муж, ...).
--create table links(
--    id int not null auto_increment primary key,
--    t1 tinyint not null,
--    obj1 int not null,
--    t2 tinyint not null,
--    obj2 int not null,
--    name varchar(255),
--    descr varchar(4096)
--);
--
---- Таг метки на произвольные объекты
--create table tags(
--    id int not null auto_increment primary key,
--    pt tinyint,
--    pid int,
--    tag varchar(255)
--);


create or replace function update_timestamp_column()
returns trigger as $$
begin
   new.updated = now();
   return new;
end;
$$ language 'plpgsql';

-- Update 'updated' timestamps
do
$$
declare
  rec record;
begin
    for rec in
    select table_name
        from information_schema.columns
        where table_schema='public' and column_name='updated'
    loop
        execute format(
            'drop trigger if exists %I on %I; ' ||
            'create trigger %I before update ' ||
            'on %I for each row execute procedure ' ||
            'update_timestamp_column()',
            'update_modtime_' || rec.table_name, rec.table_name,
            'update_modtime_' || rec.table_name, rec.table_name);
    end loop;
end
$$;
