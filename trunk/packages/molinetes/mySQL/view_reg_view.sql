delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$
-- 
-- 
-- 
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER VIEW `molinetes`.`reg_view` AS 
select   `reg`.`idregistros` AS `reg_id`
		,`reg`.`fecha` AS `reg_fecha`
		,`reg`.`operator` AS `reg_operador`
		,`reg`.`controler` AS `reg_controler`
		,`reg`.`tpmov` AS `reg_tpmov`
		,`reg`.`tarjeta` AS `reg_tarjeta`
		,`prs`.`id` AS `prs_id`,`prs`.`apellidos` AS `prs_apellidos`
		,`prs`.`nombres` AS `prs_nombres`
		,concat(`prs`.`apellidos`,' ',`prs`.`nombres`) AS `prs_fullname`
		,`prs`.`tpdoc` AS `prs_tpdoc`
		,`prs`.`nrodoc` AS `prs_nrodoc`
		,`prs`.`nacio` AS `prs_nacio`
		,`prs`.`sexo` AS `prs_sexo`
		,`org`.`idorganismo` AS `org_id`
		,`org`.`name` AS `org_name`
		,`ofi`.`idoficina` AS `ofi_id`
		,`ofi`.`name` AS `ofi_name` 
from (
		(
			(
				(`molinetes`.`registros` `reg` 
					left join `molinetes`.`personas` `prs` 
					on((`reg`.`persona` = `prs`.`id`))
				) 
				left join `molinetes`.`ofi_mov` `ofm` 
				on((`reg`.`persona` = `ofm`.`idpersona`))
			) 
			left join `molinetes`.`oficinas` `ofi` 
			on((`ofi`.`idoficina` = `ofm`.`idoficina`))
		) 
		left join `molinetes`.`organismos` `org` 
		on((`ofi`.`idorganismo` = `org`.`idorganismo`))
	)$$
