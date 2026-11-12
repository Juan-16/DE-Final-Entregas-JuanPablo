output "region" {
  description = "Región del despliegue"
  value       = var.region
}

output "bucket" {
  description = "Bucket S3 privado del ejercicio"
  value       = aws_s3_bucket.datos.bucket
}

output "bucket_arn" {
  description = "ARN del bucket"
  value       = aws_s3_bucket.datos.arn
}

output "ruta_datos" {
  description = "Prefijo de los CSV de entrada"
  value       = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_datos}"
}

output "ruta_resultados_athena" {
  description = "Prefijo donde Athena escribe los resultados"
  value       = aws_athena_workgroup.entregas.configuration[0].result_configuration[0].output_location
}

output "base_datos" {
  description = "Base de datos de Glue Data Catalog"
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla" {
  description = "Tabla externa con partition projection"
  value       = aws_glue_catalog_table.entregas.name
}

output "tabla_completa" {
  description = "Nombre calificado base_datos.tabla"
  value       = "${aws_glue_catalog_database.entregas.name}.${aws_glue_catalog_table.entregas.name}"
}

output "plantilla_ubicacion" {
  description = "Plantilla de ubicación de cada partición"
  value       = aws_glue_catalog_table.entregas.parameters["storage.location.template"]
}

output "rango_proyeccion" {
  description = "Rango de fechas proyectadas"
  value       = aws_glue_catalog_table.entregas.parameters["projection.fecha.range"]
}

output "workgroup" {
  description = "Workgroup de Athena"
  value       = aws_athena_workgroup.entregas.name
}
