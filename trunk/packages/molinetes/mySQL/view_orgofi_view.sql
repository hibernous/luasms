delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$
-- 
-- 
-- 
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` 
SQL SECURITY DEFINER VIEW `molinetes`.`orgofi_view` AS 
select   `molinetes`.`organismos`.`idorganismo` AS `org_id`
		,`molinetes`.`organismos`.`name` AS `org_name`
		,`molinetes`.`oficinas`.`idoficina` AS `ofi_id`
		,`molinetes`.`oficinas`.`name` AS `ofi_name` 
from (`molinetes`.`oficinas` 
	left join `molinetes`.`organismos` 
	on((`molinetes`.`oficinas`.`idorganismo` = `molinetes`.`organismos`.`idorganismo`))
	)$$
