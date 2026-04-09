-- ============================================================
-- PROYECTO: Análisis de Ventas 
-- AUTOR: Jorge_Torres
-- FECHA: Abril 2026
-- DESCRIPCIÓN: Análisis del rendimiento de ventas para identificar
--              oportunidades de crecimiento y optimizar estrategia comercial
-- HERRAMIENTA: SQL Server Management Studio (SSMS)
-- TÉCNICAS: Window Functions, CTEs, JOINs múltiples, Agregaciones
-- ============================================================


-- ============================================================
-- PREGUNTA 1: ¿Qué productos y categorías generan más ingresos y margen?
-- MÉTRICAS: Revenue, Cost, Profit, Profit Margin %
-- TABLAS: SalesOrderDetail, Product, ProductSubcategory, ProductCategory
-- NOTA: Se excluyen productos con StandardCost = 0 para evitar 
--       distorsiones en el cálculo del margen
-- ============================================================

-- 1A: Por categoría
-- Objetivo: identificar qué líneas de negocio son más rentables
-- Hallazgo: Bikes lidera en revenue ($94M), Accessories tiene el mayor profit_margin

SELECT 
	c.ProductCategoryID AS id,
	c.Name,
	(SUM(so.UnitPrice) - SUM(p.StandardCost)) / SUM(so.UnitPrice) * 100 AS margen, 
	SUM(so.LineTotal) AS revenue,
	SUM(p.StandardCost * so.OrderQty) AS cost, 
	SUM(so.LineTotal) - SUM(p.StandardCost * so.OrderQty) AS profit, 
	CAST(
		(SUM(so.LineTotal) - SUM(p.StandardCost * so.OrderQty)) / SUM(so.LineTotal) * 100 
		AS DECIMAL (5,2))AS profit_margin
FROM
	Sales.SalesOrderDetail AS so
INNER JOIN
	Production.Product AS p
		ON so.ProductID = p.ProductID
INNER JOIN
	Production.ProductSubcategory AS sub
		ON p.ProductSubcategoryID = sub.ProductSubcategoryID
INNER JOIN
	Production.ProductCategory AS c
		ON sub.ProductCategoryID = c.ProductCategoryID
WHERE 
	p.StandardCost > 0
GROUP BY
	c.ProductCategoryID,
	c.Name
ORDER BY
	c.ProductCategoryID ASC;

-- 1C: Top 10 productos por revenue
-- Objetivo: identificar los productos estrella del catálogo
-- Hallazgo: Mountain-200 Black lidera con $4.4M de revenue y 27.63% de margen

SELECT TOP 10 
	p.ProductID AS id,
	p.Name,
	SUM(so.LineTotal) AS revenue,
	(SUM(so.UnitPrice) - SUM(p.StandardCost)) / SUM(so.UnitPrice) * 100 AS margen
FROM
	Sales.SalesOrderDetail AS so
INNER JOIN
	Production.Product AS p
		ON so.ProductID = p.ProductID
INNER JOIN
	Production.ProductSubcategory AS sub
		ON p.ProductSubcategoryID = sub.ProductSubcategoryID
WHERE 
	p.StandardCost > 0
GROUP BY
	p.ProductID,
	p.Name
ORDER BY
	revenue DESC;

-- 1B: Por subcategoría
-- Objetivo: detectar subcategorías con margen negativo que requieren atención
-- Hallazgo: Road Frames (-4.48%), Jerseys (-19.92%) y Caps (-12.30%) 
--           se venden por debajo del coste — revisar estrategia de precios

SELECT 
	sub.ProductSubcategoryID AS id,
	sub.Name,
	(SUM(so.UnitPrice) - SUM(p.StandardCost)) / SUM(so.UnitPrice) * 100 AS margen, 
	SUM(so.LineTotal) AS revenue,
	SUM(p.StandardCost * so.OrderQty) AS cost, 
	SUM(so.LineTotal) - SUM(p.StandardCost * so.OrderQty) AS profit, 
	CAST(
		(SUM(so.LineTotal) - SUM(p.StandardCost * so.OrderQty)) / SUM(so.LineTotal) * 100 
		AS DECIMAL (5,2))AS profit_margin
FROM
	Sales.SalesOrderDetail AS so
INNER JOIN
	Production.Product AS p
		ON so.ProductID = p.ProductID
INNER JOIN
	Production.ProductSubcategory AS sub
		ON p.ProductSubcategoryID = sub.ProductSubcategoryID
INNER JOIN
	Production.ProductCategory AS c
		ON sub.ProductCategoryID = c.ProductCategoryID
WHERE 
	p.StandardCost > 0
GROUP BY
	sub.ProductSubcategoryID,
	sub.Name
ORDER BY
	sub.ProductSubcategoryID ASC;
	
-- ============================================================
-- PREGUNTA 2: ¿Cómo evolucionan las ventas en el tiempo?
-- MÉTRICAS: Revenue mensual, YTD, YoY %
-- TABLAS: SalesOrderHeader
-- NOTA: YoY compara el mismo mes entre años distintos usando 
--       PARTITION BY month ORDER BY year
-- Hallazgo: Junio 2012 fue el mes de mayor crecimiento interanual
--           2013 fue el año con mayor revenue acumulado anual
-- ============================================================

WITH base AS (
    SELECT
        YEAR(OrderDate) AS year,
        MONTH(OrderDate) AS month,
        SUM(TotalDue) AS revenue
    FROM 
		Sales.SalesOrderHeader
    GROUP BY 
		YEAR(OrderDate), 
			MONTH(OrderDate)
)
SELECT
    year,
    month,
    revenue,
    SUM(revenue) OVER(
        PARTITION BY year
        ORDER BY month
    ) AS ytd,
    LAG(revenue) OVER(
        PARTITION BY month
        ORDER BY year
    ) AS yoy_anterior,
    CAST(
        (revenue - LAG(revenue) OVER(
			PARTITION BY month 
			ORDER BY year)) /
        LAG(revenue) OVER(
			PARTITION BY month 
			ORDER BY year) * 100
			AS DECIMAL(10,2)) 
			AS yoy_pct
FROM 
	base
ORDER BY 
	year, month

-- ============================================================
-- PREGUNTA 3: ¿Qué territorios generan más ventas?
-- MÉTRICAS: Revenue, contribución %, clientes únicos, AOV
-- TABLAS: SalesOrderHeader, SalesTerritory
-- Hallazgo: Southwest lidera con mayor contribución al revenue total
--           Central tiene el AOV más alto — clientes menos frecuentes pero más valiosos
-- ============================================================

WITH base AS (
	SELECT
		Name AS name,
		SUM(TotalDue) AS revenue,
		COUNT (DISTINCT CustomerID) AS num_clientes,
		COUNT(salesOrderID) AS num_ordenes
	FROM
	Sales.SalesTerritory AS t
	INNER JOIN
		Sales.SalesOrderHeader AS so
			ON t.TerritoryID = so.TerritoryID
	GROUP BY
		Name
)
SELECT 
	name,
	revenue,
	num_clientes,
	revenue / SUM(revenue) OVER () * 100 AS pct_contribucion,
	CAST(
		revenue / num_ordenes 
		AS DECIMAL (10,2))
		AS AOV
FROM
	base
ORDER BY 
	revenue DESC

-- ============================================================
-- PREGUNTA 4: ¿Quiénes son los clientes más valiosos?
-- MÉTRICAS: Revenue, pedidos, AOV, CLV, % acumulado Pareto
-- TABLAS: SalesOrderHeader, Customer
-- NOTA: CLV aproximado = revenue total / años de antigüedad como cliente
--       Si el cliente solo ha comprado una vez, CLV = revenue total
-- Hallazgo: El 8.1% de los clientes (1,551) genera el 80% del revenue total
--           El cliente más valioso tiene $989,184 en revenue histórico
-- ============================================================

WITH base AS (
	SELECT 
		so.CustomerID AS cliente,
		SUM(TotalDue) AS revenue_cliente,
		COUNT(SalesOrderID) AS pedidos,
		SUM(TotalDue) / COUNT(SalesOrderID) AS AOV,
		CASE
			 WHEN DATEDIFF( DAY, MIN(Orderdate), MAX (OrderDate)) / 365.25 = 0 THEN SUM(TotalDue)
			 ELSE SUM(TotalDue) / (DATEDIFF( DAY, MIN(Orderdate), MAX (OrderDate)) / 365.25)
		END AS clv
	FROM
		Sales.SalesOrderHeader AS so
	INNER JOIN
		Sales.Customer AS c
			ON so.CustomerID = c.CustomerID
	GROUP BY
		so.CustomerID 
)
SELECT TOP 20 
	cliente,
	revenue_cliente,
	pedidos,
	AOV,
	CAST( clv AS DECIMAL (10,2)) AS CLV,
	SUM(revenue_cliente) OVER(ORDER BY revenue_cliente DESC) / 
		SUM(revenue_cliente) OVER() * 100 AS pct_acumulado
FROM 
	base
ORDER BY
	revenue_cliente DESC;

-- ============================================================
-- PREGUNTA 5: ¿Qué canales de venta son más rentables?
-- MÉTRICAS: Revenue, pedidos, AOV, contribución %
-- TABLAS: SalesOrderHeader
-- NOTA: OnlineOrderFlag = 1 es venta online, 0 es venta por vendedor (tienda)
-- Hallazgo: Tienda genera el 73.67% del revenue con AOV de $23,850
--           Online tiene 20x menos AOV ($1,172) pero 7x más pedidos
--           Los pedidos de tienda corresponden a empresas y distribuidores
-- ============================================================

WITH base AS (
	SELECT
		OnlineOrderFlag AS canal,
		SUM(TotalDue) AS revenue,
		COUNT(*) AS num_pedidos,
		SUM(TotalDue) / COUNT(*) AS AOV
	FROM 
		Sales.SalesOrderHeader
	GROUP BY
		OnlineOrderFlag
		
)
SELECT
	CASE
		WHEN canal = 1 THEN 'Online'
		ELSE  'Tienda'
	END AS canal,
	revenue,
	num_pedidos,
	AOV,
	revenue / SUM(revenue) OVER () * 100 AS contribucion
FROM
	base
ORDER BY
	revenue DESC;

-- ============================================================
-- PREGUNTA 6: ¿Cómo es el ticket promedio y comportamiento de compra?
-- MÉTRICAS: AOV por año, productos por pedido, distribución frecuencia
-- TABLAS: SalesOrderHeader, SalesOrderDetail
-- NOTA: Se separa en dos queries — AOV/productos por año y distribución de frecuencia
--       Son dos niveles de agregación distintos que no se pueden combinar en una sola query
-- ============================================================

-- 6A: AOV y productos medios por pedido por año
-- Objetivo: ver si el ticket medio evoluciona con el tiempo
-- Hallazgo: El AOV cae significativamente de 2012 a 2013 — 
--           la empresa captó muchos clientes nuevos con compras pequeñas

SELECT 
    YEAR(oh.OrderDate) AS year,
    COUNT(DISTINCT oh.SalesOrderID) AS num_pedidos,
    CAST(SUM(oh.TotalDue) / COUNT(DISTINCT oh.SalesOrderID) 
		AS DECIMAL(10,2)) AS AOV,
    CAST(SUM(od.OrderQty) / COUNT(DISTINCT oh.SalesOrderID) 
		AS DECIMAL(10,2)) AS avg_productos_pedido
FROM 
	Sales.SalesOrderHeader AS oh
INNER JOIN 
	Sales.SalesOrderDetail AS od 
		ON oh.SalesOrderID = od.SalesOrderID
GROUP BY 
	YEAR(oh.OrderDate)
ORDER BY 
	year

GO

-- 6B: Distribución de clientes por frecuencia de compra
-- Objetivo: entender cuántos clientes son recurrentes
-- Hallazgo: El 61% de los clientes (11,649) solo compra una vez —
--           oportunidad de mejora en retención y fidelización

WITH frecuencia AS ( 
    SELECT
        CustomerID,
        COUNT(SalesOrderID) AS num_pedidos
    FROM 
		Sales.SalesOrderHeader
    GROUP BY 
		CustomerID
)
SELECT
    CASE
        WHEN num_pedidos = 1 THEN '1 compra'
        WHEN num_pedidos = 2 THEN '2 compras'
        ELSE '3+ compras'
    END AS segmento,
    COUNT(*) AS num_clientes
FROM 
	frecuencia
GROUP BY
    CASE
        WHEN num_pedidos = 1 THEN '1 compra'
        WHEN num_pedidos = 2 THEN '2 compras'
        ELSE '3+ compras'
    END
ORDER BY 
	num_clientes DESC;

-- ============================================================
-- PREGUNTA 7: ¿Qué patrones existen en el ciclo de ventas?
-- MÉTRICAS: Clientes nuevos vs recurrentes, Repeat Purchase Rate %
-- TABLAS: SalesOrderHeader
-- NOTA: Cliente nuevo = primer año de compra coincide con el año de la orden
--       Cliente recurrente = ya compró en años anteriores
-- Hallazgo: El Repeat Purchase Rate creció del 6.36% en 2012 al 41.84% en 2014
--           La base de clientes leales se está consolidando año a año
--           2013 fue el año de mayor captación con 8,730 clientes nuevos
-- ============================================================

WITH primera_compra AS (
	SELECT
		CustomerID,
		MIN(orderDate) AS fecha_alta
	FROM
		Sales.SalesOrderHeader AS oh
	GROUP BY
		CustomerID
),

clasificacion AS (
	SELECT
		oh.CustomerID AS cliente,
		YEAR(oh.OrderDate) AS year,
		CASE
			WHEN YEAR(oh.OrderDate) = YEAR(fecha_alta) THEN 'Nuevo'
			ELSE 'Recurrente'
		END AS clasificacion_cliente
	FROM
		primera_compra AS c
	INNER JOIN
		Sales.SalesOrderHeader AS oh
			ON c.CustomerID = oh.CustomerID
	GROUP BY
		oh.CustomerID,
		YEAR(oh.OrderDate),
		YEAR(fecha_alta),
		CASE
			WHEN YEAR(oh.OrderDate) = YEAR(fecha_alta) THEN 'Nuevo'
			ELSE 'Recurrente'
		END
)

SELECT
	year,
	clasificacion_cliente,
	COUNT(DISTINCT cliente) AS num_clientes,
	 CAST(
        COUNT(DISTINCT cliente) * 1.0 / 
        SUM(COUNT(DISTINCT cliente)) OVER(PARTITION BY year) * 100
    AS DECIMAL(5,2)) AS repeat_purchase_rate
FROM
	clasificacion
GROUP BY
	year,
	clasificacion_cliente
ORDER BY
	year ASC;