DROP TABLE `jobs`;

CREATE TABLE `jobs` (
  `job_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `event_name` varchar(96) NOT NULL,
  `card_name` varchar(96) NOT NULL,
  `src_ip` varchar(16) NOT NULL DEFAULT '',
  `src_path` varchar(128) NOT NULL DEFAULT '',
  `dst_path` varchar(128) NOT NULL DEFAULT '',
  `job_type` varchar(16) NOT NULL,
  `job_status` varchar(16) NOT NULL DEFAULT 'new',
  `proc_host` varchar(64) DEFAULT NULL,
  `file_size` int(11) DEFAULT '0',
  `network_time` int(11) DEFAULT '0',
  `encode_time` int(11) DEFAULT '0',
  PRIMARY KEY (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE `config`;

CREATE TABLE `config` (
  `config_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(24) NOT NULL,
  `value` varchar(24) NOT NULL,
  PRIMARY KEY (`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO config (name, value) VALUES ('scp_bw', '10000000');

