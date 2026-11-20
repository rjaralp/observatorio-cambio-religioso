# =========================================================
# Proyecto: Observatorio del Cambio Religioso
# Script: 01_limpieza_cep.R
# Objetivo: importar y limpiar base Bicentenario consolidada
# =========================================================



library(dplyr)

here::i_am("scripts/01_limpieza_cep.R")

cep_raw <- readRDS(here::here("datos", "raw", "CEP_consolidada.rds"))

cep_clean <- cep_raw %>%
  mutate(
    religion_cat = case_when(
      religion_1 == 1 ~ "Católica",
      religion_1 == 2 ~ "Evangélica",
      religion_1 %in% c(3, 4, 5, 6, 7, 8, 13) ~ "Otras religiones",
      religion_1 %in% c(9, 10, 11) ~ "Sin religión",
      religion_1 %in% c(-8, -9) ~ NA_character_,
      TRUE ~ NA_character_
    ),
    religion_cat = factor(
      religion_cat,
      levels = c("Católica", "Evangélica", "Otras religiones", "Sin religión")
    )
  )

dir.create(here::here("datos", "processed"), recursive = TRUE, showWarnings = FALSE)
saveRDS(cep_clean, here::here("datos", "processed", "cep_clean.rds"))
