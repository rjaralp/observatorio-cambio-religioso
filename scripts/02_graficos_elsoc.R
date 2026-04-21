# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 02_graficos_elsoc.R
# Objetivo: armar todos los graficos de ELSOC
# =========================================================


# Grafico 1: Curva de religiosidad

library(dplyr)
library(ggplot2)
library(scales)

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




















