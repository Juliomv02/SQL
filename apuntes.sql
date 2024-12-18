-- ==========================
-- 1. PLANTILLAS PARA PROCEDIMIENTOS ALMACENADOS
-- ==========================

-- Plantilla básica para un procedimiento de inserción
DELIMITER //
CREATE PROCEDURE InsertarUsuario (
    IN p_email VARCHAR(255),
    IN p_contraseña VARCHAR(255),
    IN p_nombre VARCHAR(255)
)
BEGIN
    INSERT INTO Usuarios (email, contraseña, nombre)
    VALUES (p_email, p_contraseña, p_nombre);
END//
DELIMITER ;

-- Plantilla para actualizar un registro
DELIMITER //
CREATE PROCEDURE ActualizarSalarioEmpleado (
    IN p_empleadoId INT,
    IN p_nuevoSalario DECIMAL(10, 2)
)
BEGIN
    UPDATE Empleados
    SET salario = p_nuevoSalario
    WHERE id = p_empleadoId;
END//
DELIMITER ;


-- Procedimiento para mover stock de un producto a otro
DELIMITER $$
CREATE PROCEDURE MoverStock (
    IN p_productoOrigen INT,
    IN p_productoDestino INT,
    IN p_cantidad INT
)
BEGIN
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

    -- Restar la cantidad del producto origen
    UPDATE Productos
    SET stock = stock - p_cantidad
    WHERE id = p_productoOrigen;

    -- Sumar la cantidad al producto destino
    UPDATE Productos
    SET stock = stock + p_cantidad
    WHERE id = p_productoDestino;

    -- Confirmar la transacción si no hubo errores
    IF NOT error_ocurrio THEN
        COMMIT;
    END IF;
END$$
DELIMITER ;



-- ==========================
-- 2. TRIGGERS
-- ==========================

-- Plantilla para un trigger que registre cambios en una tabla
DELIMITER //
CREATE TRIGGER AntesDeInsertarPedido
BEFORE INSERT ON Pedidos
FOR EACH ROW
BEGIN
    INSERT INTO Logs (accion, fecha, descripcion)
    VALUES ('INSERT', NOW(), CONCAT('Pedido insertado con ID: ', NEW.id));
END//
DELIMITER ;

-- Plantilla para un trigger que actualice automáticamente otra tabla
DELIMITER //
CREATE TRIGGER ActualizarStockProducto
AFTER INSERT ON LineasPedido
FOR EACH ROW
BEGIN
    UPDATE Productos
    SET stock = stock - NEW.cantidad
    WHERE id = NEW.productoId;
END//
DELIMITER ;

-- ==========================
-- 3. FUNCIONES
-- ==========================

-- Función para calcular el total de un pedido
DELIMITER //
CREATE FUNCTION CalcularTotalPedido (
    p_pedidoId INT
) RETURNS DECIMAL(10, 2)
BEGIN
    DECLARE total DECIMAL(10, 2);
    SELECT SUM(lp.cantidad * p.precio) INTO total
    FROM LineasPedido lp
    JOIN Productos p ON lp.productoId = p.id
    WHERE lp.pedidoId = p_pedidoId;
    RETURN total;
END//
DELIMITER ;

-- Función para obtener el nombre completo de un cliente
DELIMITER //
CREATE FUNCTION ObtenerNombreCliente (
    p_clienteId INT
) RETURNS VARCHAR(255)
BEGIN
    DECLARE nombreCliente VARCHAR(255);
    SELECT nombre INTO nombreCliente
    FROM Clientes
    WHERE id = p_clienteId;
    RETURN nombreCliente;
END//
DELIMITER ;

-- ==========================
-- 4. CONSULTAS ÚTILES
-- ==========================

-- Consulta para obtener los productos más vendidos
SELECT p.nombre AS Producto, SUM(lp.cantidad) AS TotalVendidos
FROM LineasPedido lp
JOIN Productos p ON lp.productoId = p.id
GROUP BY p.nombre
ORDER BY TotalVendidos DESC;

-- Consulta para listar los pedidos de un cliente específico
SELECT ped.id AS PedidoID, ped.fecha, c.nombre AS Cliente, SUM(lp.cantidad * prod.precio) AS Total
FROM Pedidos ped
JOIN Clientes c ON ped.clienteId = c.id
JOIN LineasPedido lp ON lp.pedidoId = ped.id
JOIN Productos prod ON lp.productoId = prod.id
WHERE c.id = ?
GROUP BY ped.id, c.nombre, ped.fecha
ORDER BY ped.fecha DESC;

-- Consulta para mostrar el stock de productos
SELECT id AS ProductoID, nombre AS Producto, stock
FROM Productos
ORDER BY stock ASC;

-- ==========================
-- 5. BUENAS PRÁCTICAS PARA EL EXAMEN
-- ==========================

-- 1. Siempre define los DELIMITER correctamente antes y después de procedimientos, triggers o funciones.
-- 2. Usa nombres descriptivos para los procedimientos, funciones y triggers.
-- 3. Usa comentarios dentro del código para explicar cada paso.
-- 4. Asegúrate de probar las consultas con diferentes datos antes de implementarlas.
-- 5. No olvides incluir manejo de errores en procedimientos si es necesario (DECLARE EXIT HANDLER).
