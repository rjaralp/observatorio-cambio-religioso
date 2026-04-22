# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 02_graficos_elsoc.R
# Objetivo: armar todos los graficos de ELSOC
# =========================================================


rm(list = ls())
# Grafico 1: Curva de religiosidad

library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

setwd("C:/Users/Dell/Desktop/observatorio-cambio-religioso")

elsoc <- readRDS("C:/Users/Dell/Desktop/observatorio-cambio-religioso/datos/processed/elsoc_clean.rds")

elsoc_ts <- elsoc %>%
  filter(!is.na(religion_cat), !is.na(ola)) %>%
  count(ola, religion_cat) %>%
  group_by(ola) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

elsoc_ts

ggplot(elsoc_ts, aes(x = ola, y = prop, color = religion_cat)) +
  geom_line(linewidth = 1.2) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Cambio en la identificación religiosa en Chile (ELSOC)",
    x = "Ola",
    y = "Porcentaje",
    color = "Religión",
    caption = "ELSOC. Observatorio del Cambio Religioso en Chile (OCRC)."
  ) +
  theme_minimal()

# Grafico 2: Curva de religiosidad por cohorte


# Creacion de generacion 

table(elsoc$ola, is.na(elsoc$annio_enc))


elsoc %>%
  mutate(tiene_annio = !is.na(annio_enc) & annio_enc != -999) %>%
  count(ola, tiene_annio)

elsoc <- elsoc %>%
  mutate(
    annio_enc = ifelse(annio_enc == -999, NA, annio_enc)
  ) %>%
  group_by(idencuesta) %>%
  tidyr::fill(annio_enc, .direction = "downup") %>%
  ungroup()


elsoc_cohortes <- elsoc %>%
  mutate(
    annio_enc = ifelse(annio_enc == -999, NA, annio_enc)
  ) %>%
  group_by(idencuesta) %>%
  fill(annio_enc, .direction = "downup") %>%
  ungroup() %>%
  mutate(
    cohorte = case_when(
      annio_enc >= 1928 & annio_enc <= 1964 ~ "Silenciosa + Boomers",
      annio_enc >= 1965 & annio_enc <= 1980 ~ "Generación X",
      annio_enc >= 1981 & annio_enc <= 1996 ~ "Millennials",
      annio_enc >= 1997 & annio_enc <= 2012 ~ "Generación Z",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(religion_cat), !is.na(ola), !is.na(cohorte)) %>%
  count(ola, cohorte, religion_cat) %>%
  group_by(ola, cohorte) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

elsoc_cohortes <- elsoc_cohortes |>
  mutate(
    cohorte = factor(
      cohorte,
      levels = c("Silenciosa + Boomers", "Generación X", "Millennials")
    )
  )


# Grafico

grafico_cohortes_elsoc <- ggplot(
  elsoc_cohortes,
  aes(x = ola, y = prop, color = religion_cat, group = religion_cat)
) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~ cohorte, ncol = 2) +
  scale_x_continuous(breaks = 1:7) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_color_manual(
    values = c(
      "Católica" = "#F8766D",
      "Evangélica/Protestante" = "#7CAE00",
      "Otras religiones" = "#00BFC4",
      "Sin religión" = "#C77CFF"
    ),
    name = "Religión"
  ) +
  labs(
    title = "Cambio en la Identificación Religiosa en Chile por Cohorte (ELSOC)",
    x = "Ola",
    y = "Porcentaje",
    caption = "Encuesta ELSOC. Observatorio del Cambio Religioso en Chile (OCRC)."
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 22, face = "bold"),
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 12),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 13),
    strip.text = element_text(size = 14, face = "bold"),
    plot.caption = element_text(size = 11, hjust = 0.5),
    panel.grid.minor = element_line(color = "grey85"),
    panel.grid.major = element_line(color = "grey80")
  )

grafico_cohortes_elsoc

ggsave(
  filename = "images/elsoc_cohortes_religion.png",
  plot = grafico_cohortes_elsoc,
  width = 12,
  height = 8,
  dpi = 300
)

