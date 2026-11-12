# Respuestas conceptuales

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?


porque la tabla de entregas no depende de particiones registradas en el catalago porque usa partition projection. y gracias a las reglass que se usan para calcular las particiones, cuando se ejecuta athena genera en memoria los valores posibles de fecha (2026-10-01, 2026-10-02 y 2026-10-03). Con la plantilla arma el prefijo de S3 de cada valor y lee los objetos que encuentre ahí. No consulta una lista de particiones en Glue. 

la proyección no crea archivos ni garantiza que haya datos, solo define dónde buscarlos. Al subir `s3://<bucket>/entregas/fecha=2026-10-03/entregas.csv`, la siguiente consulta ya lo encontró en la ubicación calculada.


## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

el archivo quedaria guardado en `s3://<bucket>/entregas/fecha=2026-10-04/entregas.csv`, pero Athena no lo mostraria porque el rango proyectado termina en 2026-10-03, por lo que Athena nunca genera el valor 2026-10-04 y no lee ese prefijo:

Se debe modificar solo la regla del rango de la proyección en Terraform, ampliando la fecha final.
