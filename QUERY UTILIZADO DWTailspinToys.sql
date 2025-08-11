/*
CREACIÓN DE DATA WAREHOUSE
TAREA 1 MODULO 3

PRESENTADO POR JOSE ESTEBAN DURAN CRUZ, DC18024.
*/

create database DWTailspinToys
go

use DWTailspinToys
go

-- creacion de dimension dimTiempo

CREATE TABLE dimTiempo (
    fechaKey INT PRIMARY KEY, -- Formato YYYYMMDD
    fecha DATE NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    dia INT NOT NULL,
    nombre_mes NVARCHAR(20) NOT NULL,
    dia_semana NVARCHAR(20) NOT NULL,
    trimestre TINYINT NOT NULL,
    es_fin_de_semana BIT NOT NULL
);
GO

-- creacion de dimension dimProducto

CREATE TABLE dimProducto (
    productoKey INT IDENTITY(1,1) PRIMARY KEY,
    productoID NVARCHAR(50) NOT NULL, -- Clave natural del origen
    nombre NVARCHAR(200) NOT NULL,
    categoria NVARCHAR(100),
    marca NVARCHAR(100),
    precio_recomendado DECIMAL(18,4) NULL,
    fecha_inicio DATETIME2 NOT NULL,
    fecha_fin DATETIME2 NULL,
    es_actual BIT NOT NULL,
    version INT NOT NULL
);
GO

-- creacion de dimension dimCliente

CREATE TABLE dimCliente (
    clienteKey INT IDENTITY(1,1) PRIMARY KEY,
    clienteID NVARCHAR(50) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    apellido NVARCHAR(200) NOT NULL,
    ciudad NVARCHAR(100),
    estado NVARCHAR(100),
    pais NVARCHAR(100),
    correo NVARCHAR(200),
    telefono NVARCHAR(50),
    fecha_inicio DATETIME2 NOT NULL,
    fecha_fin DATETIME2 NULL,
    es_actual BIT NOT NULL,
    version INT NOT NULL
);
GO

-- creacion de dimension dimEmpleado

CREATE TABLE dimEmpleado (
    empleadoKey INT IDENTITY(1,1) PRIMARY KEY,
    empleadoID NVARCHAR(50) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    apellido NVARCHAR(200) NOT NULL,
    cargo NVARCHAR(100),
    departamento NVARCHAR(100),
    fecha_inicio DATETIME2 NOT NULL,
    fecha_fin DATETIME2 NULL,
    es_actual BIT NOT NULL,
    version INT NOT NULL
);
GO

-- creacion de dimension dimTienda

CREATE TABLE dimTienda (
    tiendaKey INT IDENTITY(1,1) PRIMARY KEY,
    tiendaID NVARCHAR(50) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    ciudad NVARCHAR(100),
    estado NVARCHAR(100),
    pais NVARCHAR(100),
    fecha_inicio DATETIME2 NOT NULL,
    fecha_fin DATETIME2 NULL,
    es_actual BIT NOT NULL,
    version INT NOT NULL
);
GO

-- creacion de dimension dimPromocion

CREATE TABLE dimPromocion (
    promocionKey INT IDENTITY(1,1) PRIMARY KEY,
    promocionID NVARCHAR(50) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    tipo NVARCHAR(100),
    descripcion NVARCHAR(500),
    fecha_inicio DATETIME2 NOT NULL,
    fecha_fin DATETIME2 NULL,
    es_actual BIT NOT NULL,
    version INT NOT NULL
);
GO

-- creacion de dimension basura (dimJunk)

CREATE TABLE dimJunk (
    junk_Key INT IDENTITY(1,1) PRIMARY KEY,
    metodo_pago NVARCHAR(50),
    es_regalo BIT,
    canal_venta NVARCHAR(50),
    prioridad_entrega NVARCHAR(50),
    otro_atributo NVARCHAR(100),
    fecha_inicio DATETIME2 NOT NULL,
    fecha_fin DATETIME2 NULL,
    es_actual BIT NOT NULL,
    version INT NOT NULL
);
GO

-- creacion de tabla de hechos facVentas

CREATE TABLE facVentas (
    fac_ventaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    fechaKey INT NOT NULL,
    productoKey INT NOT NULL,
    clienteKey INT NOT NULL,
    empleadoKey INT NOT NULL,
    tiendaKey INT NOT NULL,
    promocionKey INT NULL,
    junk_Key INT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(18,4) NOT NULL,
    descuento DECIMAL(18,4) NULL,
    total_linea DECIMAL(18,4) NOT NULL,
    costo_unitario DECIMAL(18,4) NULL,
    margen AS (total_linea - (cantidad * costo_unitario)) PERSISTED,
    fecha_carga DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT fk_fecha FOREIGN KEY (fechaKey) REFERENCES dimTiempo(fechaKey),
    CONSTRAINT fk_producto FOREIGN KEY (productoKey) REFERENCES dimProducto(ProductoKey),
    CONSTRAINT fk_cliente FOREIGN KEY (clienteKey) REFERENCES dimCliente(ClienteKey),
    CONSTRAINT fk_empleado FOREIGN KEY (empleadoKey) REFERENCES dimEmpleado(empleadoKey),
    CONSTRAINT fk_tienda FOREIGN KEY (tiendaKey) REFERENCES dimTienda(tiendaKey),
    CONSTRAINT fk_promocion FOREIGN KEY (promocionKey) REFERENCES dimPromocion(promocionKey),
    CONSTRAINT fk_junk FOREIGN KEY (junk_Key) REFERENCES dimJunk(junk_Key)
);
GO

--creacion de indices

CREATE INDEX IX_facVentas_fecha ON facVentas(fechaKey);
CREATE INDEX IX_facVentas_producto ON facVentas(productoKey);
CREATE INDEX IX_facVentas_cliente ON facVentas(clienteKey);
CREATE INDEX IX_facVentas_empleado ON facVentas(empleadoKey);
GO



-- Script para poblar dimTiempo con 5 años de fechas

SET NOCOUNT ON;

DECLARE @start DATE = '2016-01-01';
DECLARE @end DATE = '2022-12-31';

;WITH cte AS (
    SELECT @start AS fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, fecha)
    FROM cte
    WHERE fecha < @end
)
INSERT INTO dw.dimTiempo (
    fechaKey, 
    fecha, 
    anio, 
    mes, 
    dia, 
    nombre_mes, 
    dia_semana, 
    trimestre, 
    es_fin_de_semana
)
SELECT 
    CONVERT(INT, FORMAT(fecha, 'yyyyMMdd')) AS sk_fecha,
    fecha,
    DATEPART(YEAR, fecha),
    DATEPART(MONTH, fecha),
    DATEPART(DAY, fecha),
    DATENAME(MONTH, fecha),
    DATENAME(WEEKDAY, fecha),
    DATEPART(QUARTER, fecha),
    CASE WHEN DATEPART(WEEKDAY, fecha) IN (1,7) THEN 1 ELSE 0 END
FROM cte
OPTION (MAXRECURSION 0);
