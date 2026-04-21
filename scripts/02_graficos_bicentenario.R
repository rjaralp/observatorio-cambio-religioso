# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 02_grafico_bicentenario.R
# Objetivo: armar todos los graficos de Bicentenario
# =========================================================


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
