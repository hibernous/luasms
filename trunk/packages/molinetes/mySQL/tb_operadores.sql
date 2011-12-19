delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `operadores` (
  `idoperador` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `logname` varchar(32) COLLATE utf8_spanish_ci DEFAULT NULL,
  `password` varchar(16) COLLATE utf8_spanish_ci DEFAULT NULL,
  `idpersona` int(10) unsigned DEFAULT NULL,
  `funciones` char(1) COLLATE utf8_spanish_ci DEFAULT NULL,
  PRIMARY KEY (`idoperador`),
  KEY `Log_IDX` (`logname`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

INSERT INTO operadores (idoperator,logname,password,idpersona,funciones) 
VALUES (
 ('1','SYSTEM',NULL,NULL,NULL)
,('2','admin','admin','','','')
)$$