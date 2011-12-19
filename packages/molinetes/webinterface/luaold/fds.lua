file = {}
file.operadores = [[
CREATE TABLE `operadores` (
  `idoperador` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `logname` varchar(32) COLLATE utf8_spanish_ci DEFAULT NULL,
  `password` varchar(16) COLLATE utf8_spanish_ci DEFAULT NULL,
  `idpersona` int(10) unsigned DEFAULT NULL,
  `funciones` char(1) COLLATE utf8_spanish_ci DEFAULT NULL,
  PRIMARY KEY (`idoperador`),
  KEY `Log_IDX` (`logname`)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.tpdoc = [[
CREATE TABLE  IF NOT EXISTS `molinetes`.`tpdoc` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(20) NOT NULL,
  `code` char(4) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.organismos = [[
CREATE TABLE `organismos` (
  `idorganismo` int(10) unsigned NOT NULL,
  `name` varchar(256) COLLATE utf8_spanish_ci DEFAULT NULL,
  `code` int(11) DEFAULT NULL,
  PRIMARY KEY (`idorganismo`),
  KEY `Name_IDX` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.oficinas = [[
CREATE TABLE `oficinas` (
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
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

--
--file.prs_oficina = [[
--CREATE TABLE `prs_oficina` (
--  `idpersona` int(10) unsigned NOT NULL,
--  `idoficina` int(10) unsigned DEFAULT NULL,
--  PRIMARY KEY (`idpersona`),
--  KEY `Of_IDX` (`idoficina`),
--  KEY `OfPrs_IDX` (`idoficina`,`idpersona`)
--) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
--]]
--

file.ofi_mov = [[
CREATE TABLE `ofi_mov` (
  `idofi_mov` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NULL DEFAULT NULL,
  `tipo` varchar(16) COLLATE utf8_spanish_ci DEFAULT NULL,
  `idoficina` int(10) unsigned DEFAULT NULL,
  `idpersona` int(10) unsigned DEFAULT NULL,
  `idoperador` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`idofi_mov`),
  KEY `PerFch_IDX` (`idpersona`,`fecha`),
  KEY `OfiFch_IDX` (`idoficina`,`fecha`),
  KEY `PerId_IDX` (`idpersona`,`idofi_mov`),
  KEY `OfiId_IDX` (`idoficina`,`idofi_mov`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.personas = [[
CREATE TABLE `personas` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `old_id` char(36) COLLATE utf8_spanish_ci NOT NULL,
  `apellidos` char(32) COLLATE utf8_spanish_ci NOT NULL,
  `nombres` char(32) COLLATE utf8_spanish_ci NOT NULL,
  `sexo` char(1) COLLATE utf8_spanish_ci NOT NULL,
  `nacio` date NOT NULL,
  `tpdoc` smallint(5) unsigned NOT NULL,
  `nrodoc` char(20) COLLATE utf8_spanish_ci NOT NULL,
  `idoficina` int(10) unsigned DEFAULT NULL,
  `idoperador` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `OldId_IDX` (`old_id`),
  KEY `Ape_IDX` (`apellidos`),
  KEY `Nom_IDX` (`nombres`),
  KEY `Of_IDX` (`idoficina`),
  KEY `ApeyNom_IDX` (`apellidos`,`nombres`)
) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.fotos = [[
CREATE TABLE `fotos` (
  `id` int(10) unsigned NOT NULL,
  `filename` varchar(64) CHARACTER SET utf8 COLLATE utf8_swedish_ci NOT NULL,
  `mimeType` varchar(20) CHARACTER SET utf8 COLLATE utf8_spanish2_ci NOT NULL,
  `alt` varchar(64) CHARACTER SET utf8 COLLATE utf8_spanish2_ci NOT NULL,
  `data` mediumblob NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci

]]

file.prs_mov =[[
CREATE TABLE `prs_mov` (
  `idprs_mov` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `es` char(1) COLLATE utf8_spanish_ci DEFAULT NULL COMMENT 'E - Entra\nS - Sale',
  `tipo` char(1) COLLATE utf8_spanish_ci DEFAULT NULL COMMENT 'S - Systema\nO - Operador\nC - Controlador',
  `idregister` int(10) unsigned DEFAULT NULL,
  `idpersona` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`idprs_mov`),
  KEY `Fch_IDX` (`fecha`),
  KEY `PrsFch` (`idpersona`,`fecha`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.tarjetas = [[
CREATE TABLE `tarjetas` (
  `idtarjeta` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hex` char(8) COLLATE utf8_spanish_ci DEFAULT NULL,
  `pack` char(4) COLLATE utf8_spanish_ci DEFAULT NULL,
  `lecturas` int(10) unsigned DEFAULT '0',
  `created` datetime DEFAULT NULL,
  `last` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `funciones` char(1) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`idtarjeta`),
  KEY `Hex_IDX` (`hex`),
  KEY `Pack_IDX` (`pack`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.trj_mov = [[
CREATE TABLE `trj_mov` (
  `idtrj_mov` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tarjeta` int(10) unsigned DEFAULT NULL,
  `tipo` varchar(10) COLLATE utf8_spanish_ci DEFAULT NULL COMMENT 'ENTREGA de OM/OCG a OM/OCG\nASIGNA de OM a Persona\nDEVUELVE de Persona a OM\nBUZON de Persona a Controlador\nRETIRA de Controlador a OM/OCG\nALMACENA de OM/OCG a Controlador',
  `de` int(10) unsigned DEFAULT NULL,
  `a` int(10) unsigned DEFAULT NULL,
  `funciones` char(1) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`idtrj_mov`),
  KEY `Fch_IDX` (`fecha`),
  KEY `Trj_IDX` (`tarjeta`),
  KEY `TrjFch_IDX` (`tarjeta`,`fecha`),
  KEY `idTrj_IDX` (`idtrj_mov` DESC,`tarjeta`)
) ENGINE=MyISAM AUTO_INCREMENT=491153 DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.ctrls = [[
CREATE TABLE `ctrls` (
  `idctrl` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_spanish_ci DEFAULT NULL,
  `macaddrs` char(17) COLLATE utf8_spanish_ci DEFAULT NULL,
  PRIMARY KEY (`idctrl`),
  KEY `Name_IDX` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

file.ctrls_mov = [[
CREATE TABLE `ctrls_mov` (
  `idctrl_mov` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fecha` datetime DEFAULT NULL,
  `idctrl` int(10) unsigned DEFAULT NULL,
  `sensor` int(10) unsigned DEFAULT NULL,
  `tarjeta` int(10) unsigned DEFAULT NULL,
  `valid` char(1) COLLATE utf8_spanish_ci DEFAULT NULL,
  PRIMARY KEY (`idctrl_mov`),
  KEY `fch_IDX` (`fecha`),
  KEY `TrjFch_IDX` (`tarjeta`,`fecha`),
  KEY `Trj_IDX` (`tarjeta`),
  KEY `FchTrj_IDX` (`fecha`,`tarjeta`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci
]]

function dropTable(str)
	graba(string.format("DROP TABLE IF EXISTS `molinetes`.`%s`",str));
	graba(file[str]);
end

function graba(str)
	print(str)
	res, serror = mol:execute(str)
	if serror then
		print(serror)
		io.stdin:read(1)
	end
end

function find(conn,str)
	local cur, serror = conn:execute(str)
	if serror then 
		print(serror)
		return false
	end
	return cur:numrows()
end