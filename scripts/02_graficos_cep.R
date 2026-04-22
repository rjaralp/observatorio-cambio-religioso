# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 02_graficos_cep.R
# Objetivo: armar todos los graficos de Bicentenario
# =========================================================


rm(list = ls())
# Grafico 1: Curva de religiosidad

library(dplyr)
library(ggplot2)
library(scales)

setwd("C:/Users/Dell/Desktop/observatorio-cambio-religioso")

cep <- readRDS("datos/processed/cep_clean.rds")

religion_ts <- cep %>%
  filter(!is.na(religion_cat), !is.na(encuesta_a)) %>%
  count(encuesta_a, religion_cat) %>%
  group_by(encuesta_a) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

religion_ts

ggplot(religion_ts, aes(x = encuesta_a, y = prop, color = religion_cat)) +
  geom_line(linewidth = 1.2) +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Cambio en la Identificación Religiosa en Chile (CEP)",
    x = "Año (encuesta_a)",
    y = "Porcentaje",
    color = "Religión",
    caption = "Encuesta CEP. Observatorio del Cambio Religioso en Chile (OCRC)."
  ) +
  theme_minimal()


# Grafico 2: Curva de religiosidad por cohorte


# Creacion de generacion 

library(dplyr)
library(ggplot2)
library(scales)

cep_cohortes <- cep |> 
  mutate(
    anio_nacimiento = encuesta_a - edad,
    cohorte = case_when(
      anio_nacimiento >= 1928 & anio_nacimiento <= 1964 ~ "Silenciosa + Boomers",
      anio_nacimiento >= 1965 & anio_nacimiento <= 1980 ~ "Generación X",
      anio_nacimiento >= 1981 & anio_nacimiento <= 1996 ~ "Millennials",
      anio_nacimiento >= 1997 & anio_nacimiento <= 2012 ~ "Generación Z",
      TRUE ~ NA_character_
    ),
    religion_cat = case_when(
      religion_1 == 1 ~ "Católica",
      religion_1 == 2 ~ "Evangélica",
      religion_1 %in% c(3, 4, 5, 6, 7, 8) ~ "Otras religiones",
      religion_1 %in% c(9, 10, 11) ~ "Sin religión",
      TRUE ~ NA_character_
    )
  ) |> 
  filter(!is.na(cohorte), !is.na(religion_cat)) |> 
  group_by(encuesta_a, cohorte, religion_cat) |> 
  summarise(n = n(), .groups = "drop") |> 
  group_by(encuesta_a, cohorte) |> 
  mutate(pct = n / sum(n)) |> 
  ungroup()

grafico_cohortes_cep <- ggplot(cep_cohortes, aes(x = encuesta_a, y = pct, color = religion_cat)) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~ cohorte, ncol = 2) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_color_manual(
    values = c(
      "Católica" = "#F8766D",
      "Evangélica" = "#7CAE00",
      "Otras religiones" = "#00BFC4",
      "Sin religión" = "#C77CFF"
    ),
    name = "Religión"
  ) +
  labs(
    title = "Cambio en la Identificación Religiosa en Chile por Cohorte (CEP)",
    x = "Año (encuesta_a)",
    y = "Porcentaje",
    caption = "Encuesta CEP. Observatorio del Cambio Religioso en Chile (OCRC)."
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

grafico_cohortes_cep

ggsave(
  filename = "C:/Users/Dell/Desktop/observatorio-cambio-religioso/images/cep_cohortes_religion.png",
  plot = grafico_cohortes_cep,
  width = 12,
  height = 8,
  dpi = 300
)

