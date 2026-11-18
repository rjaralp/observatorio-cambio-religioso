# Ejecutar después de scripts/04_datos_editoriales.R desde la raíz del proyecto.
library(ggplot2)
library(dplyr)

if (!all(capabilities(c("cairo", "png")))) {
  stop("Para exportar los gráficos se necesita R con soporte para Cairo y PNG.")
}

carpeta_web <- file.path("analisis", "editoriales")
carpeta_difusion <- file.path("difusion", "linkedin")
estimaciones <- read.csv(
  file.path(carpeta_web, "estimaciones.csv"), fileEncoding = "UTF-8",
  stringsAsFactors = FALSE
)
dir.create(carpeta_difusion, recursive = TRUE, showWarnings = FALSE)

papel <- "#F7F5EF"
tinta <- "#102B40"
texto_secundario <- "#4E6069"
marca <- "#7B0000"
trama <- "#DEDAD0"
encuestas <- c("CEP", "Bicentenario UC")
afinidades <- c("Católica", "Sin religión")
cohortes <- c("Silenciosa + Boomers", "Generación X", "Millennials + Generación Z")
edades <- c("18–29", "30–44", "45–59", "60 o más")
porcentaje <- scales::label_number(accuracy = 1, decimal.mark = ",", suffix = "%")
porcentaje_decimal <- scales::label_number(accuracy = 0.1, decimal.mark = ",", suffix = "%")
puntos <- function(x) {
  signo <- ifelse(round(x) < 0, "−", ifelse(round(x) > 0, "+", ""))
  paste0(signo, round(abs(x)), " pp")
}
puntos_decimal <- function(x) {
  valor <- scales::number(abs(x), accuracy = 0.1, decimal.mark = ",")
  signo <- ifelse(round(x, 1) < 0, "−", ifelse(round(x, 1) > 0, "+", ""))
  paste0(signo, valor, " pp")
}

clave <- function(color, tipo = "solid", figura = 16) {
  data.frame(
    etiqueta = names(color), color = unname(color), tipo = tipo, figura = figura,
    stringsAsFactors = FALSE
  )
}

clave_religion <- clave(
  c("Católica" = marca, "Sin religión" = "#215C72"), c("solid", "longdash"), c(16, 17)
)
clave_composicion <- clave(c("Católica" = marca, "Otras afiliaciones" = "#5D6961",
                            "Sin religión" = "#215C72"))
clave_encuesta <- clave(
  c("CEP" = "#573369", "Bicentenario UC" = "#1E6050"),
  c("solid", "longdash"), c(16, 17)
)
clave_sexo <- clave(
  c("Hombres" = "#27577C", "Mujeres" = "#914131"),
  c("solid", "longdash"), c(16, 17)
)
clave_brecha <- clave(c("Brecha" = "#303D58"))

periodo <- function(d) {
  detalle <- d |>
    group_by(encuesta) |>
    summarise(inicio = min(anio), fin = max(anio), .groups = "drop") |>
    arrange(match(encuesta, encuestas))
  rangos <- ifelse(detalle$inicio == detalle$fin, detalle$fin,
                   paste(detalle$inicio, detalle$fin, sep = "–"))
  paste(paste(detalle$encuesta, rangos), collapse = "  ·  ")
}

ultimo <- function(d) {
  anios <- unique(d$anio)
  stopifnot(length(anios) == 1L)
  anios[[1L]]
}

tema_ocrc <- function() {
  theme_minimal(base_family = "sans", base_size = 14) +
    theme(
      plot.background = element_rect(fill = papel, color = NA),
      panel.grid.major = element_line(color = trama, linewidth = 0.33),
      panel.grid.minor = element_blank(),
      axis.text = element_text(color = texto_secundario, size = 12),
      axis.title = element_blank(),
      plot.title = element_text(color = tinta, size = 14, face = "bold", margin = margin(b = 7)),
      plot.margin = margin(5, 3, 7, 2),
      plot.title.position = "plot",
      legend.position = "none"
    )
}

barras_composicion <- function(d, fuente, etiquetas_grandes) {
  panel <- d |>
    filter(encuesta == fuente) |>
    mutate(
      grupo = factor(grupo, levels = rev(cohortes)),
      indicador = factor(indicador, levels = clave_composicion$etiqueta)
    ) |>
    arrange(indicador) |>
    group_by(grupo) |>
    mutate(medio = cumsum(valor) - valor / 2) |>
    ungroup()

  ggplot(panel, aes(x = valor, y = grupo, fill = indicador)) +
    geom_col(orientation = "y", width = 0.64, position = position_stack(reverse = TRUE)) +
    geom_text(
      data = filter(panel, valor >= 13), aes(x = medio, label = porcentaje_decimal(valor)),
      color = "white", fontface = "bold", size = if (etiquetas_grandes) 4.2 else 4.0
    ) +
    scale_fill_manual(values = setNames(clave_composicion$color, clave_composicion$etiqueta)) +
    scale_x_continuous(breaks = seq(0, 100, 25), labels = porcentaje,
                       expand = expansion(mult = c(0, 0.022))) +
    scale_y_discrete(labels = c("Silenciosa + Boomers" = "Silenciosa\n+ Boomers",
                                "Generación X" = "Generación X",
                                "Millennials + Generación Z" = "Millennials\n+ Generación Z")) +
    labs(title = paste(fuente, ultimo(panel))) +
    tema_ocrc() +
    theme(axis.text.y = element_text(color = tinta, lineheight = 0.92),
          panel.grid.major.y = element_blank())
}

barras_edad <- function(d, fuente, escala) {
  panel <- d |>
    filter(encuesta == fuente) |>
    mutate(grupo = factor(grupo, levels = rev(edades)))

  ggplot(panel, aes(x = valor, y = grupo)) +
    geom_col(orientation = "y", width = 0.58, fill = clave_religion$color[2]) +
    geom_text(aes(label = porcentaje(valor)), hjust = -0.19, size = 4.2,
              fontface = "bold", color = clave_religion$color[2]) +
    scale_x_continuous(breaks = seq(0, escala, 20), labels = porcentaje,
                       limits = c(0, escala), expand = expansion(add = c(0, escala * 0.12))) +
    labs(title = paste(fuente, ultimo(panel))) +
    tema_ocrc() +
    theme(axis.text.y = element_text(color = tinta), panel.grid.major.y = element_blank())
}

ubicacion_etiquetas <- function(datos, limites) {
  etiqueta <- datos |>
    group_by(serie) |>
    slice_max(anio, n = 1, with_ties = FALSE) |>
    ungroup() |>
    arrange(valor)
  alto <- diff(limites)
  centro <- pmin(pmax(etiqueta$valor, limites[1] + 0.04 * alto), limites[2] - 0.04 * alto)
  espaciado <- 0.13 * alto

  for (i in seq_along(centro)[-1]) {
    centro[i] <- max(centro[i], centro[i - 1] + espaciado)
  }

  etiqueta$ubicacion <- centro - max(0, max(centro) - limites[2] + 0.04 * alto)
  etiqueta
}

serie_temporal <- function(d, variable, clave, fechas, y, titulo_panel = NULL, unidad = "%") {
  series <- mutate(d, serie = .data[[variable]])
  curvas <- series |> group_by(serie, tramo) |> filter(n() > 1) |> ungroup()
  etiquetas <- ubicacion_etiquetas(series, y)
  es_brecha <- unidad == "pp"
  amplitud <- max(diff(fechas), 1)
  separacion <- amplitud * 0.042
  etiquetas <- etiquetas |>
    mutate(anio_rotulo = if (variable == "encuesta") fechas[2] else anio)
  ticks_x <- pretty(fechas, n = 4)
  ticks_x <- ticks_x[ticks_x >= fechas[1] & ticks_x <= fechas[2]]
  ticks_y <- pretty(y, n = 4)
  formato <- if (es_brecha) puntos else porcentaje
  formato_etiqueta <- if (es_brecha) puntos_decimal else porcentaje_decimal
  paleta <- setNames(clave$color, clave$etiqueta)

  grafico <- ggplot(series, aes(x = anio, y = valor, color = serie))
  if (es_brecha) {
    grafico <- grafico + geom_hline(yintercept = 0, color = "#8F968C", linewidth = 0.46)
  }

  grafico +
    geom_line(data = curvas, aes(group = interaction(serie, tramo), linetype = serie),
              linewidth = 0.91, lineend = "round") +
    geom_point(aes(shape = serie), size = 2) +
    geom_segment(
      data = etiquetas,
      aes(xend = anio_rotulo + separacion, yend = ubicacion),
      linewidth = 0.33, alpha = 0.8
    ) +
    geom_text(
      data = etiquetas,
      aes(x = anio_rotulo + separacion * 1.2, y = ubicacion, label = formato_etiqueta(valor)),
      hjust = 0, fontface = "bold", size = 4.0
    ) +
    scale_x_continuous(breaks = ticks_x, expand = expansion(mult = 0),
                       limits = fechas + c(-0.025, 0.072) * amplitud) +
    scale_y_continuous(breaks = ticks_y, labels = formato,
                       expand = expansion(mult = c(0.04, 0.06)), limits = y) +
    scale_color_manual(values = paleta) +
    scale_linetype_manual(values = setNames(clave$tipo, clave$etiqueta)) +
    scale_shape_manual(values = setNames(clave$figura, clave$etiqueta)) +
    coord_cartesian(clip = "off") +
    labs(title = titulo_panel) +
    tema_ocrc() +
    theme(panel.grid.major.x = element_blank(),
          plot.margin = margin(5, if (es_brecha) 50 else 37, 7, 2))
}

limites_pct <- function(d) {
  c(0, max(20, 20 * ceiling(max(d$valor) / 20)))
}

limites_pp <- function(d) {
  c(min(0, 20 * floor(min(d$valor) / 20)), max(20, 20 * ceiling(max(d$valor) / 20)))
}

# La web toma el título, la fuente y las notas del artículo. Las tarjetas de difusión
# incorporan esos textos para que puedan compartirse de forma independiente.
dibujar_leyenda <- function(guia, barras) {
  distribucion <- grid::grid.layout(1L, nrow(guia))
  grid::pushViewport(grid::viewport(layout = distribucion))
  for (i in seq_len(nrow(guia))) {
    item <- guia[i, ]
    grid::pushViewport(grid::viewport(layout.pos.col = i))
    if (barras) {
      grid::grid.rect(x = grid::unit(0.085, "in"), width = grid::unit(0.15, "in"),
                      height = grid::unit(0.12, "in"), gp = grid::gpar(col = NA, fill = item$color))
    } else {
      grid::grid.lines(x = grid::unit(c(0.02, 0.25), "in"), y = grid::unit(c(0.5, 0.5), "npc"),
                       gp = grid::gpar(col = item$color, lwd = 2.2, lty = item$tipo))
      grid::grid.points(x = grid::unit(0.135, "in"), y = 0.5, pch = item$figura,
                        size = grid::unit(1.8, "mm"), gp = grid::gpar(col = item$color))
    }
    grid::grid.text(item$etiqueta, x = grid::unit(if (barras) 0.23 else 0.32, "in"),
                    just = "left", gp = grid::gpar(col = tinta, fontsize = 12.2, fontfamily = "sans"))
    grid::popViewport()
  }
  grid::popViewport()
}

componer <- function(paneles, columnas, guia, barras, caratula) {
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(col = NA, fill = papel))

  social <- !is.null(caratula)
  n_filas <- ceiling(length(paneles) / columnas)
  altura_titulo <- if (social) {
    0.53 + ifelse(grepl("\n", caratula$titulo, fixed = TRUE), 0.35, 0)
  } else {
    0
  }
  altura_nota <- if (social) 0.61 else 0
  altura_leyenda <- if (!is.null(guia)) 0.28 else 0
  alturas <- grid::unit.c(grid::unit(c(altura_titulo, altura_leyenda), "in"),
                          grid::unit(rep(1, n_filas), "null"),
                          grid::unit(altura_nota, "in"))
  margen <- if (social) 0.42 else 0.24
  grid::pushViewport(grid::viewport(
    width = grid::unit(1, "npc") - grid::unit(margen, "in"),
    height = grid::unit(1, "npc") - grid::unit(margen, "in"),
    layout = grid::grid.layout(n_filas + 3L, columnas, heights = alturas)
  ))

  if (social) {
    grid::pushViewport(grid::viewport(layout.pos.row = 1L, layout.pos.col = seq_len(columnas)))
    grid::grid.text(caratula$titulo, x = 0, y = 1, just = c("left", "top"),
                    gp = grid::gpar(col = tinta, fontsize = 23, fontfamily = "serif", fontface = "bold"))
    grid::grid.text(caratula$bajada, x = 0, y = 0, just = c("left", "bottom"),
                    gp = grid::gpar(col = texto_secundario, fontsize = 11.5, fontfamily = "sans"))
    grid::popViewport()
  }

  if (!is.null(guia)) {
    grid::pushViewport(grid::viewport(layout.pos.row = 2L, layout.pos.col = seq_len(columnas)))
    dibujar_leyenda(guia, barras)
    grid::popViewport()
  }

  for (i in seq_along(paneles)) {
    posicion <- grid::viewport(layout.pos.row = 3L + (i - 1L) %/% columnas,
                               layout.pos.col = 1L + (i - 1L) %% columnas)
    print(paneles[[i]], vp = posicion, newpage = FALSE)
  }

  if (social) {
    grid::pushViewport(grid::viewport(layout.pos.row = n_filas + 3L, layout.pos.col = seq_len(columnas)))
    grid::grid.lines(y = c(1, 1), gp = grid::gpar(col = trama, lwd = 1.1))
    grid::grid.text(caratula$fuente, x = 0, y = 0.69, just = "left",
                    gp = grid::gpar(col = tinta, fontsize = 11.0, fontfamily = "sans", fontface = "bold"))
    grid::grid.text(caratula$nota, x = 0, y = 0.20, just = "left",
                    gp = grid::gpar(col = texto_secundario, fontsize = 10.1, fontfamily = "sans"))
    grid::grid.text("OCRC", x = 1, y = 0.49, just = "right",
                    gp = grid::gpar(col = marca, fontsize = 15, fontfamily = "serif", fontface = "bold"))
    grid::popViewport()
  }
  grid::popViewport()
}

exportar <- function(historia, crear, altura, titulo, bajada, nota, guia = NULL,
                     barras = FALSE, columnas_social = 1L) {
  d <- filter(estimaciones, .data$historia == .env$historia, is.finite(valor))
  if (!nrow(d)) stop("No hay estimaciones publicables para ", historia, ".")
  caratula <- list(titulo = titulo, bajada = bajada, fuente = periodo(d), nota = nota)

  grDevices::svg(file.path(carpeta_web, paste0(historia, ".svg")),
                 width = 5.75, height = altura, bg = papel)
  tryCatch(componer(crear(d, FALSE), 1L, guia, barras, NULL),
           finally = grDevices::dev.off())

  grDevices::png(file.path(carpeta_difusion, paste0(historia, ".png")),
                 width = 1200, height = 1200, res = 200, type = "cairo", bg = papel)
  tryCatch(componer(crear(d, TRUE), columnas_social, guia, barras, caratula),
           finally = grDevices::dev.off())
}

exportar(
  "composicion-generacional",
  function(d, social) {
    lapply(encuestas, function(fuente) barras_composicion(d, fuente, social))
  },
  altura = 4.78, titulo = "La religión, generación\npor generación",
  bajada = "¿Cómo se distribuye la afiliación en cada cohorte?",
  nota = "Porcentajes ponderados. Cohortes de nacimiento aproximadas.",
  guia = clave_composicion, barras = TRUE
)

exportar(
  "catolicismo-joven",
  function(d, social) {
    list(serie_temporal(d, "encuesta", clave_encuesta, range(d$anio), limites_pct(d)))
  },
  altura = 3.43, titulo = "El catolicismo entre jóvenes",
  bajada = "Identificación católica entre personas de 18 a 29 años.",
  nota = "Porcentajes ponderados sobre respuestas válidas.",
  guia = clave_encuesta
)

exportar(
  "brecha-genero",
  function(d, social) {
    paneles <- expand.grid(encuesta = encuestas, indicador = afinidades, stringsAsFactors = FALSE)
    lapply(seq_len(nrow(paneles)), function(i) {
      especificacion <- paneles[i, ]
      panel <- filter(d, encuesta == especificacion$encuesta, indicador == especificacion$indicador)
      serie_temporal(panel, "grupo", clave_sexo, range(d$anio), limites_pct(d),
                     paste(especificacion$indicador, "·", especificacion$encuesta))
    })
  },
  altura = 8.34, titulo = "La identificación religiosa\npor sexo",
  bajada = "Identificación católica y sin religión, por encuesta.",
  nota = "Porcentajes ponderados según el sexo registrado.",
  guia = clave_sexo, columnas_social = 2L
)

exportar(
  "no-afiliacion-edad",
  function(d, social) {
    escala <- limites_pct(d)[2]
    lapply(encuestas, function(fuente) barras_edad(d, fuente, escala))
  },
  altura = 4.98, titulo = "¿A qué edad es más común\nno tener religión?",
  bajada = "Porcentajes por grupo etario en el último año disponible.",
  nota = "Porcentajes ponderados. Sin intervalos de confianza.",
  barras = TRUE
)

exportar(
  "brecha-catolicismo",
  function(d, social) {
    fechas <- range(d$anio)
    series <- filter(d, unidad == "%")
    brecha <- filter(d, unidad == "pp")
    niveles <- lapply(encuestas, function(fuente) {
      panel <- filter(series, encuesta == fuente)
      serie_temporal(panel, "indicador", clave_religion, fechas, limites_pct(series), fuente)
    })
    diferencias <- lapply(encuestas, function(fuente) {
      panel <- filter(brecha, encuesta == fuente) |> mutate(serie_brecha = "Brecha")
      serie_temporal(panel, "serie_brecha", clave_brecha, fechas, limites_pp(brecha),
                     paste("Brecha ·", fuente), unidad = "pp")
    })
    c(niveles, diferencias)
  },
  altura = 8.34, titulo = "La brecha entre católicos\ny personas sin religión",
  bajada = "La brecha resta el porcentaje sin religión del católico.",
  nota = "Porcentajes ponderados y diferencias en puntos porcentuales.",
  guia = clave_religion, columnas_social = 2L
)

exportar(
  "comparacion-encuestas",
  function(d, social) {
    lapply(afinidades, function(afinidad) {
      panel <- filter(d, indicador == afinidad)
      serie_temporal(panel, "encuesta", clave_encuesta, range(d$anio), limites_pct(d), afinidad)
    })
  },
  altura = 5.02, titulo = "Dos encuestas, los mismos años",
  bajada = "Identificación católica y sin religión en años comunes.",
  nota = "Porcentajes ponderados. Las muestras y preguntas difieren.",
  guia = clave_encuesta
)
