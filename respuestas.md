# Respuestas conceptuales

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla `entregas_db.entregas` no depende de particiones registradas en el catálogo. Usa **partition projection**. En las propiedades de la tabla (`infraestructura/principal.tf`) quedaron las reglas para *calcular* las particiones:

- `projection.fecha.type = date`, `projection.fecha.format = yyyy-MM-dd`
- `projection.fecha.range = 2026-10-01,2026-10-03`, `projection.fecha.interval = 1`, `projection.fecha.interval.unit = DAYS`
- `storage.location.template = s3://<bucket>/entregas/fecha=${fecha}/`

Con esas reglas, cuando se ejecuta una consulta Athena genera en memoria los valores posibles de `fecha` (`2026-10-01`, `2026-10-02` y `2026-10-03`). Con la plantilla arma el prefijo de S3 de cada valor y lee los objetos que encuentre ahí. No consulta una lista de particiones en Glue. De hecho, `aws glue get-partitions` devuelve `0` antes y después de cargar el día 3.

El rango incluía el 2026-10-03 desde el despliegue inicial. En la etapa inicial ese prefijo estaba vacío y no aportaba filas: la proyección no crea archivos ni garantiza que haya datos, solo define dónde buscarlos. Al subir `s3://<bucket>/entregas/fecha=2026-10-03/entregas.csv`, la siguiente consulta ya lo encontró en la ubicación calculada.

Así lo muestra la evidencia:
- `resultados/final/verificacion_tercer_dia.csv` tiene los 6 registros del 2026-10-03.
- `resultados/final/verificacion_total_registros.csv` muestra 18 registros en total.
- `resultados/final/intentos_por_fecha_estado.csv` y `resultados/final/porcentaje_exito_por_fecha_ciudad.csv` incluyen el tercer día y coinciden con las referencias finales.
- Todo eso se obtuvo sin crawlers, sin `MSCK REPAIR TABLE`, sin `ALTER TABLE ADD PARTITION` y sin volver a aplicar Terraform. Los identificadores de las ejecuciones `final` están en `evidencias/ejecuciones_athena.csv`.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

**Resultado esperado:** el archivo quedaría guardado en `s3://<bucket>/entregas/fecha=2026-10-04/entregas.csv`, pero **Athena no lo mostraría**. El rango proyectado termina en `2026-10-03`, así que Athena nunca genera el valor `2026-10-04` y no lee ese prefijo:

- Las consultas agregadas seguirían devolviendo solo los días 1 a 3 (18 registros).
- Una consulta con `WHERE fecha = '2026-10-04'` devolvería 0 filas, sin error.

El dato existe en S3, pero queda fuera de lo que la tabla puede ver.

Registrar la partición a mano tampoco sirve. Cuando la proyección está habilitada, Athena ignora las particiones registradas en el catálogo para esa tabla.

**Qué modificar:** solo la regla del rango de la proyección, en Terraform, para que sea reproducible:

1. Ampliar la fecha final, por ejemplo con `terraform apply -var fecha_fin=2026-10-04`, o cambiar el valor por defecto de `fecha_fin` en `infraestructura/variables.tf` y aplicar. Esto actualiza `projection.fecha.range` a `2026-10-01,2026-10-04`. No se crean particiones ni se mueven datos.
2. Volver a ejecutar las consultas. El 2026-10-04 aparecería sin ningún otro paso, siempre que el archivo respete la ruta `entregas/fecha=yyyy-MM-dd/` y el mismo esquema de cinco columnas.

Para no tener que ampliar el rango cada día, se podría usar un rango relativo como `2026-10-01,NOW`. Así Athena proyectaría hasta la fecha actual en cada consulta, y los días nuevos se incorporarían solo con subir el archivo.
