delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$
-- 
-- 
-- 
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER VIEW `molinetes`.`ofimov_view` AS 
select   `molinetes`.`ofi_mov`.`idofi_mov` AS `idofi_mov`
		,`molinetes`.`ofi_mov`.`fecha` AS `fecha`
		,`molinetes`.`ofi_mov`.`tipo` AS `tipo`
		,`molinetes`.`ofi_mov`.`idoficina` AS `idoficina`
		,`molinetes`.`ofi_mov`.`idpersona` AS `idpersona`
		,`molinetes`.`ofi_mov`.`idoperador` AS `idoperador` 
from `molinetes`.`ofi_mov` 
order by `molinetes`.`ofi_mov`.`fecha` desc$$
