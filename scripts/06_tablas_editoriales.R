here::i_am("scripts/06_tablas_editoriales.R")

estimaciones <- read.csv(
  here::here("analisis", "editoriales", "estimaciones.csv"),
  fileEncoding = "UTF-8"
)

fichas <- list(
  "composicion-generacional" = list(
    tema = "por generación",
    grupo = "Generación",
    orden_grupo = c("Silenciosa + Boomers", "Generación X", "Millennials + Generación Z"),
    indicadores = c("Católica", "Otras afiliaciones", "Sin religión")
  ),
  "catolicismo-joven" = list(
    tema = "de catolicismo entre jóvenes",
    grupo = NULL,
    indicadores = "Católica"
  ),
  "brecha-genero" = list(
    tema = "por sexo registrado",
    grupo = "Sexo registrado",
    orden_grupo = c("Hombres", "Mujeres"),
    indicadores = c("Católica", "Sin religión")
  ),
  "no-afiliacion-edad" = list(
    tema = "por grupo etario",
    grupo = "Grupo etario",
    orden_grupo = c("18–29", "30–44", "45–59", "60 o más"),
    indicadores = "Sin religión"
  ),
  "brecha-catolicismo" = list(
    tema = "de la brecha histórica",
    grupo = NULL,
    indicadores = c("Católica", "Sin religión", "Brecha")
  ),
  "comparacion-encuestas" = list(
    tema = "de los años comunes",
    grupo = NULL,
    indicadores = c("Católica", "Sin religión")
  )
)

destino <- here::here("analisis", "_tablas-editoriales")
dir.create(destino, recursive = TRUE, showWarnings = FALSE)

escribir_tabla <- function(historia, ficha) {
  claves <- c("encuesta", "anio", if (!is.null(ficha$grupo)) "grupo")
  base <- estimaciones[estimaciones$historia == historia, ]
  tabla <- tidyr::pivot_wider(
    base[, c(claves, "n", "indicador", "valor")],
    names_from = indicador,
    values_from = valor
  )
  tabla <- tabla[, c(claves, ficha$indicadores, "n")]
  orden_encuesta <- match(tabla$encuesta, c("CEP", "Bicentenario UC"))
  orden_grupo <- if (is.null(ficha$grupo)) seq_len(nrow(tabla)) else match(tabla$grupo, ficha$orden_grupo)
  tabla <- tabla[order(orden_encuesta, tabla$anio, orden_grupo), ]

  tiene_omisiones <- anyNA(tabla[, ficha$indicadores])
  for (indicador in ficha$indicadores) {
    cifras <- tabla[[indicador]]
    tabla[[indicador]] <- ifelse(
      is.na(cifras), "—", formatC(cifras, digits = 1, format = "f", decimal.mark = ",")
    )
  }
  tabla$n <- formatC(tabla$n, format = "d", big.mark = ".", decimal.mark = ",")

  cabeceras <- c(
    "Encuesta", "Año", ficha$grupo,
    ifelse(ficha$indicadores == "Brecha", "Diferencia (pp)", paste0(ficha$indicadores, " (%)")),
    "Casos válidos (n)"
  )
  atributos <- ifelse(seq_along(cabeceras) > length(claves), ' class="editorial-cifra"', "")
  celda <- function(etiqueta, atributo, valor) {
    paste0("<", etiqueta, atributo, ">", htmltools::htmlEscape(valor), "</", etiqueta, ">")
  }
  cabecera <- celda("th", paste0(' scope="col"', atributos), cabeceras)
  encabezado_fila <- if (is.null(ficha$grupo)) 2L else 3L
  etiquetas <- rep("td", length(cabeceras))
  etiquetas[encabezado_fila] <- "th"
  atributos[encabezado_fila] <- ' scope="row"'
  filas <- vapply(seq_len(nrow(tabla)), function(i) {
    celdas <- celda(etiquetas, atributos, as.character(unlist(tabla[i, ])))
    paste0("      <tr>", paste0(celdas, collapse = ""), "</tr>")
  }, character(1))

  id <- paste0("tabla-", historia, "-titulo")
  contenido <- c(
    '```{=html}',
    '<!-- Generado por scripts/06_tablas_editoriales.R. -->',
    '<details class="editorial-tabla">',
    paste0("  <summary>Ver tabla ", ficha$tema, "</summary>"),
    paste0('  <div class="editorial-tabla-contenedor" role="region" tabindex="0" aria-labelledby="', id, '">'),
    '  <table data-quarto-disable-processing="true">',
    paste0('    <caption id="', id, '">Estimaciones ponderadas ', ficha$tema, "</caption>"),
    paste0("    <thead><tr>", paste0(cabecera, collapse = ""), "</tr></thead>"),
    "    <tbody>",
    filas,
    "    </tbody>",
    "  </table>",
    "  </div>",
    if (tiene_omisiones) '  <p class="editorial-tabla-nota">— Estimación omitida por falta de casos.</p>',
    "</details>",
    '```'
  )
  writeLines(enc2utf8(contenido), file.path(destino, paste0(historia, ".qmd")), useBytes = TRUE)
}

for (historia in names(fichas)) {
  escribir_tabla(historia, fichas[[historia]])
}
