-- Везде pt = parent type, pid = parent_id
-- Надо ли трэкать источники получения данных?

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


-- Предполагаю, что объект может иметь несколько источников (например в результате кластеризации).
-- В свою очередь источник может быть источником для нескольких объектов. Поэтому связывать предполагаю через links
create table source(
    id bigserial primary key,
    src varchar(255) not null
);


create table person(
    id bigserial primary key,
    -- Полное имя, если не структурировано четко в ФИО
    name varchar(255),
    -- Фамилия
    last_name varchar(100),
    -- Имя или первая буква
    first_name varchar(100),
    -- Отчество или первая буква
    middle_name varchar(100),
    gender varchar(30),
    birth_date date,
    -- город, деревня и тд
    origin_place varchar(250),
    -- номер с серией, например AB123456
    passport_number varchar(50),
    passport_issue_date date,
    passport_issue_place varchar(255),
    -- город, где человек был последний раз замечен
    last_known_location varchar(255),
    source_id bigint,
    notes varchar(255),
    
    constraint fk_source
        foreign key(source_id)
            references source(id)
);


create table address(
    id bigserial primary key,
    city varchar(100),
    -- область
    region varchar(100),
    -- Район
    county varchar(100),
    -- street address - улица, дом, квартира.
    street varchar(100),
    building varchar(100),
    block varchar(100),
    appartment varchar(10),

    from_date date,
    -- Если актуальный аддресс, то to_date=null
    to_date date,

    owner_id bigint,

    -- геолокация
    position geometry(Point, 4326),
    -- радиус для неточных позиций
    radius real,
    --spatial index(position),
    source_id bigint,
    notes varchar(255),

    constraint fk_owner
        foreign key(owner_id)
            references person(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


create table property(
    id bigserial primary key,
    type varchar(50) not null,
    address_id bigint,
    source_id bigint,

    constraint fk_address
        foreign key(address_id)
            references address(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


create table vehicle(
    id bigserial primary key,
    brand varchar(100),
    model varchar(100),
    licensePlate varchar(10) not null,
    color varchar(50),

    from_date date,
    -- Если по-прежнему используется, то to_date=null
    to_date date,

    productionYear smallint,
    registrationYear smallint,

    vin varchar(50),
    owner_id bigint,
    source_id bigint,
    notes varchar(255),

    constraint fk_owner
        foreign key(owner_id)
        references person(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


-- Предприятия. Для военных - часть или другое подразделение. Надо ли иерархия?
create table organization(
    id bigserial primary key,
    name varchar(255) not null,
    division varchar(255),
    address_id bigint,
    source_id bigint,

    constraint fk_address
        foreign key(address_id)
            references address(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


-- Таблица должностей. Также включает владение предприятием или долей.
create table job(
    id bigserial primary key,
    employee_id bigint not null,
    employer_id bigint,
    -- должность
    position varchar(255),
    -- TODO: даты, похоже, должны иметь погрешность. Например точная дата, год/месяц или только год.
    from_date date,
    to_date date,
    source_id bigint,

    constraint fk_employee
        foreign key(employee_id)
            references person(id),

    constraint fk_employer
        foreign key(employer_id)
            references organization(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


create table relation(
    id bigserial primary key,
    type varchar(50),
    from_person_id bigint not null,
    to_person_id bigint not null,

    from_date date,
    -- Если по-прежнему в силе, то to_date=null
    to_date date,
    source_id bigint,

    constraint fk_from_person_id
        foreign key(from_person_id)
            references person(id),

    constraint fk_to_person_id
        foreign key(to_person_id)
            references person(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


-- 1 person to N social
create table social_network(
    id bigserial primary key,
    owner_id bigint,
    url varchar(255),
    -- vk, fb, ok ...
    net_name varchar(50) not null,
    -- id внутри сети, обычно часть url
    net_id varchar(255) not null,
    source_id bigint,

    constraint fk_owner_id
        foreign key(owner_id)
            references person(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


-- Впринципе Привязка может осуществляеться связыванием через links.
-- Телефоны можно привязывать к person, address, job,
create table phone(
    id bigserial primary key,
    --pt tinyint,
    --pid bigint,
    number varchar(255) not null,
    normalized varchar(255),
    carrier varchar(100),
    owner_id bigint,
    from_date date,
    -- Если по-прежнему в силе, то to_date=null
    to_date date,
    source_id bigint,

    constraint fk_owner_id
        foreign key(owner_id)
            references person(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


-- Привязка, как в телефонах, но пока с помощью fk
create table email(
    id bigserial primary key,
    --pt tinyint,
    -- Parent id
    --pid int,
    email varchar(255) not null,
    owner_id bigint,
    from_date date,
    -- Если по-прежнему в силе, то to_date=null
    to_date date,
    source_id bigint,

    constraint fk_owner_id
        foreign key(owner_id)
            references person(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


-- С медиа я не определился. Надо смотреть на источники, откуда будем собирать данные
-- Варианты:
-- 1. Привязать как ресурс к Person, Event ...
-- 2. Использовать в Person, Event html в описании.
create table media(
    id bigserial primary key,
    --pt tinyint,
    --pid int,
    type varchar(50) not null,
    description varchar(1024),
    hash varchar(255),
    fileName varchar(100),
    url varchar(1024),
    -- Откуда мы этот файл взяли
    original_url varchar(1024),		
    timestamp timestamp,
    owner_id bigint,
    source_id bigint,
    notes varchar(255),

    constraint fk_owner_id
        foreign key(owner_id)
            references person(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


create table person_media(

    person_id bigint not null,
    media_id bigint not null,
    source_id bigint,

    constraint fk_person_id
        foreign key(person_id)
            references person(id),

    constraint fk_media_id
        foreign key(media_id)
            references media(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


create table incident(
    id bigserial primary key,
    --pt tinyint,
    --pid int,
    type varchar(50) not null,
    name varchar(255),
    description varchar(4096),
    from_time timestamp,
    to_time timestamp,
    time_precision real,
    position geometry(Point, 4326),

    source_id bigint,
    notes varchar(1024),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


create table person_incident(

    person_id bigint not null,
    incident_id bigint not null,
    source_id bigint,

    constraint fk_person_id
        foreign key(person_id)
            references person(id),

    constraint fk_incident_id
        foreign key(incident_id)
            references incident(id),

    constraint fk_source
        foreign key(source_id)
            references source(id)
);


-- Ссылки надо делать двунаправленными, чтобы разрешить обход графа в обе стороны
-- Сейчас связями связаны:
-- Person и Address
-- Event и anyof(Person, Address, Phone,
-- Person -> Person, родственные связи. name - тип связи (жена, муж, ...).
/*create table links(
    id int not null auto_increment primary key,
    t1 tinyint not null,
    obj1 int not null,
    t2 tinyint not null,
    obj2 int not null,
    name varchar(255),
    descr varchar(4096)
);

-- Таг метки на произвольные объекты
create table tags(
    id int not null auto_increment primary key,
    pt tinyint,
    pid int,
    tag varchar(255)
);*/
