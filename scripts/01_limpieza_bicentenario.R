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

saveRDS(bic, "datos/processed/bicentenario_clean.rds")

