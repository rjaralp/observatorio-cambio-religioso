# Ejecutar desde la raíz del proyecto. La salida contiene solo agregados.
library(dplyr)

n_minimo <- 30L
religiones_validas <- c("Católica", "Evangélica", "Otras religiones", "Sin religión")
indicadores_principales <- c("Católica", "Sin religión")

leer_encuesta <- function(archivo, nombre, anio, ponderador) {
  datos <- readRDS(file.path("datos", "processed", archivo))

  tibble(
    encuesta = nombre,
    anio = as.integer(unclass(datos[[anio]])),
    peso = as.numeric(unclass(datos[[ponderador]])),
    # Usar la misma recodificación de la limpieza que usa el explorador.
    religion = as.character(datos$religion_cat),
    edad = as.numeric(unclass(datos$edad)),
    sexo = c("Hombres", "Mujeres")[match(unclass(datos$sexo), c(1, 2))]
  ) |>
    filter(!is.na(anio), is.finite(peso), peso > 0, religion %in% religiones_validas) |>
    mutate(
      edad = if_else(is.finite(edad) & edad >= 18, edad, NA_real_),
      grupo_etario = cut(
        edad, breaks = c(18, 30, 45, 60, Inf),
        labels = c("18–29", "30–44", "45–59", "60 o más"), right = FALSE
      ),
      cohorte = cut(
        anio - edad, breaks = c(1928, 1965, 1981, 2013),
        labels = c("Silenciosa + Boomers", "Generación X", "Millennials + Generación Z"),
        right = FALSE
      )
    )
}

estimar <- function(datos) {
  datos |>
    filter(!is.na(grupo)) |>
    group_by(encuesta, anio, grupo) |>
    filter(n() >= n_minimo) |>
    mutate(n_total = n(), peso_total = sum(peso)) |>
    group_by(indicador = religion, .add = TRUE) |>
    summarise(
      valor = 100 * sum(peso) / first(peso_total),
      n = first(n_total),
      n_indicador = n(),
      .groups = "drop"
    )
}

publicables <- function(estimaciones, indicadores) {
  estimaciones |>
    filter(indicador %in% indicadores, n_indicador >= n_minimo, n - n_indicador >= n_minimo)
}

ultimo_anio <- function(estimaciones) {
  estimaciones |>
    group_by(encuesta) |>
    filter(anio == max(anio)) |>
    ungroup()
}

con_historia <- function(estimaciones, id, unidad = "%") {
  estimaciones |>
    mutate(historia = id, unidad = unidad) |>
    select(historia, encuesta, anio, grupo, indicador, valor, unidad, n)
}

base <- bind_rows(
  leer_encuesta("cep_clean.rds", "CEP", "encuesta_a", "pond"),
  leer_encuesta("bicentenario_clean.rds", "Bicentenario UC", "ano", "ponderador")
) |>
  # Usar la misma partición de afiliaciones en las dos encuestas.
  mutate(religion = if_else(religion %in% indicadores_principales, religion, "Otras afiliaciones"))

anios <- base |>
  distinct(encuesta, anio) |>
  arrange(encuesta, anio) |>
  group_by(encuesta) |>
  mutate(indice_anio = row_number()) |>
  ungroup()

# La cohorte más joven agrupa 1981–2012: Gen Z sola tiene menos de 30
# respuestas de otras afiliaciones en CEP 2021. Omitir la barra entera
# si alguna de sus partes queda bajo el umbral.
composicion <- base |>
  mutate(grupo = as.character(cohorte)) |>
  estimar() |>
  group_by(encuesta, anio, grupo) |>
  filter(n() == 3L, all(n_indicador >= n_minimo)) |>
  ungroup() |>
  ultimo_anio()

jovenes <- base |>
  filter(grupo_etario == "18–29") |>
  mutate(grupo = "") |>
  estimar() |>
  publicables("Católica")

sexo <- base |>
  mutate(grupo = sexo) |>
  estimar() |>
  publicables(indicadores_principales)

edad <- base |>
  mutate(grupo = as.character(grupo_etario)) |>
  estimar() |>
  publicables("Sin religión") |>
  ultimo_anio()

historico <- base |>
  mutate(grupo = "") |>
  estimar() |>
  publicables(indicadores_principales)

brecha <- historico |>
  group_by(encuesta, anio, grupo, n) |>
  filter(n() == length(indicadores_principales)) |>
  summarise(
    valor = valor[indicador == "Católica"] - valor[indicador == "Sin religión"],
    .groups = "drop"
  ) |>
  mutate(indicador = "Brecha")

anios_comunes <- brecha |>
  count(anio, name = "fuentes") |>
  filter(fuentes == n_distinct(base$encuesta)) |>
  arrange(anio) |>
  pull(anio)

estimaciones <- bind_rows(
  con_historia(composicion, "composicion-generacional"),
  con_historia(jovenes, "catolicismo-joven"),
  con_historia(sexo, "brecha-genero"),
  con_historia(edad, "no-afiliacion-edad"),
  con_historia(historico, "brecha-catolicismo"),
  con_historia(brecha, "brecha-catolicismo", "pp"),
  historico |>
    filter(anio %in% anios_comunes) |>
    con_historia("comparacion-encuestas")
) |>
  left_join(anios, by = c("encuesta", "anio")) |>
  mutate(indice_anio = if_else(
    historia == "comparacion-encuestas", match(anio, anios_comunes), indice_anio
  )) |>
  group_by(historia, encuesta, grupo, indicador) |>
  arrange(anio, .by_group = TRUE) |>
  mutate(tramo = cumsum(row_number() == 1L | indice_anio - lag(indice_anio, default = 0L) > 1L)) |>
  ungroup() |>
  select(-indice_anio)

salida <- file.path("analisis", "editoriales")
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
write.csv(
  estimaciones, file.path(salida, "estimaciones.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
