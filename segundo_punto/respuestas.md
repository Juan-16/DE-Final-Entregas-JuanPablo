# Respuestas conceptuales

## 1. ¿Por qué usar `_loaded_at` y no `fecha_venta` para este control?

Porque el control quiere saber si **la carga** está al día, no cuándo ocurrieron las ventas.

- `_loaded_at` es el instante en que los registros llegaron a `raw.ventas`. Si su máximo tiene más de 24 horas, la carga se detuvo o se retrasó, y el resumen se construiría con información vieja. Eso es justo lo que hay que detectar antes del `dbt build`.
- `fecha_venta` es una fecha del negocio. Una venta antigua puede cargarse hoy (por ejemplo, un dato que llega tarde o una corrección), y un día sin ventas, como un festivo, no significa que la carga haya fallado. Medir con `fecha_venta` daría falsos errores y falsos aciertos.

La evidencia del ejercicio lo muestra. Los tres escenarios conservan exactamente las mismas fechas de negocio (2026-01-10 a 2026-01-12, hace meses) y solo cambian `_loaded_at` (hace 2, 18 y 30 horas). Con `fecha_venta` los tres darían error, aunque la carga de "actualizada" sea de hace 2 horas. Con `_loaded_at` el resultado es el correcto: `pass`, `warn` y `error`.

## 2. ¿Por qué las pruebas de integridad no garantizan actualidad?

Porque revisan **cómo son** los datos presentes, no **cuándo llegaron**.

`unique`, `not_null` y `valores_ventas` comprueban que no haya ventas duplicadas, que no falten campos y que cantidades y precios sean válidos. Una carga de hace 30 horas cumple todas esas reglas igual que una de hace 2 horas: los datos son correctos, solo que viejos. Por eso el proceso puede "terminar sin errores técnicos" y aun así reconstruir el resumen con información desactualizada.

En el ejercicio, `dbt build` pasa sus 19 pruebas con cualquiera de los escenarios, porque los datos de negocio son los mismos. Además, `dbt build` no ejecuta freshness por sí mismo. Por eso hace falta la tarea `comprobar_freshness` antes de `construir_resumen`. En la ejecución desactualizada, freshness quedó `failed` (`ERROR STALE`) y el build quedó `upstream_failed` sin ejecutarse, así que el resumen anterior se conservó.
