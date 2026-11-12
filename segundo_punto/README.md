# Segundo punto: ventas diarias con control de actualidad (dbt + Airflow local)

Repositorio base: https://github.com/smm-0216/DE-Final-Ventas (entorno Docker del docente: Airflow 2.10.5, dbt 1.9.4, dbt-duckdb).

## Archivos modificados (únicos tres permitidos)
- `dbt/models/ventas_diarias.sql`: una fila por `fecha_venta` con `numero_ventas`, `unidades_vendidas` e `ingreso_total` (DECIMAL(18,2)), usando `ref('stg_ventas')`.
- `dbt/models/sources.yml`: `loaded_at_field: _loaded_at` y `freshness` (warn > 12 h, error > 24 h) en la tabla `ventas_raw.ventas`.
- `airflow/dags/examen_ventas.py`: nueva tarea `comprobar_freshness` (`run_dbt(["source", "freshness"])`) con la dependencia `comprobar_freshness >> construir_resumen` y la regla por defecto `all_success`.

## Comprobación del modelo
`dbt build`: PASS=19 WARN=0 ERROR=0.

| fecha_venta | numero_ventas | unidades_vendidas | ingreso_total |
|---|---:|---:|---:|
| 2026-01-10 | 2 | 3 | 46.00 |
| 2026-01-11 | 3 | 6 | 51.25 |
| 2026-01-12 | 1 | 4 | 12.40 |

## Ejecuciones obligatorias
| Escenario | run_id | comprobar_freshness | construir_resumen |
|---|---|---|---|
| actualizada (carga hace ~2 h) | manual__2026-11-12T12:04:58.462362+00:00 | success (PASS) | success |
| desactualizada (carga hace ~30 h) | manual__2026-11-12T12:07:51.927689+00:00 | failed (ERROR STALE) | upstream_failed (no se ejecutó) |

## Evidencias (`evidencias/`)
- `estados_actualizada.txt` y `estados_desactualizada.txt`: estados de las tareas por run_id.
- `log_airflow_freshness_desactualizada.txt`: log de Airflow de la tarea (INICIO dbt y salida con código 1).
- `log_dbt_freshness_desactualizada.txt`: salida de dbt con el motivo, `ERROR STALE freshness of ventas_raw.ventas`. `run_dbt` ejecuta dbt como subproceso, así que esta salida queda en los logs del contenedor (`docker compose logs airflow`) y no en el log de la tarea.
- `artifacts_desactualizada.txt`: `sources.json` con `"status": "error"` y la antigüedad de `_loaded_at`.
- `build_no_ejecutado.txt`: la ejecución desactualizada solo tiene log de `comprobar_freshness`; build no tuvo intentos.
- `resumen_antes_del_bloqueo.txt` y `resumen_despues_del_bloqueo.txt`: mismas filas, el resumen anterior se conservó.

## Capturas
- `capturas/capturas_airflow.docx`: run_id y estados de ambas ejecuciones, y log de la tarea de freshness fallida.

## Respuestas
Ver `respuestas.md`.
