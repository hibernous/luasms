delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `registros` (
  `idregistros` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fecha` datetime DEFAULT NULL,
  `operator` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'es el Id del Operador del controlador si es una PC, para los dspositivos como los molinetes y aquellos automatizados el Id es 0, que es el Id del Sistema',
  `controler` int(10) unsigned DEFAULT NULL COMMENT 'Aca va el Id del controlador, los controladores pueden ser Molinetes, PC, etc.',
  `tpmov` varchar(1) COLLATE utf8_spanish_ci DEFAULT NULL COMMENT 'este campo indca si (E)ntra, (S)ale, (P)resencia\n\n(E)ntra cuando entra al edificio\n(P)resencia cuando es detectada presencia por un sensor de presencia\n(S)ale cuando sale del edificio\n',
  `tarjeta` int(10) unsigned DEFAULT NULL COMMENT 'Nro de la tarjeta que se uso, si es un registro hecho por un Operador desde una PC queda en blanco',
  `persona` int(10) unsigned DEFAULT NULL COMMENT 'El Id de la persona que pasa',
  PRIMARY KEY (`idregistros`),
  KEY `Fch_IDX` (`fecha`),
  KEY `Ctrl_IDX` (`controler`),
  KEY `TrjId_IDX` (`tarjeta`),
  KEY `PerId_IDX` (`persona`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

