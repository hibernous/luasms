delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$
-- 
-- 
-- 
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER VIEW `molinetes`.`trj_uso` AS 
select   `molinetes`.`registros`.`tarjeta` AS `tarjeta`
		,`molinetes`.`registros`.`persona` AS `persona`
		,count(0) AS `usos`
		,min(`molinetes`.`registros`.`fecha`) AS `firstuse`
		,max(`molinetes`.`registros`.`fecha`) AS `lastuse` 
from `molinetes`.`registros` 
group by `molinetes`.`registros`.`tarjeta`,`molinetes`.`registros`.`persona`$$
