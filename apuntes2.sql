-- ==========================
-- 1. PROCEDIMIENTOS COMPLEJOS
-- ==========================

-- Procedimiento para calcular el promedio de salario de los empleados por rango de salario
DELIMITER //
CREATE PROCEDURE PromedioSalarioPorRango (
    IN p_salarioMin DECIMAL(10, 2),
    IN p_salarioMax DECIMAL(10, 2),
    OUT p_promedioSalario DECIMAL(10, 2)
)
BEGIN
    SELECT AVG(salario) INTO p_promedioSalario
    FROM Empleados
    WHERE salario BETWEEN p_salarioMin AND p_salarioMax;
END//
DELIMITER ;

-- Procedimiento para registrar un pedido y sus líneas
DELIMITER //
CREATE PROCEDURE RegistrarPedido (
    IN p_clienteId INT,
    IN p_fecha DATE,
    IN p_lineas JSON
)
BEGIN
    DECLARE pedidoId INT;

    -- Insertar el pedido
    INSERT INTO Pedidos (clienteId, fecha)
    VALUES (p_clienteId, p_fecha);

    -- Obtener el ID del pedido recién insertado
    SET pedidoId = LAST_INSERT_ID();

    -- Recorrer las líneas del pedido y añadirlas
    WHILE JSON_LENGTH(p_lineas) > 0 DO
        INSERT INTO LineasPedido (pedidoId, productoId, cantidad)
        VALUES (
            pedidoId,
            JSON_EXTRACT(p_lineas, '$[0].productoId'),
            JSON_EXTRACT(p_lineas, '$[0].cantidad')
        );
        SET p_lineas = JSON_REMOVE(p_lineas, '$[0]');
    END WHILE;
END//
DELIMITER ;

-- ==========================
-- 2. TRIGGERS AVANZADOS
-- ==========================

-- Trigger para actualizar el promedio de calificaciones de un producto tras una nueva reseña
DELIMITER //
CREATE TRIGGER ActualizarPromedioCalificacion
AFTER INSERT ON Reseñas
FOR EACH ROW
BEGIN
    DECLARE nuevoPromedio DECIMAL(3, 2);

    SELECT AVG(calificacion) INTO nuevoPromedio
    FROM Reseñas
    WHERE productoId = NEW.productoId;

    UPDATE Productos
    SET promedioCalificacion = nuevoPromedio
    WHERE id = NEW.productoId;
END//
DELIMITER ;

-- ==========================
-- 3. FUNCIONES AVANZADAS
-- ==========================

-- Función para obtener la antigüedad promedio de los empleados en años
DELIMITER //
CREATE FUNCTION AntiguedadPromedioEmpleados ()
RETURNS DECIMAL(5, 2)
BEGIN
    RETURN (
        SELECT AVG(YEAR(CURDATE()) - YEAR(fechaContratacion))
        FROM Empleados
    );
END//
DELIMITER ;

-- Función para obtener el producto más vendido
DELIMITER //
CREATE FUNCTION ProductoMasVendido ()
RETURNS VARCHAR(255)
BEGIN
    RETURN (
        SELECT p.nombre
        FROM Productos p
        JOIN LineasPedido lp ON p.id = lp.productoId
        GROUP BY p.id, p.nombre
        ORDER BY SUM(lp.cantidad) DESC
        LIMIT 1
    );
END//
DELIMITER ;

-- ==========================
-- 4. CONSULTAS AVANZADAS
-- ==========================

-- Consulta para obtener la media de cantidad de productos vendidos por pedido
SELECT AVG(cantidadTotal) AS MediaProductosVendidos
FROM (
    SELECT SUM(lp.cantidad) AS cantidadTotal
    FROM LineasPedido lp
    GROUP BY lp.pedidoId
) subquery;

-- Consulta para listar los clientes con el total gastado mayor al promedio
SELECT c.id, c.nombre, SUM(lp.cantidad * p.precio) AS TotalGastado
FROM Clientes c
JOIN Pedidos ped ON c.id = ped.clienteId
JOIN LineasPedido lp ON lp.pedidoId = ped.id
JOIN Productos p ON lp.productoId = p.id
GROUP BY c.id, c.nombre
HAVING TotalGastado > (
    SELECT AVG(TotalGastado)
    FROM (
        SELECT SUM(lp.cantidad * p.precio) AS TotalGastado
        FROM Pedidos ped
        JOIN LineasPedido lp ON lp.pedidoId = ped.id
        JOIN Productos p ON lp.productoId = p.id
        GROUP BY ped.clienteId
    ) subquery
)
ORDER BY TotalGastado DESC;


-- PROCEDIMIENTOS USANDO TRANSACTIONS

-- Procedimiento para registrar un pedido con transacciones
DELIMITER $$
CREATE PROCEDURE RegistrarPedidoConTransaccion (
    IN p_clienteId INT,
    IN p_fecha DATE,
    IN p_lineas JSON
)
BEGIN
    DECLARE pedidoId INT;
    DECLARE error_ocurrio BOOL DEFAULT FALSE;

    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Si ocurre un error, deshacer la transacción
        SET error_ocurrio = TRUE;
        ROLLBACK;
    END;

    -- Iniciar la transacción
    START TRANSACTION;

    -- Insertar el pedido
    INSERT INTO Pedidos (clienteId, fecha)
    VALUES (p_clienteId, p_fecha);

    -- Obtener el ID del pedido recién insertado
    SET pedidoId = LAST_INSERT_ID();

    -- Recorrer las líneas del pedido y añadirlas
    WHILE JSON_LENGTH(p_lineas) > 0 DO
        INSERT INTO LineasPedido (pedidoId, productoId, cantidad)
        VALUES (
            pedidoId,
            JSON_EXTRACT(p_lineas, '$[0].productoId'),
            JSON_EXTRACT(p_lineas, '$[0].cantidad')
        );
        
        -- Actualizar el stock del producto correspondiente
        UPDATE Productos
        SET stock = stock - JSON_EXTRACT(p_lineas, '$[0].cantidad')
        WHERE id = JSON_EXTRACT(p_lineas, '$[0].productoId');
        
        SET p_lineas = JSON_REMOVE(p_lineas, '$[0]');
    END WHILE;

    -- Confirmar la transacción si no hubo errores
    IF NOT error_ocurrio THEN
        COMMIT;
    END IF;
END$$
DELIMITER ;
