here::i_am("scripts/03_datos_explorador.R")

library(dplyr)

n_minimo <- 30L

categorias <- tibble::tribble(
  ~id,            ~label,             ~color,
  "catolica",     "Católica",         "#F8766D",
  "evangelica",   "Evangélica",       "#7CAE00",
  "otras",        "Otras religiones", "#00BFC4",
  "sin-religion", "Sin religión",     "#C77CFF"
)

grupos_edad <- tibble::tribble(
  ~id,      ~label,
  "18-29",  "18 a 29 años",
  "30-44",  "30 a 44 años",
  "45-59",  "45 a 59 años",
  "60-mas", "60 años o más"
)

grupos_cohorte <- tibble::tribble(
  ~id,                  ~label,
  "silenciosa-boomers", "Silenciosa + Boomers",
  "generacion-x",       "Generación X",
  "millennials",        "Millennials",
  "generacion-z",       "Generación Z"
)

grupos_sexo <- tibble::tribble(
  ~id,      ~label,  ~codigo,
  "hombre", "Hombre", 1,
  "mujer",  "Mujer",  2
)

resumir <- function(base, por = NULL) {
  if (is.null(por)) {
    grupos <- base |> group_by(year)
  } else {
    grupos <- base |>
      mutate(group = .data[[por]]) |>
      filter(!is.na(group)) |>
      group_by(year, group)
  }

  claves <- group_keys(grupos)
  grupos <- group_split(grupos)

  registros <- lapply(seq_along(grupos), function(i) {
    datos <- grupos[[i]]
    if (nrow(datos) < n_minimo) {
      return(NULL)
    }

    peso_total <- sum(datos$peso)
    partes <- lapply(categorias$id, function(id) {
      coincide <- datos$religion == id
      n <- sum(coincide)
      if (n < n_minimo) {
        return(list(id = id, pct = NA_real_, n = NA_integer_))
      }

      list(
        id = id,
        pct = 100 * sum(datos$peso[coincide]) / peso_total,
        n = n
      )
    })

    c(as.list(claves[i, ]), list(n = nrow(datos), parts = partes))
  })

  Filter(Negate(is.null), registros)
}

preparar_encuesta <- function(id, etiqueta, anio, peso, etiqueta_peso, metodo) {
  archivo <- here::here("datos", "processed", paste0(id, "_clean.rds"))
  columnas <- c(anio, peso, "religion_cat", "edad", "sexo")
  datos <- readRDS(archivo)[columnas]

  base <- tibble::tibble(
    year = datos[[anio]],
    peso = as.numeric(datos[[peso]]),
    religion = categorias$id[match(datos$religion_cat, categorias$label)],
    edad = as.numeric(datos$edad),
    sexo = grupos_sexo$id[match(unclass(datos$sexo), grupos_sexo$codigo)]
  ) |>
    filter(is.finite(year), !is.na(religion), is.finite(peso), peso > 0) |>
    mutate(
      cohorte = cut(
        year - if_else(edad >= 18, edad, NA_real_),
        breaks = c(1928, 1965, 1981, 1997, 2013),
        labels = grupos_cohorte$id,
        right = FALSE
      ),
      edad = cut(
        edad,
        breaks = c(18, 30, 45, 60, Inf),
        labels = grupos_edad$id,
        right = FALSE
      )
    )

  list(
    id = id,
    label = etiqueta,
    source = paste0("Fuente: ", etiqueta, ". Observatorio del Cambio Religioso en Chile (OCRC)."),
    weighted = TRUE,
    weight = peso,
    weightLabel = etiqueta_peso,
    method = metodo,
    years = sort(unique(base$year)),
    validResponses = nrow(base),
    views = list(
      tendencia = resumir(base),
      edad = resumir(base, "edad"),
      sexo = resumir(base, "sexo"),
      cohorte = resumir(base, "cohorte")
    )
  )
}

encuestas <- list(
  preparar_encuesta(
    "cep", "Encuesta CEP", "encuesta_a", "pond", "BASE PONDERADA",
    "Porcentajes ponderados con el factor pond de la base consolidada. Se agrupan los levantamientos con respuestas válidas del mismo año."
  ),
  preparar_encuesta(
    "bicentenario", "Encuesta Bicentenario UC", "ano", "ponderador", "Ponderador",
    "Porcentajes ponderados con el factor ponderador de la base consolidada."
  )
)

explorador <- list(
  minCases = n_minimo,
  categories = categorias,
  groups = list(
    edad = grupos_edad,
    sexo = select(grupos_sexo, id, label),
    cohorte = grupos_cohorte
  ),
  surveys = encuestas
)

jsonlite::write_json(
  explorador,
  here::here("analisis", "datos-explorador.json"),
  auto_unbox = TRUE,
  na = "null",
  digits = 4
)
