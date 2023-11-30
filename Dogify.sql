-- 1) Procedure para registrar un nuevo perro y asignarlo a un dueño:

create procedure proc_registrar_perro_y_asignar_dueno
    @raza varchar(100),
    @edad int,
    @sexo varchar(100),
    @esterilizado bit,
    @vacunado bit,
    @tipo_pelo varchar(100),
    @longitud_pelo varchar(100),
    @id_dueno int
as
begin
    begin try
        begin transaction

        declare @id_perros int;

        insert into perros (raza, edad, sexo, esterilizado, vacunado, tipo_pelo, longitud_pelo)
        values (@raza, @edad, @sexo, @esterilizado, @vacunado, @tipo_pelo, @longitud_pelo);

        set @id_perros = scope_identity();

        insert into perros_perdidos (hora_perdida, lugar_perdida, nombre_pp, id_dueno, fecha_registro, id_perros)
        values (getdate(), 'Desconocido', 'Desconocido', @id_dueno, getdate(), @id_perros);

        print ('Perro registrado y asignado a dueño correctamente')

        commit transaction
    end try
    begin catch 
        print error_message()
        rollback 
    end catch
end
go

-- 2) Función para obtener la cantidad de perros alojados en una perrera específica:

create function fun_cantidad_perros_en_perrera (@id_perrera int)
returns table
as
return  
    select count(*) as cantidad
    from perros_alojados
    where id_perreras = @id_perrera

-- 3) Query para obtener la lista de perros alojados por cada alojante, ordenados por la cantidad de perros que tienen:

select A.id_alojantes, A.direccion, count(APA.id_perros_alojados) as cantidad_perros
from alojantes as A
inner join alojantes_perros_alojados as APA on A.id_alojantes = APA.id_alojantes
group by A.id_alojantes, A.direccion
order by cantidad_perros desc

-- 4) Crea una funcion la cual me ayude a encontrar los perros avistados entre fechas específicas

create or alter function fun_perros_avistados_entre_fechas (@fecha_inicio datetime, @fecha_final datetime) returns table
as
return  select * from avistamientos where tiempo_registro BETWEEN @fecha_inicio AND @fecha_final 
go

select * from dbo.fun_perros_avistados_entre_fechas('2023-01-01', '2024-02-02')

-- 5) un query donde pueda saber exactamente quienes son los dueños de las mascotas y su respectiva mascota y además que enfermedades tiene

select D.nombre_dueno, D.dni, P.id_perros, P.raza, E.id_enfermedades
from duenos as D 
inner join perros_perdidos as Pp on D.id_duenos = Pp.id_dueno
inner join perros as P on Pp.id_perros = P.id_perros
inner join perros_enfermedades as E on P.id_perros = E.id_perros
go

-- 6) Crea un procedimiento que actualiza la vacunación de una perro

create procedure proc_actualizar_vacuna
    @id_perros int,
    @vacunado bit = 1
as
begin
    begin try
        begin transaction

        if (select vacunado from perros where id_perros = @id_perros) = 0  
        begin
            update perros 
            set vacunado = @vacunado
            where id_perros = @id_perros

            print ('Proceso de vacunado actualizado')
        end 
        else 
        begin
            print ('El perro ya está vacunado')
            rollback
        end

        commit transaction
    end try
    begin catch 
        print error_message()
        rollback 
    end catch
end
go

exec proc_actualizar_vacuna @id_perros = 3

-- 7) Procedimiento para obtener perros con una enfermedad específica:

CREATE PROCEDURE proc_perros_enfermedad_especifica
    @nombre_enfermedad VARCHAR(100)
AS
BEGIN
    SELECT p.id_perros, p.raza, p.edad, e.nombre AS enfermedad, e.descripcion AS descripcion_enfermedad
    FROM perros p
    JOIN perros_enfermedades pe ON p.id_perros = pe.id_perros
    JOIN enfermedades e ON pe.id_enfermedades = e.id_enfermedades
    WHERE e.nombre = @nombre_enfermedad;
END

select * from perros_enfermedades

exec proc_perros_enfermedad_especifica @nombre_enfermedad = 'Resfriado'

-- 8) Lista de perreras que tienen más de 100 perros alojados
select p.id_perreras, p.nombre_perrera, count(pa.id_perros_alojados) as cantidad_perros_alojados
from perreras as p
inner join alojantes as a on p.id_alojantes = a.id_alojantes
inner join alojantes_perros_alojados as apa on a.id_alojantes = apa.id_alojantes
inner join perros_alojados as pa on apa.id_perros_alojados = pa.id_perros_alojados
group by p.id_perreras, p.nombre_perrera
having count(pa.id_perros_alojados) > 100

-- 9) Ordenar razas de perro de la mas comun a la menos comun
select p.raza, count(p.raza) as cantidad
from perros as p
group by p.raza
order by count(p.raza) desc

-- 10) Ver avistamientos de un perro segun el dueño
select p.nombre_pp, a.tiempo_registro, a.latitud, a.longitud
from perros_perdidos as pp
inner join perros as p on pp.id_perros = p.id_perros
inner join avistamientos as a on p.id_perros = a.id_perros
where pp.nombre_pp = 'Juan'

-- 11) Dueños con más de una mascota ---
SELECT D.nombre_dueno, D.dni, COUNT(Pp.id_perros) AS cantidad_mascotas
FROM duenos AS D
     INNER JOIN perros_perdidos AS Pp ON D.id_duenos = Pp.id_dueno
GROUP BY D.nombre_dueno, D.dni
HAVING COUNT(Pp.id_perros) > 1;

-- 12) Calcular la edad promedio de perros de una raza específica ---
CREATE FUNCTION fun_edad_promedio_por_raza (@raza varchar(100)) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @edad_promedio DECIMAL(10,2);

    SET @edad_promedio = (SELECT AVG(edad) 
                          FROM perros 
                          WHERE raza = @raza);

    RETURN @edad_promedio;
END;
GO

--- uso de la función ---
SELECT dbo.fun_edad_promedio_por_raza('pug');

-- 13)Procedimiento para reportar un perro como perro perdido ---
CREATE PROCEDURE proc_reportar_perro_perdido
    @id_perro INT,
    @hora_perdida TIME,
    @lugar_perdida VARCHAR(100),
    @nombre_perro VARCHAR(100),
    @id_dueno INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            -- Insertar el registro del perro perdido
            INSERT INTO perros_perdidos (id_perros, hora_perdida, lugar_perdida, nombre_pp, id_dueno, fecha_registro)
            VALUES (@id_perro, @hora_perdida, @lugar_perdida, @nombre_perro, @id_dueno, GETDATE())

            PRINT 'Perro reportado como perdido exitosamente.'
        COMMIT 
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE()
        ROLLBACK TRANSACTION
    END CATCH
END
GO

--- uso del procedimiento ---
exec proc_reportar_perro_perdido @id_perro = 123, @hora_perdida = '08:00:00', @lugar_perdida = 'Parque Central', @nombre_perro = 'Max', @id_dueno = 456;

-- 14) Listar perros perdidos y sus dueños:
SELECT pp.id_perros_perdidos, pp.nombre_pp, d.nombre_dueno, d.apellido_dueno
FROM perros_perdidos pp
INNER JOIN duenos d ON pp.id_dueno = d.id_duenos;

-- 15) Perros que no han sido avistados:
SELECT p.id_perros, p.raza
FROM perros p
WHERE NOT EXISTS (
   SELECT 1
   FROM avistamientos a
   WHERE a.id_perros = p.id_perros
);

-- 16) Mostrar las enfermedades de un perro específico:
SELECT p.id_perros, p.raza, e.nombre AS enfermedad, e.descripcion
FROM perros p
LEFT JOIN perros_enfermedades pe ON p.id_perros = pe.id_perros
LEFT JOIN enfermedades e ON pe.id_enfermedades = e.id_enfermedades
WHERE p.id_perros = Paco ;
