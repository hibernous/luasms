delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$
-- 
-- 
-- 
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER VIEW `molinetes`.`es_view` AS 
select 	 `reg`.`idregistros` AS `id`
		,`reg`.`fecha` AS `fecha`
		,`molinetes`.`get_ctrl_name`(`reg`.`controler`) AS `controler`
		,`molinetes`.`get_tpmov`(`reg`.`tpmov`) AS `tpmov`
		,`reg`.`tarjeta` AS `tarjeta`
		,`reg`.`persona` AS `prsid`
		,`prs`.`apellidos` AS `apellidos`
		,`prs`.`nombres` AS `nombres`
		,`prs`.`sexo` AS `sexo`
		,`molinetes`.`get_organismo`(`reg`.`persona`) AS `lugar` 
from (`molinetes`.`registros` `reg` 
	left join `molinetes`.`personas` `prs` 
	on((`reg`.`persona` = `prs`.`id`))
	)$$

