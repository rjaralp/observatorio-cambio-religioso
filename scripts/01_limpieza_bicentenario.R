# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 01_limpieza_bicentenario.R
# Objetivo: importar y limpiar base Bicentenario consolidada
# =========================================================

rm(list = ls())

library(haven)
library(dplyr)
library(janitor)
library(stringr)

# Importar base
bic <- read_dta("datos/raw/bicentenario_limpio.dta")

# Revisar estructura inicial
glimpse(bic)
names(bic)

# Recodificación de religión
bic <- bic %>%
  mutate(
    religion_cat = case_when(
      religion_encuestado == 1 ~ "Católica",
      religion_encuestado %in% c(2, 3) ~ "Evangélica",
      religion_encuestado == 4 ~ "Otras religiones",
      religion_encuestado %in% c(5, 6) ~ "Sin religión",
      TRUE ~ NA_character_
    )
  )

saveRDS(bic, "datos/processed/bicentenario_clean.rds")

