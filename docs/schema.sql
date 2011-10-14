create table accesslog (
    id        int(10) unsigned NOT NULL auto_increment,
    role      varchar(100)     NOT NULL,
    service   varchar(10)      NOT NULL,
    component varchar(20)      NOT NULL,
    host      varchar(40)      NOT NULL,
    server    varchar(10)      NOT NULL,
    status    varchar(3)       NOT NULL,
    path      varchar(255)     NOT NULL,
    method    varchar(5)       NOT NULL,
    logged_at datetime         NOT NULL,
    count     int(10) unsigned NOT NULL,
    digest    varchar(255)     NOT NULL,
    PRIMARY KEY (id),
    KEY accesslog_threshold_idx (role,logged_at)
) ENGINE=InnoDB;

create table syslog (
    id        int(10) unsigned    NOT NULL auto_increment,
    role      varchar(100)        NOT NULL,
    service   varchar(10)         NOT NULL,
    component varchar(20)         NOT NULL,
    server    varchar(10)         NOT NULL,
    digest    varchar(255)        NOT NULL,
    log       text                NOT NULL,
    logged_on date                NOT NULL,
    notifyed  tinyint(4) unsigned NOT NULL,
    PRIMARY KEY (id),
    KEY syslog_dup_check_idx (role,service,component,server,digest,notifyed),
    KEY syslog_notify_idx (role, notifyed)
) ENGINE=InnoDB;

create table mysqlquery_threshold (
    id        int(10) unsigned  NOT NULL auto_increment,
    server    varchar(10)      NOT NULL,
    log       varchar(255)     NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

create table deploy_log (
    id        int(10) unsigned  NOT NULL auto_increment,
    service   varchar(10)       NOT NULL,
    component varchar(20)       NOT NULL,
    started_at int(10) unsigned, 
    ended_at   int(10) unsigned,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

