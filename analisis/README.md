# Actualizar el explorador y el sitio

Con R y Quarto instalados, instalar los paquetes de R que falten.

```r
install.packages(c("here", "dplyr", "jsonlite"))
```

Desde la raíz del proyecto, regenerar los datos del explorador y renderizar el sitio.

```sh
Rscript scripts/03_datos_explorador.R
quarto render
```

El script lee las bases procesadas de CEP y Bicentenario UC y escribe
`analisis/datos-explorador.json` con porcentajes ponderados y recuentos
agregados. Quarto copia ese archivo a `docs/`, desde donde GitHub Pages
sirve el sitio. Los gráficos históricos usan los PNG versionados en `images/`.

El explorador usa `pond` para CEP y `ponderador` para Bicentenario UC.
Las estimaciones usan respuestas válidas con ponderadores positivos. Se omiten
los porcentajes y recuentos de categorías con menos de 30 respuestas, aunque
esas respuestas se incluyen en el denominador de su grupo. Las vistas por
cohorte estiman el año de nacimiento restando la edad al año de la encuesta.
Las fichas técnicas describen la ponderación y el diseño de cada encuesta.
[Manual de la base consolidada CEP](https://static.cepchile.cl/uploads/cepchile/2025/05/14-171256_ky8a_Manual-del-Usuario-Base-Consolidada-Mayo-2025.pdf) ·
[Metodología de Bicentenario UC](https://encuestabicentenario.uc.cl/metodologia/)
