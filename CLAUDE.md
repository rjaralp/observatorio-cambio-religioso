# Observatorio del Cambio Religioso en Chile (OCRC)

Sitio web abierto de análisis y visualización de datos sobre identificación religiosa en Chile.
Dirección: Ramón Jara López (sociólogo, Mg. en Sociología PUC). Proyecto iniciado el 11-02-2026.
Idioma de todo el sitio, textos y gráficos: **español de Chile**.

Sitio publicado: https://rjaralp.github.io/observatorio-cambio-religioso/
Objetivo a mediano plazo: gráficos tipo Ryan Burge (muchos cruces entre variables), gráficos interactivos,
actualización semanal/mensual y dominio propio .cl (se mantiene GitHub Pages, solo se agrega dominio).

## Cómo está construido

- Quarto (website), R. Salida en `docs/` (así lo sirve GitHub Pages). `_site/` está en .gitignore.
- Páginas: `index.qmd`, `analisis/analisis.qmd`, `datos/datos.qmd`, `papers/papers.qmd`, `about.qmd`.
- `scripts/01_limpieza_*.R`: importan datos crudos y guardan `datos/processed/*_clean.rds`.
- `scripts/02_graficos_*.R`: construyen los gráficos y los guardan como PNG en `images/`.
- Los `.qmd` incluyen los PNG; hoy no hay gráficos interactivos.
- `datos/raw/ELSOC_Long_2016_2023.dta` NO está en el repo (.gitignore). Se descarga de Harvard Dataverse
  (doi:10.7910/DVN/LD4BPH). Se puede trabajar con `datos/processed/elsoc_clean.rds`.

## Variables clave por encuesta

| Encuesta | Archivo limpio | Año/ola | Religión (cruda) | Otras |
|---|---|---|---|---|
| CEP 1994-2024 | `cep_clean.rds` | `encuesta_a` | `religion_1` | `edad` |
| Bicentenario UC | `bicentenario_clean.rds` | `ano` | `religion_encuestado` | `edad` |
| ELSOC 2016-2023 (panel, urbano) | `elsoc_clean.rds` | `ola` (1-7) | `m38` | `annio_enc`, `idencuesta` |

Categorías de `religion_cat`: Católica, Evangélica (en ELSOC: Evangélica/Protestante), Otras religiones, Sin religión.
Cohortes (por año de nacimiento): Silenciosa + Boomers 1928-1964, Generación X 1965-1980,
Millennials 1981-1996, Generación Z 1997-2012.

## Problemas conocidos (resolver primero)

1. Los scripts `02_graficos_*` tienen `setwd("C:/Users/Dell/Desktop/...")` y rutas absolutas de un PC antiguo.
   Reemplazar por rutas relativas al proyecto (paquete `here`). No deben depender de ningún setwd.
2. El código de gráficos está triplicado (una copia por encuesta). Unificar en funciones compartidas
   (por ejemplo `R/funciones.R`) y una lista/archivo de configuración de gráficos, para agregar uno nuevo con una línea.
3. Inconsistencia de recodificación en CEP: `01_limpieza_cep.R` incluye el código 13 en "Otras religiones",
   pero `02_graficos_cep.R` vuelve a recodificar `religion_cat` sin el 13. Dejar UNA sola recodificación, en la limpieza.
4. Ningún gráfico usa ponderadores (factores de expansión). Identificar la variable de ponderación de cada
   base en sus cuestionarios/diccionarios y aplicarla. Confirmar con el director antes de dar por buena una variable.
5. Etiquetas de ejes con nombres de variable ("Año (ano)", "Año (encuesta_a)"): dejar "Año".
6. Erratas en textos: "1994-20024", "Bicentneario", "deicha", "desacargar".
7. El repo pesa ~227 MB (zip de 52 MB y bases crudas dentro). Proponer orden sin borrar nada sin permiso.

## Reglas de trabajo y calidad

- Trabajar en una rama y abrir pull request; no empujar directo a `main`. El director revisa y hace el merge.
- Nunca borrar archivos de datos ni reescribir historial.
- Todo gráfico: ponderado, con fuente y n en el pie, formato de pie
  "Fuente: <encuesta>. Observatorio del Cambio Religioso en Chile (OCRC)."
- Mostrar intervalos de confianza donde corresponda; no graficar ni interpretar celdas con pocos casos
  (definir y documentar un n mínimo; por defecto avisar bajo ~30 casos por celda).
- Los textos de interpretación deben describir solo lo que muestran los datos. Sin causalidad no demostrada,
  y distinguir cambio de cohorte, período y ciclo de vida.
- No inventar cifras ni variables. Si una variable no está clara, preguntar.
- Paleta consistente con la actual: Católica #F8766D, Evangélica #7CAE00, Otras religiones #00BFC4, Sin religión #C77CFF.
- Antes de dar por terminada una tarea: renderizar el sitio con Quarto y comprobar que no hay errores ni enlaces rotos.

## Hoja de ruta

1. Ordenar proyecto (rutas, funciones compartidas, recodificación única, ponderadores).
2. Publicación automática con GitHub Actions (renderizar y publicar el sitio al aprobar cambios).
3. Primer lote de gráficos con cruces: religión por cohorte, sexo, educación, posición política, región;
   asistencia a servicios religiosos; desglose de la no afiliación (ateo, agnóstico, "nada en particular");
   confianza en la Iglesia; valores (aborto, matrimonio igualitario); comparación entre encuestas.
4. Gráficos interactivos en Quarto (filtros por encuesta, cohorte, período).
5. Actualización periódica: monitor de prensa sobre religión, nuevas olas/encuestas (Latinobarómetro, LAPOP, etc.),
   nuevos papers. Ejecutar como tarea programada.
6. Dominio .cl apuntando a GitHub Pages.
