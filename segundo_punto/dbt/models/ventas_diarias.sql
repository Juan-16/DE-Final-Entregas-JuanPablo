-- Resumen diario de ventas: una fila por fecha_venta.
-- ingreso_total conserva la precisión decimal (cantidad INTEGER * precio_unitario DECIMAL(12,2)).
select
    fecha_venta,
    count(*)                                          as numero_ventas,
    sum(cantidad)                                     as unidades_vendidas,
    cast(sum(cantidad * precio_unitario) as decimal(18, 2)) as ingreso_total
from {{ ref('stg_ventas') }}
group by fecha_venta
