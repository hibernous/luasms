delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

-- --------------------------------------------------------------------------------
-- get_organismo(prs_id INT)
-- Note: Obtiene Organismo y Oficina para el id de la persona
-- Parametro de entrada id de la tabla personas
-- SALIDA String con el Nombre del Organismo y la Oficina 
-- --------------------------------------------------------------------------------
CREATE DEFINER=`root`@`localhost` 
FUNCTION `get_prsorgofi`(prs_id INT) 
RETURNS varchar(250)
BEGIN
    DECLARE organismo VARCHAR(250) DEFAULT '';
    SET organismo = (SELECT CONCAT(org_name, " ", ofi_name) AS lugar FROM `molinetes`.`ofi_mov` as ofm 
        left join `molinetes`.`orgofi_view` as ofi
        on (ofm.idoficina=ofi.ofi_id)
        where ofm.idpersona=prs_id 
        order by fecha desc limit 1);
    RETURN organismo;
END
$$
