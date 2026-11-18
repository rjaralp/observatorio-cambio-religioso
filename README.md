# observatorio-cambio-religioso
Observatorio del Cambio Religioso en Chile. Plataforma abierta de análisis y visualización de datos sobre identificación religiosa, afiliación y transformación cultural, basada en fuentes oficiales y métodos reproducibles.

## Regenerar los gráficos y el sitio

Con R y Quarto instalados, abrir el proyecto e instalar los paquetes de R que falten.

```r
install.packages(c("here", "dplyr", "ggplot2", "scales", "tidyr"))
```

Desde la raíz del proyecto, ejecutar los tres scripts de gráficos y renderizar el sitio.
Los scripts leen las bases incluidas en `datos/processed/` y escriben los seis
gráficos en `images/`. Quarto usa esos PNG y genera el sitio en `docs/`.

```sh
Rscript scripts/02_graficos_cep.R
Rscript scripts/02_graficos_bicentenario.R
Rscript scripts/02_graficos_elsoc.R
quarto render
```

Para volver a crear las bases procesadas, ejecutar el script `01_limpieza_*.R`
de la encuesta correspondiente. Instalar también `haven` para ELSOC y
Bicentenario, y `janitor` y `stringr` para Bicentenario. Solo
`scripts/01_limpieza_elsoc.R` requiere la base original de ELSOC. Antes de
ejecutarlo, extraer `ELSOC_Long_2016_2023.dta` de `datos/dataverse_files.zip`
y dejar el archivo en `datos/raw/`.
