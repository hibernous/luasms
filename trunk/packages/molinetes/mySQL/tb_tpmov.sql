delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `tpdoc` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(20) COLLATE utf8_spanish_ci NOT NULL,
  `code` char(4) COLLATE utf8_spanish_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

