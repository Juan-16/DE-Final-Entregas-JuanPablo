# Infraestructura del ejercicio: S3 -> Glue Data Catalog (partition projection) -> Athena
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Proyecto  = var.proyecto
      Ejercicio = "entregas-partition-projection"
    }
  }
}

data "aws_caller_identity" "actual" {}

locals {
  # Nombre global único: <proyecto>-<cuenta>-<región>, o el que se indique en var.nombre_bucket
  nombre_bucket      = var.nombre_bucket != "" ? var.nombre_bucket : "${var.proyecto}-${data.aws_caller_identity.actual.account_id}-${var.region}"
  prefijo_datos      = "entregas/"
  prefijo_resultados = "resultados-athena/"
}

# ---------------------------------------------------------------- 1 y 2. Bucket S3 privado
# Los prefijos entregas/ y resultados-athena/ son parte de las claves de los objetos:
# no se crean carpetas, aparecen al subir los CSV y al ejecutar consultas.
resource "aws_s3_bucket" "datos" {
  bucket        = local.nombre_bucket
  force_destroy = var.forzar_eliminacion_bucket
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket                  = aws_s3_bucket.datos.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "datos" {
  bucket = aws_s3_bucket.datos.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datos" {
  bucket = aws_s3_bucket.datos.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------- 3. Base de datos de Glue
resource "aws_glue_catalog_database" "entregas" {
  name        = var.nombre_base_datos
  description = "Catalogo del ejercicio de intentos de entrega"
}

# ---------------------------------------------------------------- 4. Tabla externa con partition projection
resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  description   = "Intentos de entrega (CSV) particionados por fecha con partition projection"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    classification           = "csv"
    "skip.header.line.count" = "1" # omite el encabezado de cada archivo

    # Partition projection: Athena calcula valores y ubicaciones de las particiones con estas reglas
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio},${var.fecha_fin}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"
    # Prefijo de cada partición, terminado en "/". "$${fecha}" queda escrito literal como ${fecha}.
    "storage.location.template" = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_datos}fecha=$${fecha}/"
  }

  # fecha NO es columna del CSV: es la clave de partición, de tipo texto
  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_datos}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    # Las cinco columnas del diccionario, en el orden del archivo
    columns {
      name = "id_envio"
      type = "string"
    }
    columns {
      name = "ciudad"
      type = "string"
    }
    columns {
      name = "transportadora"
      type = "string"
    }
    columns {
      name = "estado"
      type = "string"
    }
    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# ---------------------------------------------------------------- 5. Workgroup de Athena
resource "aws_athena_workgroup" "entregas" {
  name          = var.nombre_workgroup
  description   = "Workgroup del ejercicio de entregas"
  force_destroy = true # permite eliminarlo aunque tenga historial de consultas

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_resultados}"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
