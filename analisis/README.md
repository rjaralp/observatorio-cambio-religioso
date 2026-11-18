# Actualizar el análisis y el sitio

Con R y Quarto instalados, instalar los paquetes de R que falten.

```r
install.packages(c("here", "dplyr", "jsonlite", "ggplot2", "scales", "tidyr", "htmltools"))
```

Desde la raíz del proyecto, regenerar los agregados, gráficos y tablas y renderizar el sitio.
La exportación gráfica requiere R con soporte para Cairo y PNG.

```sh
Rscript scripts/03_datos_explorador.R
Rscript scripts/04_datos_editoriales.R
Rscript scripts/05_graficos_editoriales.R
Rscript scripts/06_tablas_editoriales.R
quarto render --no-clean
```

El script 03 actualiza `analisis/datos-explorador.json`. El 04 escribe las estimaciones
agregadas en `analisis/editoriales/estimaciones.csv`. Los scripts 05 y 06 leen ese CSV y
generan los SVG para la web, los PNG para LinkedIn en `difusion/linkedin/` y las tablas
en `analisis/_tablas-editoriales/`. Después de actualizar las series, revisar las cifras
citadas en `analisis/_preguntas.qmd` y `difusion/linkedin/publicaciones.md`.

Quarto genera el sitio en `docs/`, desde donde sirve GitHub Pages. La opción
`--no-clean` conserva los archivos históricos ya publicados. Para publicar una
actualización, incluir en el commit tanto las fuentes como el sitio renderizado.
Los gráficos históricos usan los PNG versionados en `images/`.

El explorador usa `pond` para CEP y `ponderador` para Bicentenario UC.
Las estimaciones usan respuestas válidas con ponderadores positivos. Se omiten
los porcentajes y recuentos de categorías con menos de 30 respuestas, aunque
esas respuestas se incluyen en el denominador de su grupo. Las vistas por
cohorte estiman el año de nacimiento restando la edad al año de la encuesta.
Las fichas técnicas describen la ponderación y el diseño de cada encuesta.
[Manual de la base consolidada CEP](https://static.cepchile.cl/uploads/cepchile/2025/05/14-171256_ky8a_Manual-del-Usuario-Base-Consolidada-Mayo-2025.pdf) ·
[Metodología de Bicentenario UC](https://encuestabicentenario.uc.cl/metodologia/)

Las reglas de las historias, los años válidos y las diferencias entre fuentes
están en la [auditoría metodológica](auditoria-editorial.qmd).
