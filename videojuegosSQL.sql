TABLAS

DROP TABLE if EXISTS  Progresos;
DROP TABLE if EXISTS  Jugadores;
DROP TABLE if EXISTS  Videojuegos;


CREATE TABLE Videojuegos(
	videojuegoId INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
	nombre VARCHAR(80) NOT NULL,
	fechaLanzamiento DATE,
	logros INT,
	estado ENUM('Lanzado', 'Beta', 'Acceso anticipado'),
	precioLanzamiento DOUBLE
);


CREATE TABLE Jugadores(
	jugadorId INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	nickname VARCHAR(60) NOT NULL,
);

DROP TABLE if EXISTS  Valoraciones;
CREATE TABLE Valoraciones(
	valoracionId INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	jugadorId INT NOT NULL, 
	videojuegoId INT NOT NULL,
	fechaValoracion DATE NOT NULL DEFAULT CURDATE(),
	puntuacion DOUBLE NOT NULL CHECK (puntuacion>=0 AND puntuacion <=5),
	numeroLikes INT DEFAULT 0,
	opinion VARCHAR(255) NOT NULL,
	veredicto ENUM ('Imprescindible', 'Recomendado', 'Comprar en rebajas', 'No merece la pena') NOT NULL,
	FOREIGN KEY (jugadorId) REFERENCES Jugadores(jugadorId)
		ON DELETE CASCADE 
		ON UPDATE CASCADE, 
	FOREIGN KEY (videojuegoId) REFERENCES Videojuegos(videojuegoId)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	UNIQUE(jugadorId, videojuegoId)
);

/*
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('The Legend of Zelda: Breath of the Wild', '2017-03-03', 76, 'Lanzado', 69.99);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('The Legend of Zelda: Tears of the Kingdom', '2023-05-12', 139, 'Lanzado', 79.99);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('Maniac Mansion', '1987-01-01', 1, 'Lanzado', 49.98);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('Horizon: Zero Dawn', '2017-02-28', 31, 'Lanzado', 79.99);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('Super Metroid', '1994-04-28', 1, 'Lanzado', 69.99);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('Final Fantasy IX', '2001-02-16', 9, 'Lanzado', 69.99);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('Pokemon Rojo', '1999-11-01', 151, 'Lanzado', 49.98);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('Pokemon Amarillo', '2000-06-16', 155, 'Lanzado', 49.98);
INSERT INTO Videojuegos(nombre, fechaLanzamiento,logros, estado,precioLanzamiento) VALUES ('Pokemon Beige Clarito', '2023-12-15', 3, 'Beta', 2000000);


INSERT INTO Jugadores(nickname) VALUES ('Currito92');
INSERT INTO Jugadores(nickname) VALUES ('MariTrini67');
INSERT INTO Jugadores(nickname) VALUES ('IISSI_USER');
INSERT INTO Jugadores(nickname) VALUES ('Samus');
INSERT INTO Jugadores(nickname) VALUES ('Aran');
*/


PROCEDIMIENTOS

/*
DELIMITER //

CREATE PROCEDURE InsertarValoracion(
    IN p_jugadorId INT,
    IN p_videojuegoId INT,
    IN p_puntuacion DOUBLE,
    IN p_opinion VARCHAR(255),
    IN p_veredicto ENUM('Imprescindible', 'Recomendado', 'Comprar en rebajas', 'No merece la pena')
)

BEGIN

	IF NOT EXISTS(SELECT 1 FROM Jugadores WHERE jugadorId = p_jugadorId) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'El jugador no existe.';
	END IF;
	
	IF NOT EXISTS(SELECT 1 FROM Videojuegos WHERE videojuegoId = p_videojuegoId) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'El videojuego no existe.';
	END IF;
	
	IF p_puntuacion<0 OR p_puntuacion>5 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'La puntuacion debe estar entre 0 y 5.';
	END IF;

	IF p_veredicto NOT IN ('Imprescindible', 'Recomendado', 'Comprar en rebajas', 'No merece la pena') THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'El veredicto no es válido.';
	END IF;
	
	IF EXISTS (SELECT 1 FROM Valoraciones WHERE jugadorId = p_jugadorId AND videojuegoId = p_videojuegoId) THEN
		 SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'El jugador ya ha valorado este videojuego.';
	END IF;
	
	INSERT INTO Valoraciones(jugadorId, videojuegoId,puntuacion,opinion, veredicto)
	VALUES (p_jugadorId,p_videojuegoId,p_puntuacion,p_opinion,p_veredicto);

END; //

DELIMITER ;
*/

DELIMITER //

CREATE PROCEDURE pAddUsuarioValoracion(
    IN p_nickname VARCHAR(60),
    IN p_videojuegoId INT,
    IN p_puntuacion DOUBLE,
    IN p_opinion VARCHAR(255),
    IN p_veredicto ENUM('Imprescindible', 'Recomendado', 'Comprar en rebajas', 'No merece la pena')
)
BEGIN
	
	DECLARE v_jugadorId INT;
	
	START TRANSACTION;
	
	
	
	INSERT INTO Jugadores(nickname) VALUES (p_nickname);
	
	SET v_jugadorId = LAST_INSERT_ID();
	
	CALL InsertarValoracion(v_jugadorId, p_videojuegoId, p_puntuacion, p_opinion, p_veredicto);
	
	COMMIT;

END //

DELIMITER ;

PRUEBA PROCEDIMIENTOS
#VERDE
/*
CALL InsertarValoracion(1,2,5,"cualquiera",'Imprescindible');
CALL InsertarValoracion(2,4,3,"cualquiera",'Comprar en rebajas');
CALL InsertarValoracion(3,3,4,"cualquiera",'Recomendado');
CALL InsertarValoracion(4,5,1,"cualquiera",'No merece la pena');
CALL InsertarValoracion(2,3,4.5,"cualquiera",'Imprescindible');
*/

#ROJO
#CALL InsertarValoracion(1,6,10,"cualquiera",'Imprescindible')
#CALL InsertarValoracion(3,1,3,"cualquiera",'Ni fu ni fa');
#CALL InsertarValoracion(3,3,2,"No era para tanto",'No merece la pena');
#CALL InsertarValoracion(6,8,3,"cualquiera",'Comprar en rebajas');

#BIEN
#CALL pAddUsuarioValoracion('NuevoUsuario', 1, 4.5, 'Gran juego', 'Recomendado');

#MAL
#CALL pAddUsuarioValoracion('NuevoUsuario', 1, 3.0, 'Juego interesante', 'Comprar en rebajas');

TRIGGERS

/*
DELIMITER //

CREATE TRIGGER verificarFechaValoracion
BEFORE INSERT ON Valoraciones
FOR EACH ROW 
BEGIN

	IF NEW.fechaValoracion < (SELECT fechaLanzamiento FROM Videojuegos WHERE videojuegoId = NEW.videojuegoId) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de valoracion no puede ser anterior a la fecha de lanzamiento del videojuego';
	END IF;
	
	IF NEW.fechaValoracion > CURDATE() THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de valoracion no puede ser posterior a la fecha actual';
	END IF;
	
END //


DELIMITER ;
*/

DELIMITER //
CREATE TRIGGER verificaSiBeta
BEFORE INSERT ON valoraciones
FOR EACH ROW 
BEGIN
	IF 'Beta' = (SELECT estado FROM videojuegos WHERE videojuegoId = NEW.videojuegoId) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede valorar un juego en fase Beta.';
	END IF;
	
END //
DELIMITER ;


PRUEBA TRIGGERS

INSERT INTO valoraciones(jugadorId,videojuegoId,puntuacion,opinion,veredicto,fechaValoracion) 
#trigger fechas
#VALUES (1,3,3,'cualquiera','Recomendado','2024-12-19');
#VALUES (1,3,3,'cualquiera','Recomendado','1986-12-19');
#trigger beta
#VALUES (1,9,3,'cualquiera','Recomendado','2024-12-18');

CONSULTAS

/*
SELECT 
    j.nickname AS nickn,
    v.nombre AS nombreJuego,
    val.valoracionId AS valoracioId,
    j.jugadorId AS jugadorId,
    v.videojuegoId AS videojuegoId,
    val.fechaValoracion AS fecha,
    val.puntuacion AS puntuacion,
    val.opinion AS comentario,
    val.numeroLikes AS likes,
    val.veredicto AS veredicto
FROM 
    Valoraciones val
JOIN 
    Jugadores j ON val.jugadorId = j.jugadorId
JOIN 
    Videojuegos v ON val.videojuegoId = v.videojuegoId
ORDER BY 
    v.videojuegoId, val.valoracionId;
*/
SELECT v.nombre, 
       COALESCE(AVG(val.puntuacion), 0) AS media_valoraciones
FROM Videojuegos v
LEFT JOIN Valoraciones val ON v.videojuegoId = val.videojuegoId
GROUP BY v.videojuegoId
ORDER BY media_valoraciones DESC;

FUNCION

DELIMITER //

CREATE FUNCTION NumeroValoracionesUsuario(p_jugadorId INT) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_numeroValoraciones INT;

    SELECT COUNT(*) INTO v_numeroValoraciones
    FROM Valoraciones
    WHERE jugadorId = p_jugadorId;

    RETURN v_numeroValoraciones;
END //

DELIMITER ;


#SELECT NumeroValoracionesUsuario(2);

