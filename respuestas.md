# Respuestas conceptuales

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla `entregas_db.entregas` no depende de particiones registradas en el catálogos ya que usa partition projection.
En las propiedades de la tabla (`infraestructura/principal.tf`) quedan las reglas que se usan para calcular las particiones:

- `projection.fecha.type = date`, `projection.fecha.format = yyyy-MM-dd`
- `projection.fecha.range = 2026-10-01,2026-10-03`, `projection.fecha.interval = 1`, `projection.fecha.interval.unit = DAYS`
- `storage.location.template = s3://<bucket>/entregas/fecha=${fecha}/`

Con esas reglas, cuando se ejecuta una consulta Athena genera en memoria los valores posibles de `fecha` (`2026-10-01`, `2026-10-02` y `2026-10-03`). Con la plantilla arma el prefijo de S3 de cada valor y lee los objetos que encuentre ahí. No consulta una lista de particiones en Glue. De hecho, `aws glue get-partitions` devuelve `0` antes y después de cargar el día 3.

El rango incluía el 2026-10-03 desde el despliegue inicial. En la etapa inicial ese prefijo estaba vacío y no aportaba filas: la proyección no crea archivos ni garantiza que haya datos, solo define dónde buscarlos. Al subir `s3://<bucket>/entregas/fecha=2026-10-03/entregas.csv`, la siguiente consulta ya lo encontró en la ubicación calculada.


## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

el archivo quedaría guardado en `s3://<bucket>/entregas/fecha=2026-10-04/entregas.csv`, pero Athena no lo mostraría. El rango proyectado termina en `2026-10-03`, así que Athena nunca genera el valor `2026-10-04` y no lee ese prefijo:

- Las consultas agregadas seguirían devolviendo solo los días 1 a 3.
- Una consulta con `WHERE fecha = '2026-10-04'` devolvería 0 filas, sin error.

El dato existe en S3, pero queda fuera de lo que la tabla puede ver.

Registrar la partición a mano tampoco sirve. Cuando la proyección está habilitada, Athena ignora las particiones registradas en el catálogo para esa tabla.

Se debe modificar solo la regla del rango de la proyección en Terraform

1. Ampliar la fecha final, por ejemplo con `terraform apply -var fecha_fin=2026-10-04`, o cambiar el valor por defecto de `fecha_fin` en `infraestructura/variables.tf` y aplicar. Esto actualiza `projection.fecha.range` a `2026-10-01,2026-10-04`. No se crean particiones ni se mueven datos.
2. Volver a ejecutar las consultas. El 2026-10-04 aparecería sin ningún otro paso, siempre que el archivo respete la ruta `entregas/fecha=yyyy-MM-dd/` y el mismo esquema de cinco columnas.
