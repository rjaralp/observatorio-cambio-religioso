# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 01_limpieza_elsoc.R
# Objetivo: importar y limpiar base ELSOC consolidada
# =========================================================

rm(list = ls())

library(dplyr)
library(haven)

# 1) Cargar base raw
elsoc_raw <- read_dta("datos/raw/ELSOC_Long_2016_2023.dta")

# 2) Limpiar variables clave
elsoc_clean <- elsoc_raw %>%
  mutate(
    ola = as.numeric(ola),
    religion_cat = case_when(
      m38 == 1 ~ "Católica",
      m38 %in% c(2, 3) ~ "Evangélica/Protestante",
      m38 %in% c(4, 6) ~ "Otras religiones",
      m38 %in% c(5, 7, 8, 9) ~ "Sin religión",
      TRUE ~ NA_character_
    ),
    religion_cat = factor(
      religion_cat,
      levels = c(
        "Católica",
        "Evangélica/Protestante",
        "Otras religiones",
        "Sin religión"
      )
    )
  )
# 3) Guardar processed
dir.create("datos/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(elsoc_clean, "datos/processed/elsoc_clean.rds")
