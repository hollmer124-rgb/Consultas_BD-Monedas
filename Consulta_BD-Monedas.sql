-- Hollmer Moncada Florez
-- Damian Alejandro Moncada Sanchez

-- Parcial Bases de datos estructurados
WITH 
-- 1. Cantidad de países por moneda
PaisesPorMoneda AS (
    SELECT 
        IdMoneda,
        COUNT(Id) AS TotalPaises
    FROM Pais
    GROUP BY IdMoneda
),

-- 2. Última fecha registrada por moneda
UltimaFechaCambio AS (
    SELECT 
        IdMoneda,
        MAX(Fecha) AS UltimaFecha
    FROM CambioMoneda
    GROUP BY IdMoneda
),

-- 3. Último cambio registrado por moneda
UltimoCambioCTE AS (
    SELECT 
        cm.IdMoneda,
        cm.Fecha AS UltimaFecha,
        cm.Cambio AS UltimoCambio
    FROM CambioMoneda cm
    INNER JOIN UltimaFechaCambio ufc 
        ON cm.IdMoneda = ufc.IdMoneda 
       AND cm.Fecha = ufc.UltimaFecha
),

-- 4. Promedio y Desviación Estándar de los últimos 30 días
Estadisticas30Dias AS (
    SELECT 
        IdMoneda,
        AVG(Cambio) AS Promedio30Dias,
        STDEV(Cambio) AS DesviacionEstandar
    FROM CambioMoneda
    WHERE Fecha >= DATEADD(day, -30, (SELECT MAX(Fecha) FROM CambioMoneda))
    GROUP BY IdMoneda
)

-- Consulta final con los nombres de columna y lógica exacta de la imagen
SELECT 
    m.Id,
    m.Moneda,
    m.Sigla,
    ISNULL(p.TotalPaises, 0) AS TotalPaises,
    uc.UltimaFecha,
    uc.UltimoCambio,
    e.Promedio30Dias,
    CASE 
        WHEN e.DesviacionEstandar < 0.05 THEN 'Estable'
        WHEN e.DesviacionEstandar >= 0.05 AND e.DesviacionEstandar < 0.15 THEN 'Media volatilidad'
        WHEN e.DesviacionEstandar >= 0.15 THEN 'Alta volatilidad'
        ELSE 'Estable'
    END AS Volatilidad,
    RANK() OVER (ORDER BY ISNULL(p.TotalPaises, 0) DESC) AS RankingUso
FROM Moneda m
LEFT JOIN PaisesPorMoneda p ON m.Id = p.IdMoneda
LEFT JOIN UltimoCambioCTE uc ON m.Id = uc.IdMoneda
LEFT JOIN Estadisticas30Dias e ON m.Id = e.IdMoneda
ORDER BY TotalPaises DESC, m.Id ASC;