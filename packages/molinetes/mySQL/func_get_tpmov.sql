delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

-- --------------------------------------------------------------------------------
-- get_tpmov`(tpmov INT) 
-- Note: Devuelve el string de tipo de moviemiento en Molinetes MACRONE
-- PARAM_IN: tipo de movimiento en table de registraciones
-- SALIDA: String con el Nombre del Movimiento
-- --------------------------------------------------------------------------------
CREATE DEFINER=`root`@`localhost` 
FUNCTION `get_tpmov`(tpmov INT) 
RETURNS varchar(20)
BEGIN
    DECLARE strmov VARCHAR(20) DEFAULT '';
    CASE tpmov
        WHEN 0 THEN SET strmov = "ENTRA";
        WHEN 1 THEN SET strmov = "SALE";
        WHEN 2 THEN SET strmov = "SALE-BUZON";
        WHEN 3 THEN SET strmov = "3 ????";
        WHEN 4 THEN SET strmov = "NO ENTRA";
        WHEN 5 THEN SET strmov = "NO SALE";
        WHEN 6 THEN SET strmov = "NO SALE-BUZON";
        ELSE
            SET strmov = CONCAT(tpmov, " ?????");
    END CASE;
    RETURN strmov;
END
$$
