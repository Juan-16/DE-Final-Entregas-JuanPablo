variable "region" {
  description = "Región de AWS del despliegue"
  type        = string
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Prefijo de nombres y etiquetas"
  type        = string
  default     = "de-final-entregas"
}

variable "nombre_bucket" {
  description = "Nombre del bucket. Vacío = <proyecto>-<cuenta>-<región> (único a nivel global)"
  type        = string
  default     = ""
}

variable "forzar_eliminacion_bucket" {
  description = "Permite que terraform destroy elimine el bucket aunque contenga datos y resultados"
  type        = bool
  default     = true
}

variable "nombre_base_datos" {
  description = "Base de datos de Glue Data Catalog"
  type        = string
  default     = "entregas_db"
}

variable "nombre_tabla" {
  description = "Tabla externa de intentos de entrega"
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Workgroup de Athena del ejercicio"
  type        = string
  default     = "entregas-wg"
}

variable "fecha_inicio" {
  description = "Primera fecha proyectada (incluida), formato yyyy-MM-dd"
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin" {
  description = "Última fecha proyectada (incluida), formato yyyy-MM-dd"
  type        = string
  default     = "2026-10-03"
}
