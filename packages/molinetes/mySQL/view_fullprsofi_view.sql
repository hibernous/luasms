delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$
-- 
-- 
-- 
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER VIEW `molinetes`.`fullprsofi_view` AS 
select   `orgofi_view`.`org_id` AS `org_id`
		,`orgofi_view`.`org_name` AS `org_name`
		,`orgofi_view`.`ofi_id` AS `ofi_id`
		,`orgofi_view`.`ofi_name` AS `ofi_name`
		,`prsofi_view`.`fecha` AS `ofi_fecha`
		,`prsofi_view`.`tipo` AS `estado`
		,`molinetes`.`personas`.`id` AS `prs_id`
		,`molinetes`.`personas`.`tpdoc` AS `prs_tpdoc`
		,`molinetes`.`personas`.`nrodoc` AS `prs_nrodoc`
		,`molinetes`.`personas`.`apellidos` AS `prs_apellidos`
		,`molinetes`.`personas`.`nombres` AS `prs_nombres`
		,`molinetes`.`personas`.`sexo` AS `prs_sexo` 
from ((`molinetes`.`orgofi_view` join `molinetes`.`personas`) 
	left join `molinetes`.`prsofi_view` 
	on(((`prsofi_view`.`idoficina` = `orgofi_view`.`ofi_id`) 
	and (`prsofi_view`.`idpersona` = `molinetes`.`personas`.`id`)
	))
	)$$

