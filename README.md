# sales_analytics
Análisis de ventas con SQL avanzado
## Descripción
Análisis del rendimiento de ventas de AdventureWorks para identificar oportunidades 
de crecimiento, optimizar la estrategia comercial y mejorar la toma de decisiones 
basada en datos.

El proyecto responde 7 preguntas clave de negocio usando SQL avanzado sobre la base 
de datos AdventureWorks2022 de Microsoft SQL Server.

---

## Preguntas de negocio
1. ¿Qué productos y categorías generan más ingresos y margen?
2. ¿Cómo evolucionan las ventas en el tiempo?
3. ¿Qué territorios o regiones generan más ventas?
4. ¿Quiénes son los clientes más valiosos?
5. ¿Qué canales de venta son más rentables?
6. ¿Cómo es el ticket promedio y el comportamiento de compra?
7. ¿Qué patrones existen en el ciclo de ventas?

---

## Tecnologías
- Microsoft SQL Server 2022
- SQL Server Management Studio (SSMS)
- T-SQL

---

## Técnicas SQL utilizadas
- Window Functions — LAG, SUM OVER, PARTITION BY, DENSE_RANK
- CTEs encadenadas — hasta 3 CTEs en una sola query
- JOINs múltiples — hasta 4 tablas en una sola query
- Análisis Pareto — porcentaje acumulado con SUM OVER y ORDER BY
- CLV aproximado — revenue total / años de antigüedad
- Segmentación de clientes — nuevos vs recurrentes con lógica de primera compra

---

## Hallazgos principales

### Productos y margen
- **Bikes** lidera en revenue con $94M pero con márgenes moderados
- **Accessories** tiene el mayor profit margin — productos con bajo coste y buen precio
- **Road Frames** (-4.48%), **Jerseys** (-19.92%) y **Caps** (-12.30%) se venden 
  por debajo del coste de producción — se recomienda revisar estrategia de precios
- **Mountain-200 Black** es el producto estrella con $4.4M de revenue y 27.63% de margen

### Evolución temporal
- **2013** fue el año con mayor revenue acumulado anual
- **Junio 2012** registró el mayor crecimiento interanual
- El AOV cae de 2012 a 2013 — la captación masiva de clientes nuevos 
  trajo pedidos de menor valor medio

### Territorios
- **Southwest** lidera en revenue con la mayor contribución al total
- **Central** tiene el AOV más alto — menos clientes pero más valiosos por transacción
- Oportunidad: aumentar volumen en Central manteniendo su alto ticket medio

### Clientes más valiosos
- El **8.1% de los clientes (1,551 de 19,119)** genera el **80% del revenue** 
  — concentración mayor que la regla 80/20 típica
- El cliente más valioso acumula **$989,184** en revenue histórico
- Retener a estos 1,551 clientes es la prioridad estratégica número 1

### Canales de venta
- **Tienda** genera el **73.67% del revenue** con AOV de $23,850
- **Online** tiene 7 veces más pedidos pero AOV de solo $1,172
- Los pedidos de tienda corresponden a empresas y distribuidores que compran en volumen
- Oportunidad: aumentar el ticket medio del canal online

### Comportamiento de compra
- El **61% de los clientes (11,649)** solo compra una vez — 
  oportunidad de mejora en retención y fidelización
- Solo **1,997 clientes** (10.4%) realizan 3 o más compras
- Convertir el 10% de los clientes de una sola compra en recurrentes 
  tendría un impacto significativo en el revenue

### Ciclo de ventas
- El **Repeat Purchase Rate** creció del **6.36% en 2012** al **41.84% en 2014**
- La base de clientes leales se está consolidando año a año
- **2013** fue el año de mayor captación con **8,730 clientes nuevos**
- Si la tendencia continúa, en 2015 más de la mitad de los clientes serían recurrentes

---

## Conclusiones y recomendaciones

**1. Revisar precios de Road Frames y Jerseys** — se venden con margen negativo. 
Subir precios o reducir costes de producción es urgente.

**2. Programa de fidelización** — el 61% de clientes solo compra una vez. 
Implementar campañas de retención para convertirlos en recurrentes.

**3. Proteger a los 1,551 clientes top** — generan el 80% del revenue. 
Un programa VIP con atención personalizada reduciría el riesgo de churn.

**4. Potenciar el canal tienda** — AOV 20 veces superior al online. 
Invertir en el equipo de ventas directo tiene mayor retorno que el canal digital.

**5. Estrategia en Central** — tiene el AOV más alto de todos los territorios. 
Aumentar la base de clientes en ese territorio mejoraría el revenue global.

---

## Autor
Jorge Torres  
[GitHub](#)
