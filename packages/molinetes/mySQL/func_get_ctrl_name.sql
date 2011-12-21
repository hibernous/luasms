delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

-- --------------------------------------------------------------------------------
-- get_ctrl_name(ctrlid VARCHAR(45)) 
-- Note: Obtiene Descripcion del Controlador a partir del Id del Mismo
-- PARAM_IN: ctrlid un id de controlador
-- SALIDA: Descripcion del controlador
-- --------------------------------------------------------------------------------
CREATE FUNCTION `molinetes`.`get_ctrl_name`(ctrlid VARCHAR(45)) 
RETURNS varchar(45)
BEGIN
    DECLARE strname VARCHAR(45) DEFAULT '';
    SET strname = (SELECT name from ctrls where id=ctrlid);
    RETURN strname;
END

