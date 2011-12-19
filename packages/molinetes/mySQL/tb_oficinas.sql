delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `oficinas` (
  `idoficina` int(10) unsigned NOT NULL,
  `idorganismo` int(10) unsigned DEFAULT NULL,
  `name` varchar(256) COLLATE utf8_spanish_ci DEFAULT NULL,
  `sigla` varchar(32) COLLATE utf8_spanish_ci DEFAULT NULL,
  `code` int(11) DEFAULT NULL,
  PRIMARY KEY (`idoficina`),
  KEY `sigla_IDX` (`sigla`),
  KEY `Name_IDX` (`name`),
  KEY `Org_IDX` (`idorganismo`),
  KEY `OrgOf_IDX` (`idorganismo`,`idoficina`),
  KEY `Org_Name` (`idorganismo`,`name`),
  KEY `OrgSigla` (`idorganismo`,`sigla`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

