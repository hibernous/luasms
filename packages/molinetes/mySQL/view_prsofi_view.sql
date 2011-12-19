delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$
-- 
-- 
-- 
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER VIEW `molinetes`.`prsofi_view` AS 
select   `ofimov_view`.`idofi_mov` AS `idofi_mov`
		,`ofimov_view`.`fecha` AS `fecha`
		,`ofimov_view`.`tipo` AS `tipo`
		,`ofimov_view`.`idoficina` AS `idoficina`
		,`ofimov_view`.`idpersona` AS `idpersona`
		,`ofimov_view`.`idoperador` AS `idoperador` 
from `molinetes`.`ofimov_view` 
group by `ofimov_view`.`idpersona`$$
