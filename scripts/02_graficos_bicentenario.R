# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 02_grafico_bicentenario.R
# Objetivo: armar todos los graficos de Bicentenario
# =========================================================

rm(list = ls())
# Grafico 1: Curva de religiosidad

library(dplyr)
library(ggplot2)
library(scales)

setwd("C:/Users/Dell/Desktop/observatorio-cambio-religioso")

bic <- readRDS("C:/Users/Dell/Desktop/observatorio-cambio-religioso/datos/processed/bicentenario_clean.rds")

religion_ts_bic <- bic %>%
  filter(!is.na(religion_cat), !is.na(ano)) %>%
  count(ano, religion_cat) %>%
  group_by(ano) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

religion_ts_bic

ggplot(religion_ts_bic, aes(x = ano, y = prop, color = religion_cat)) +
  geom_line(linewidth = 1.2) +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Cambio en la Identificación Religiosa en Chile (Encuesta Bicentenario)",
    x = "Año",
    y = "Porcentaje",
    color = "Religión",
    caption = "Encuesta Bicentneario. Observatorio del Cambio Religioso en Chile (OCRC)."
  ) +
  theme_minimal()



# Grafico 2: Curva de religiosidad por cohorte


# Creacion de generacion 


bic <- bic |> 
  mutate(
    anio_nacimiento = ano - edad,
    cohorte = case_when(
      anio_nacimiento >= 1928 & anio_nacimiento <= 1964 ~ "Silenciosa + Boomers",
      anio_nacimiento >= 1965 & anio_nacimiento <= 1980 ~ "Generación X",
      anio_nacimiento >= 1981 & anio_nacimiento <= 1996 ~ "Millennials",
      anio_nacimiento >= 1997 & anio_nacimiento <= 2012 ~ "Generación Z",
      TRUE ~ NA_character_
    )
  )

bic_cohortes <- bic |> 
  filter(!is.na(cohorte), !is.na(religion_cat)) |> 
  group_by(ano, cohorte, religion_cat) |> 
  summarise(n = n(), .groups = "drop") |> 
  group_by(ano, cohorte) |> 
  mutate(pct = n / sum(n)) |> 
  ungroup()


grafico_cohortes_bic <- ggplot(bic_cohortes, aes(x = ano, y = pct, color = religion_cat)) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~ cohorte, ncol = 2) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
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
    title = "Cambio en la Identificación Religiosa en Chile por Cohorte (Bicentenario)",
    x = "Año (ano)",
    y = "Porcentaje",
    caption = "Encuesta Bicentenario UC. Observatorio del Cambio Religioso en Chile (OCRC)."
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

grafico_cohortes_bic

ggsave(
  filename = "images/bicentenario_cohortes_religion.png",
  plot = grafico_cohortes_bic,
  width = 12,
  height = 8,
  dpi = 300
)









































