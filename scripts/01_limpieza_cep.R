library(dplyr)

cep_raw <- readRDS("datos/raw/CEP_consolidada.rds")

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

dir.create("datos/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(cep_clean, "datos/processed/cep_clean.rds")
