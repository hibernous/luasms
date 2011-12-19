delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `fotos` (
  `id` int(10) unsigned NOT NULL,
  `filename` varchar(64) CHARACTER SET utf8 COLLATE utf8_swedish_ci NOT NULL,
  `mimeType` varchar(20) CHARACTER SET utf8 COLLATE utf8_spanish2_ci NOT NULL,
  `alt` varchar(64) CHARACTER SET utf8 COLLATE utf8_spanish2_ci NOT NULL,
  `data` mediumblob NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

