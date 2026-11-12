# Respuestas conceptuales

## 1. ¿Por qué usar `_loaded_at` y no `fecha_venta` para este control?

Porque el control quiere saber si la carga está al día, no cuándo ocurrieron las ventas.

## 2. ¿Por qué las pruebas de integridad no garantizan actualidad?

Porque revisan cómo son los datos presentes, no cuándo llegaron.
