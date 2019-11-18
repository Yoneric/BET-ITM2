
SELECT USUARIO

select * from usuarios order by ID


SELECT * FROM CUOTAS

SELECT * FROM PARTIDOS

SELECT *  FROM EQUIPOS

SELECT * FROM CUOTAS  WHERE ID_PARTIDO = 31

DELETE FROM CUOTAS

SELECT * FROM CATEGORIAS

SELECT * FROM PARTIDOS

SELECT * FROM APUESTAS 

SELECT * FROM CUOTAS

SELECT * FROM DETALLES_APUESTAS

SELECT * FROM ESTADOS

SELECT *  FROM USUARIOS





-- PUNTO 1 VISTAS

/* A.  Sumar el valor ganado de todas las apuestas de los usuarios que están en estado ganado de aquellos partidos asociados a las apuestas que se efectuaron en el trancurso de la semana y mostrarlas ordenadas por el valor más alto; El nombre de la vista será "GANADORES_SEMANALES" y tendrá dos columnas: nombre completo y valor acumulado.

Considerar el siguiente query select trunc(sysdate, 'DAY') start_of_the_week, trunc(sysdate, 'DAY')+6 end_of_the_week from dual;*/


CREATE VIEW GANADORES_SEMANALES AS
SELECT us.primer_nombre ||' ' ||US.SEGUNDO_NOMBRE||' ' ||us.primer_apellido ||' '|| US.SEGUNDO_APELLIDO  "NOMBRE COMPLETO", sum(ap.total_ganancias)"TOTAL GANANCIAS" 
FROM usuarios us INNER JOIN apuestas ap
ON ap.id_usuario = us.id
WHERE AP.FECHA BETWEEN (SELECT trunc(sysdate, 'DAY') FROM DUAL) AND (SELECT trunc(sysdate, 'DAY')+6 FROM dual)
GROUP BY us.primer_nombre,SEGUNDO_NOMBRE, us.primer_apellido,SEGUNDO_APELLIDO;

SELECT * FROM GANADORES_SEMANALES


/* B  Nombre de la vista: DETALLES_APUESTAS. Esta vista deberá mostrar todos los detalles de apuestas simples que se 
efectuaron para un boleto en particular, tal como se muestra en el siguiente ejemplo: */

CREATE OR REPLACE VIEW DETALLE_APUESTAS AS 
SELECT  E.EQUIPO ||' VS '|| E2.EQUIPO "PARTIDO", DAP.OPCION_CUOTA, C.CUOTA_GANADORA,CA.NOMBRE "CATEGORÍA"
FROM   PARTIDOS P  
INNER JOIN  EQUIPOS E  
ON E.ID = P.ID_LOCAL 
INNER JOIN EQUIPOS E2 
ON E2.ID = P.ID_VISITANTE 
INNER JOIN CUOTAS C
ON P.ID = C.ID_PARTIDO 
INNER JOIN CATEGORIAS CA
ON CA.ID = C.ID_CATEGORIA
INNER JOIN DETALLES_APUESTAS DAP
ON C.ID = DAP.ID_CUOTA
INNER JOIN APUESTAS AP
ON AP.ID = DAP.ID_APUESTA
WHERE AP.ID = 1001;

SELECT * FROM DETALLE_APUESTAS


/* C  Nombre de la vista: RESUMEN_APUESTAS. Esta vista mostrará el resumen de cada apuesta efectuada en el sistema, 
la información de la siguiente imagen corresponderá a cada columna (Omitir la siguiente columna Pago máx. incl. 5% bono 
(293.517,58 $)). La idea es que cuando se llame la vista, muestre la información únicamente de esa apuesta en particular: 
SELECT * FROM RESUMEN_APUESTAS WHERE APUESTAS.ID = 123. */

SELECT COUNT(*) "NÚMERO DE APUESTAS",COUNT(*)||'x' || SUM(DAP.VALOR_APOSTADO) "VALOR TOTAL APUESTA"
FROM  DETALLES_APUESTAS DAP
INNER JOIN APUESTAS AP
ON AP.ID = DAP.ID_APUESTA
WHERE AP.ID = 1001

