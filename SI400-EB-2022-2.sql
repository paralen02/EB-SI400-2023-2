--CASO 1 (Perú Service Summit)

--Pregunta 1 (8 p.).
--Diseñar el modelo físico de base de datos para la plataforma de Rueda de Negocios, identificando las 
--principales tablas y sus respectivos atributos, las relaciones entre las tablas, las llaves primarias y llaves 
--secundarias.


CREATE DATABASE PeruvianServiceSummitDB;

GO

USE PeruvianServiceSummitDB;

-- Tablas
-- Tabla: empresas_peruanas
CREATE TABLE empresas_peruanas (
    ruc varchar(20) NOT NULL,
    razon_social varchar(100) NOT NULL,
    ciudad varchar(50) NOT NULL,
    cantidad_empleados int NOT NULL,
    servicios_ofrecidos varchar(255) NOT NULL,
    facturacion_promedio_anual decimal(15, 2) NOT NULL,
    CONSTRAINT empresas_peruanas_pk PRIMARY KEY (ruc)
);

-- Tabla: contactos_empresas_peruanas
CREATE TABLE contactos_empresas_peruanas (
    dni varchar(15) NOT NULL,
    nombres varchar(50) NOT NULL,
    apellido_paterno varchar(50) NOT NULL,
    apellido_materno varchar(50) NOT NULL,
    puesto varchar(50) NOT NULL,
    telefono varchar(15) NOT NULL,
    correo_electronico varchar(100) NOT NULL,
    ruc_empresa varchar(20) NOT NULL,
    CONSTRAINT contactos_empresas_peruanas_pk PRIMARY KEY (dni),
    CONSTRAINT contactos_empresas_peruanas_fk FOREIGN KEY (ruc_empresa) REFERENCES empresas_peruanas (ruc)
);

-- Tabla: clientes_empresas_peruanas
CREATE TABLE clientes_empresas_peruanas (
    ruc_cliente varchar(20) NOT NULL,
    razon_social_cliente varchar(100) NOT NULL,
    servicios_ejecutados varchar(255) NOT NULL,
    ruc_empresa varchar(20) NOT NULL,
    CONSTRAINT clientes_empresas_peruanas_pk PRIMARY KEY (ruc_cliente),
    CONSTRAINT clientes_empresas_peruanas_fk FOREIGN KEY (ruc_empresa) REFERENCES empresas_peruanas (ruc)
);

-- Tabla: empresas_contratantes_extranjero
CREATE TABLE empresas_contratantes_extranjero (
    ruc_o_identificador varchar(20) NOT NULL,
    razon_social varchar(100) NOT NULL,
    pais_procedencia varchar(50) NOT NULL,
    ciudad_procedencia varchar(50) NOT NULL,
    servicios_requeridos varchar(255) NOT NULL,
    CONSTRAINT empresas_contratantes_extranjero_pk PRIMARY KEY (ruc_o_identificador)
);

-- Tabla: disponibilidad_empresas
CREATE TABLE disponibilidad_empresas (
    ruc_empresa varchar(20) NOT NULL,
    fecha date NOT NULL,
    disponible_desde time NOT NULL,
    disponible_hasta time NOT NULL,
    CONSTRAINT disponibilidad_empresas_pk PRIMARY KEY (ruc_empresa, fecha),
    CONSTRAINT disponibilidad_empresas_fk FOREIGN KEY (ruc_empresa) REFERENCES empresas_peruanas (ruc)
);

-- Tabla: disponibilidad_contratantes
CREATE TABLE disponibilidad_contratantes (
    ruc_contratante varchar(20) NOT NULL,
    fecha date NOT NULL,
    disponible_desde time NOT NULL,
    disponible_hasta time NOT NULL,
    CONSTRAINT disponibilidad_contratantes_pk PRIMARY KEY (ruc_contratante, fecha),
    CONSTRAINT disponibilidad_contratantes_fk FOREIGN KEY (ruc_contratante) REFERENCES empresas_contratantes_extranjero (ruc_o_identificador)
);

-- Tabla: reuniones
CREATE TABLE reuniones (
    id_reunion int NOT NULL,
    ruc_empresa_peruana varchar(20) NOT NULL,
    ruc_contratante_extranjero varchar(20) NOT NULL,
    fecha date NOT NULL,
    hora_inicio time NOT NULL,
    hora_fin time NOT NULL,
    realizada bit NOT NULL,
    CONSTRAINT reuniones_pk PRIMARY KEY (id_reunion),
    CONSTRAINT reuniones_fk_empresa_peruana FOREIGN KEY (ruc_empresa_peruana) REFERENCES empresas_peruanas (ruc),
    CONSTRAINT reuniones_fk_contratante_extranjero FOREIGN KEY (ruc_contratante_extranjero) REFERENCES empresas_contratantes_extranjero (ruc_o_identificador)
);

-- Tabla: oportunidades_negocio
CREATE TABLE oportunidades_negocio (
    id_oportunidad int NOT NULL,
    ruc_empresa_peruana varchar(20) NOT NULL,
    ruc_contratante_extranjero varchar(20) NOT NULL,
    servicio_ofrecido varchar(255) NOT NULL,
    monto_estimado decimal(15, 2) NOT NULL,
    CONSTRAINT oportunidades_negocio_pk PRIMARY KEY (id_oportunidad),
    CONSTRAINT oportunidades_negocio_fk_empresa_peruana FOREIGN KEY (ruc_empresa_peruana) REFERENCES empresas_peruanas (ruc),
    CONSTRAINT oportunidades_negocio_fk_contratante_extranjero FOREIGN KEY (ruc_contratante_extranjero) REFERENCES empresas_contratantes_extranjero (ruc_o_identificador)
);


--Caso 2: Películas (MoviesDB)

--Pregunta 2 (2 p.).
--Crear un procedimiento almacenado o función que retorne la cantidad de actores que participaron en 
--películas de un determinado género (ingresado como parámetro) para un determinado año (ingresado como 
--parámetro).


create view v_actor_quantity_by_category_by_year 
as 
select description, year, count(distinct  actor_id) as quantity 
    from movie_cast as mc 
    join movies as m on mc.movie_id = m.id 
    join genres as g on m.genre_id = g.id 
group by description, year 
go; 
 
create function f_actor_quantity_by_category_by_year( 
    @description varchar(50), 
    @year int 
) returns int 
as 
begin 
    declare @quantity int 
    set @quantity = (select quantity 
    from v_actor_quantity_by_category_by_year 
    where description = @description and year = @year) 
    return @quantity 
end 
go; 

--Pregunta 3 (2 p.).
--Crear un procedimiento almacenado o función que retorne el nombre del actor (o actores) que participó más 
--veces en películas de un determinado género (ingresado como parámetro) para un determinado año 
--(ingresado como parámetro).

create view v_actors_quantity_by_year_by_category 
as 
select name, year, description, count(m.id) as quantity 
from actors as a 
    join movie_cast as mc on a.id = mc.actor_id 
    join movies as m on mc.movie_id = m.id 
    join genres as g on m.genre_id = g.id 
group by name, year, description 
go 
 
 
create function f_actor_max_movies_by_year_by_category( 
    @year int, 
    @description varchar(50) 
) returns table 
return 
select name 
from v_actors_quantity_by_year_by_category 
where year = @year and description = @description 
    and quantity = (select max(quantity) 
                    from v_actors_quantity_by_year_by_category 
                    where year = @year and description = @description) 
go; 

--Caso 3: Airbnb
--La aplicación Airbnb es una plataforma en línea que permite a las personas alquilar alojamiento a corto plazo. 
--Esto va desde personas normales con un dormitorio extra hasta empresas administradoras de propiedades 
--que arriendan varios alojamientos.

--Pregunta 4 (4 p.).
--Establecer una regla de validación utilizando JSON Schema para una colección de documentos que 
--representen el detalle por alojamiento de acuerdo con las pantallas mostradas.

db.createCollection("alojamientos", {
	validator: {
		$jsonSchema: {
			bsonType: "object",
			required: ["nombre", "ubicacion", "anfitrion"],
			properties: {
				nombre: {
					bsonType: "string"
				},
				ubicacion: {
					bsonType: "object",
					required: ["latitud", "longitud"],
					properties: {
						latitud: {
							bsonType: "double"
						},
						longitud: {
							bsonType: "double"
						},
						ciudad: {
							bsonType: "string"
						}
					}
				},
				anfitrion: {
					bsonType: "object",
				},
				servicios: {
					bsonType: "array",
					minItems: 1,
					items: {
						bsonType: "string"
					}
				}
			}
		}
	}
})
