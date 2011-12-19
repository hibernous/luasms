delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `personas` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `apellidos` varchar(64) COLLATE utf8_spanish_ci NOT NULL,
  `nombres` varchar(64) COLLATE utf8_spanish_ci NOT NULL,
  `sexo` char(1) COLLATE utf8_spanish_ci NOT NULL,
  `nacio` date NOT NULL,
  `tpdoc` smallint(5) unsigned NOT NULL,
  `nrodoc` varchar(20) COLLATE utf8_spanish_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `Ape_IDX` (`apellidos`),
  KEY `Nom_IDX` (`nombres`),
  KEY `ApeyNom_IDX` (`apellidos`,`nombres`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

