delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `ctrls` (
  `idctrl` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(45) COLLATE utf8_spanish_ci DEFAULT NULL,
  `name` varchar(45) COLLATE utf8_spanish_ci DEFAULT NULL,
  `macaddrs` char(17) COLLATE utf8_spanish_ci DEFAULT NULL,
  `ip` varchar(45) COLLATE utf8_spanish_ci DEFAULT NULL,
  `activo` char(1) COLLATE utf8_spanish_ci DEFAULT NULL,
  `tipo` varchar(45) COLLATE utf8_spanish_ci DEFAULT NULL,
  `protocol` varchar(5) COLLATE utf8_spanish_ci DEFAULT NULL,
  `port` varchar(5) COLLATE utf8_spanish_ci DEFAULT NULL,
  PRIMARY KEY (`idctrl`),
  KEY `Name_IDX` (`name`),
  KEY `idIDX` (`id`),
  KEY `macIDX` (`macaddrs`),
  KEY `ipIDX` (`ip`),
  KEY `activoIDX` (`activo`),
  KEY `tipoIDX` (`tipo`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

