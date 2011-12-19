delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `organismos` (
  `idorganismo` int(10) unsigned NOT NULL,
  `name` varchar(256) COLLATE utf8_spanish_ci DEFAULT NULL,
  `code` int(11) DEFAULT NULL,
  PRIMARY KEY (`idorganismo`),
  KEY `Name_IDX` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

