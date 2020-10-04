use bel2020;

-- Везде pt = parent type, pid = parent_id
-- Надо ли трэкать источники получения данных?

create table persons(
    id int not null auto_increment primary key,
    -- Полное имя, если не структурировано четко в ФИО
    name varchar(255),
    -- Фамилия
    last_name varchar(255),
    -- Имя или первая буква
    first_name varchar(255),
    -- Отчество или первая буква
    middle_name varchar(255),
    bday date,
    -- номер с серией, например AB123456
    passport_number varchar(255),
    passport_issue_date date,
    passport_issue_place varchar(255),
    -- город, где человек был последний раз замечен
    last_known_location varchar(255)
);

create table addresses(
    id int not null auto_increment primary key,
    -- street address - улица, дом, квартира.
    -- Не уверен, стоит ли разбивать на более мелкие части: улица, дом, кв
    street varchar(255),
    -- геолокация
    position point srid 4326,
    -- радиус для неточных позиций
    radius float,
    spatial index(position)
);

-- Таблица должностей. Также включает владение предприятием или долей.
create table jobs(
    id int not null auto_increment primary key,
    org_id int,
    -- должность
    position varchar(255),
    -- TODO: даты, похоже, должны иметь погрешность. Например точная дата, год/месяц или только год.
    start_date date,
    end_date date
);

-- Предприятия. Для военных - часть или другое подразделение. Надо ли иерархия?
create table orgs(
    id int not null auto_increment primary key,
    name varchar(255),
    address_id int
);

-- 1 person to N social
create table socials(
    id int not null auto_increment primary key,
    person_id int not null,
    url varchar(255),
    -- vk, fb, ok ...
    net_name varchar(255),
    -- id внутри сети, обычно часть url
    net_id varchar(255)
);

-- Привязка осуществляется связыванием через links.
-- Телефоны можно привязывать к person, address, job,
create table phones(
    id int not null auto_increment primary key,
    pt tinyint,
    pid int,
    number varchar(255),
    normalized varchar(255)
);

-- Привязка, как в телефонах
create table emails(
    id int not null auto_increment primary key,
    pt tinyint,
    -- Parent id
    pid int,
    email varchar(255)
);

-- Происшествия. Можно собирать неидентифицированные происшествия, и потом,
-- по мере добытия информации, связывать с фактами, людьми и т.п.
create table events(
    id int not null auto_increment primary key,
    descr varchar(4096),
    position point srid 4326,
    radius float,
    -- Можно использовать start=end для точечных временных событий
    start_dt datetime,
    end_dt datetime,
    spatial index(position)
);

-- С медиа я не определился. Надо смотреть на источники, откуда будем собирать данные
-- Варианты:
-- 1. Привязать как ресурс к Person, Event ...
-- 2. Использовать в Person, Event html в описании.
create table media(
    id int not null auto_increment primary key,
    pt tinyint,
    pid int,
    descr varchar(1024),
    hash varchar(255),
    -- Откуда мы этот файл взяли
    original_url varchar(1024)
);

-- Предполагаю, что объект может иметь несколько источников (например в результате кластеризации).
-- В свою очередь источник может быть источником для нескольких объектов. Поэтому связывать предполагаю через links
create table sources(
    id int not null auto_increment primary key,
    src varchar(255) not null
);

-- Ссылки надо делать двунаправленными, чтобы разрешить обход графа в обе стороны
-- Сейчас связями связаны:
-- Person и Address
-- Event и anyof(Person, Address, Phone,
-- Person -> Person, родственные связи. name - тип связи (жена, муж, ...).
create table links(
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
);
