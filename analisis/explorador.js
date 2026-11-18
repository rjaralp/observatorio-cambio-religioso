(() => {
  const explorer = document.getElementById("explorador");
  if (!explorer) return;

  const byId = (suffix) => document.getElementById(`explorador-${suffix}`);
  const filters = byId("filtros");
  const surveySelect = byId("encuesta");
  const viewSelect = byId("vista");
  const yearSelect = byId("anio");
  const chart = byId("grafico");
  const table = byId("tabla");
  const summary = byId("resumen");
  const status = byId("estado");
  const legend = byId("leyenda");
  const showChart = byId("mostrar-grafico");
  const showTable = byId("mostrar-tabla");
  const views = {
    tendencia: {
      label: "Evolución",
      title: "Identificación religiosa en el tiempo",
      prompt: "Recorre la serie y consulta la distribución de cada año disponible.",
      tableKey: "Año"
    },
    edad: {
      label: "Edad",
      title: "Identificación religiosa por edad",
      prompt: "Compara la distribución dentro de cada grupo de edad.",
      tableKey: "Grupo de edad"
    },
    sexo: {
      label: "Sexo",
      title: "Identificación religiosa por sexo",
      prompt: "Compara la distribución según el sexo registrado en la encuesta.",
      tableKey: "Sexo"
    },
    cohorte: {
      label: "Generación",
      title: "Identificación religiosa por generación",
      prompt: "Compara la distribución entre cohortes de nacimiento en el mismo año de encuesta.",
      tableKey: "Generación"
    }
  };
  const decimal = new Intl.NumberFormat("es-CL", { maximumFractionDigits: 1, minimumFractionDigits: 1 });
  const integer = new Intl.NumberFormat("es-CL");
  const percent = (value) => `${decimal.format(value)} %`;
  const eligible = (part) => Number.isFinite(part?.pct);
  const patterns = ["", "7 4", "2 4", "10 4 2 4"];
  const svgNS = "http://www.w3.org/2000/svg";

  let data;
  let current;
  let activeIndex = 0;
  let highlightedIndex = -1;
  let highlightChart = () => {};
  let mode = "grafico";
  let legendInputs = [];

  function html(tag, content, className) {
    const element = document.createElement(tag);
    if (content !== undefined) element.textContent = content;
    if (className) element.className = className;
    return element;
  }

  function svg(tag, attributes, value) {
    const element = document.createElementNS(svgNS, tag);
    for (const [attribute, setting] of Object.entries(attributes)) {
      element.setAttribute(attribute, setting);
    }
    if (value !== undefined) element.textContent = value;
    return element;
  }

  function setOptions(select, options, value) {
    if (select.options.length !== options.length ||
        options.some((option, index) => select.options[index].value !== option.id)) {
      const elements = options.map(({ id, label }) => new Option(label, id));
      select.replaceChildren(...elements);
    }

    const selected = options.find((option) => option.id === String(value)) ?? options[0];
    select.value = selected?.id ?? "";
    return selected?.id;
  }

  function labelFor(row) {
    if (current.view === "tendencia") return String(row.year);
    return data.groups[current.view].find(({ id }) => id === row.group)?.label ?? row.group;
  }

  function findPart(row, id) {
    return row.parts.find((part) => part.id === id);
  }

  function setBarLabel(container, label, cases) {
    container.append(html("span", label, "explorador-items-etiqueta"));
    container.append(html("span", `n = ${integer.format(cases)}`, "explorador-items-n"));
  }

  function detail(index) {
    if (!current.rows[index] || index === highlightedIndex) return;
    highlightedIndex = index;
    highlightChart(index);

    const row = current.rows[index];
    const meta = html("p", current.view === "tendencia" ? "Año destacado" : "Grupo destacado", "explorador-resumen-meta");
    const heading = html("p", labelFor(row), "explorador-resumen-titulo");
    const sample = html("p", `n = ${integer.format(row.n)} respuestas válidas`, "explorador-resumen-n");
    const list = html("dl", undefined, "explorador-resumen-datos");

    for (const category of current.categories) {
      const part = findPart(row, category.id);
      const label = html("dt", category.label);
      label.style.setProperty("--explorador-serie", category.color);
      const value = html("dd", eligible(part) ? percent(part.pct) : "—");
      if (!eligible(part)) value.setAttribute("aria-label", "Dato omitido");
      list.append(label, value);
    }

    summary.replaceChildren(meta, heading, sample, list);
  }

  function setSelection(index) {
    if (!current.rows[index] || index === activeIndex) return;
    activeIndex = index;
    detail(index);

    if (current.view === "tendencia") {
      yearSelect.value = current.rows[index].year;
      updateAddress();
    }
    announce(`${labelFor(current.rows[index])}. ${integer.format(current.rows[index].n)} respuestas válidas.`);
  }

  function axisFrame(width, height, compact, accessibleLabel) {
    const plot = svg("svg", {
      viewBox: `0 0 ${width} ${height}`,
      role: "img",
      "aria-label": accessibleLabel
    });
    plot.classList.add("explorador-svg");
    if (compact) plot.classList.add("explorador-svg-compacto");
    chart.replaceChildren(plot);
    return plot;
  }

  function pointerCoordinates(event, plot, width, height) {
    const rect = plot.getBoundingClientRect();
    return [(event.clientX - rect.left) / rect.width * width, (event.clientY - rect.top) / rect.height * height];
  }

  function drawTrend(width, compact) {
    const height = compact ? 272 : 308;
    const start = 42;
    const end = width - 21;
    const top = 16;
    const bottom = height - 33;
    const { rows, categories } = current;
    const years = rows.map((row) => row.year);
    const firstYear = years[0];
    const lastYear = years.at(-1);
    const span = lastYear - firstYear;
    const x = (year) => span ? start + (year - firstYear) * (end - start) / span : (start + end) / 2;
    const y = (value) => bottom - value * (bottom - top) / 100;
    const plot = axisFrame(width, height, compact, `Series de identificación religiosa, ${firstYear} a ${lastYear}`);

    for (const tick of [0, 25, 50, 75, 100]) {
      plot.append(
        svg("line", { x1: start, x2: end, y1: y(tick), y2: y(tick), class: "explorador-svg-guia" }),
        svg("text", { x: start - 9, y: y(tick), "text-anchor": "end", "dominant-baseline": "middle" }, `${tick} %`)
      );
    }

    const tickCount = Math.min(years.length, compact ? 4 : 7);
    for (let i = 0; i < tickCount; i++) {
      const index = Math.round(i * (years.length - 1) / Math.max(1, tickCount - 1));
      plot.append(svg("text", { x: x(years[index]), y: bottom + 22, "text-anchor": "middle" }, years[index]));
    }

    const cursor = svg("line", {
      x1: x(years[activeIndex]), x2: x(years[activeIndex]), y1: top, y2: bottom,
      class: "explorador-svg-cursor"
    });
    plot.append(cursor);

    for (const category of categories) {
      let continuous = false;
      const segment = [];
      const points = [];
      for (const row of rows) {
        const part = findPart(row, category.id);
        if (eligible(part)) {
          const point = `${x(row.year)} ${y(part.pct)}`;
          segment.push(`${continuous ? "L" : "M"} ${point}`);
          points.push([x(row.year), y(part.pct)]);
        }
        continuous = eligible(part);
      }

      if (segment.length) {
        plot.append(svg("path", {
          d: segment.join(" "),
          class: "explorador-svg-serie",
          stroke: category.color,
          "stroke-dasharray": patterns[data.categories.indexOf(category)]
        }));
      }
      for (const [cx, cy] of points) {
        plot.append(svg("circle", { cx, cy, r: 2.25, fill: category.color }));
      }
    }

    const focusPoints = svg("g", {});
    plot.append(focusPoints);
    highlightChart = (index) => {
      const row = rows[index];
      const at = x(row.year);
      cursor.setAttribute("x1", at);
      cursor.setAttribute("x2", at);
      const circles = categories.flatMap(({ id, color }) => {
        const part = findPart(row, id);
        return eligible(part) ? [svg("circle", { cx: at, cy: y(part.pct), r: 5, fill: color, stroke: "#fff", "stroke-width": 2 })] : [];
      });
      focusPoints.replaceChildren(...circles);
    };

    function nearestYear(event) {
      const [position] = pointerCoordinates(event, plot, width, height);
      return years.reduce((nearest, year, index) =>
        Math.abs(position - x(year)) < Math.abs(position - x(years[nearest])) ? index : nearest, 0);
    }
    plot.addEventListener("pointermove", (event) => {
      if (event.pointerType === "mouse") detail(nearestYear(event));
    });
    plot.addEventListener("pointerleave", () => detail(activeIndex));
    plot.addEventListener("click", (event) => setSelection(nearestYear(event)));
  }

  function drawGroups(width, compact) {
    const { rows, categories } = current;
    const barHeight = 12;
    const groupHeight = 29 + categories.length * (barHeight + 5);
    const top = 4;
    const axis = top + rows.length * groupHeight;
    const height = axis + 34;
    const start = 4;
    const end = width - 20;
    const x = (value) => start + value * (end - start) / 100;
    const plot = axisFrame(width, height, compact, `Distribución por ${views[current.view].tableKey.toLowerCase()} en ${yearSelect.value}`);
    const bands = [];
    for (const tick of [0, 25, 50, 75, 100]) {
      plot.append(
        svg("line", { x1: x(tick), x2: x(tick), y1: top, y2: axis - 4, class: "explorador-svg-guia" }),
        svg("text", { x: x(tick), y: axis + 18, "text-anchor": tick === 0 ? "start" : "middle" }, `${tick} %`)
      );
    }

    for (const [index, row] of rows.entries()) {
      const groupY = top + index * groupHeight;
      const band = svg("g", { class: "explorador-svg-grupo" });
      const background = svg("rect", { x: 0, y: groupY, width, height: groupHeight - 4, rx: 6, class: "explorador-svg-banda" });
      const label = svg("text", { x: start + 2, y: groupY + 16, class: "explorador-svg-etiqueta" }, labelFor(row));
      band.append(background, label);
      for (const [position, category] of categories.entries()) {
        const part = findPart(row, category.id);
        if (!eligible(part)) continue;
        const y = groupY + 23 + position * (barHeight + 5);
        const mark = svg("rect", {
          x: start, y, width: Math.max(2, x(part.pct) - start), height: barHeight, rx: 2, fill: category.color
        });
        mark.append(svg("title", {}, `${category.label}, ${percent(part.pct)}`));
        band.append(mark);
      }
      plot.append(band);
      bands.push(band);
    }

    highlightChart = (index) => {
      for (const [position, band] of bands.entries()) band.classList.toggle("activo", index === position);
    };
    function nearestGroup(event) {
      const [, position] = pointerCoordinates(event, plot, width, height);
      return Math.min(rows.length - 1, Math.max(0, Math.floor((position - top) / groupHeight)));
    }
    plot.addEventListener("pointermove", (event) => {
      if (event.pointerType === "mouse") detail(nearestGroup(event));
    });
    plot.addEventListener("pointerleave", () => detail(activeIndex));
    plot.addEventListener("click", (event) => setSelection(nearestGroup(event)));
  }

  function buildChart() {
    if (!current?.rows.length || mode !== "grafico") return;
    const width = Math.max(280, Math.round(chart.clientWidth));
    const compact = width < 480;
    if (current.view === "tendencia") drawTrend(width, compact);
    else drawGroups(width, compact);
    highlightedIndex = -1;
    detail(activeIndex);
  }

  function buildTable() {
    const grid = html("table");
    grid.append(html("caption", `${views[current.view].title} · ${current.survey.label}`));
    const headings = grid.createTHead().insertRow();
    for (const label of [views[current.view].tableKey, "n válido", ...current.categories.map(({ label }) => label)]) {
      const heading = html("th", label);
      heading.scope = "col";
      headings.append(heading);
    }
    const body = grid.createTBody();
    for (const row of current.rows) {
      const result = body.insertRow();
      const heading = html("th", labelFor(row));
      heading.scope = "row";
      result.append(heading, html("td", integer.format(row.n)));
      for (const { id } of current.categories) {
        const part = findPart(row, id);
        const value = html("td");
        if (eligible(part)) setBarLabel(value, percent(part.pct), part.n);
        else value.textContent = "—";
        result.append(value);
      }
    }
    table.replaceChildren(grid);
  }

  function showMode() {
    const isChart = mode === "grafico";
    showChart.setAttribute("aria-pressed", isChart);
    showTable.setAttribute("aria-pressed", !isChart);
    byId("figura").hidden = !isChart;
    table.hidden = isChart;
    byId("ayuda").textContent = isChart
      ? "Selecciona un punto o un grupo para ver el detalle. Con el teclado, usa las flechas al enfocar el gráfico."
      : "La tabla muestra el porcentaje y el número de respuestas de cada categoría. Un guion indica una celda omitida.";
    if (isChart) buildChart();
    else buildTable();
  }

  function announce(message, visible = false) {
    status.classList.toggle("visually-hidden", !visible);
    status.textContent = message;
  }

  function updateAddress() {
    const url = new URL(window.location.href);
    url.searchParams.set("encuesta", surveySelect.value);
    url.searchParams.set("vista", viewSelect.value);
    if (yearSelect.value) url.searchParams.set("anio", yearSelect.value);
    history.replaceState(null, "", url);
  }

  function refresh(writeAddress = true, { year = yearSelect.value, view = viewSelect.value } = {}) {
    const survey = data.surveys.find(({ id }) => id === surveySelect.value) ?? data.surveys[0];
    const availableViews = Object.keys(views).filter((id) => survey.views[id]?.length)
      .map((id) => ({ id, label: views[id].label }));
    view = setOptions(viewSelect, availableViews, view);
    const records = [...(survey.views[view] ?? [])].sort((a, b) => a.year - b.year);
    const years = [...new Set(records.map((row) => row.year))];
    const selectedYear = Number(setOptions(yearSelect, [...years].reverse().map((value) => ({ id: String(value), label: value })), year));
    const groupOrder = data.groups[view]?.map(({ id }) => id) ?? [];
    const rows = view === "tendencia" ? records : records.filter((row) => row.year === selectedYear)
      .sort((a, b) => groupOrder.indexOf(a.group) - groupOrder.indexOf(b.group));
    const categories = data.categories.filter((_, index) => legendInputs[index].checked);
    current = { survey, view, rows, categories };
    activeIndex = view === "tendencia" ? Math.max(0, rows.findIndex((row) => row.year === selectedYear)) : 0;
    byId("etiqueta-anio").textContent = view === "tendencia" ? "Año destacado" : "Año de encuesta";
    byId("periodo").textContent = view === "tendencia"
      ? `${survey.label} · ${years[0]}–${years.at(-1)}`
      : `${survey.label} · ${selectedYear}`;
    byId("titulo").textContent = views[view]?.title ?? "Identificación religiosa";
    byId("bajada").textContent = views[view]?.prompt ?? "";
    const hasData = rows.length > 0 && rows.some((row) => categories.some(({ id }) => eligible(findPart(row, id))));
    byId("resultados").hidden = !rows.length;
    byId("fuente").textContent = survey.source;
    byId("metodo").textContent = `${survey.method} n corresponde a respuestas válidas. Se omiten celdas con menos de ${data.minCases} casos.`;
    announce(hasData ? `${byId("titulo").textContent}, ${survey.label}.` : "No hay resultados publicables para esta selección.", !hasData);
    if (writeAddress) updateAddress();
    showMode();
  }

  function openLinkedArchive() {
    try {
      const target = document.getElementById(decodeURIComponent(window.location.hash.slice(1)));
      const details = target?.closest("details.analisis-detalle");
      if (details && !details.open) {
        details.open = true;
        target.scrollIntoView();
      }
    } catch (error) {
      if (!(error instanceof URIError)) throw error;
    }
  }
  window.addEventListener("hashchange", openLinkedArchive);
  openLinkedArchive();

  async function start() {
    try {
      const endpoint = new URL("datos-explorador.json", document.currentScript?.src || document.baseURI);
      const response = await fetch(endpoint);
      if (!response.ok) throw new Error(`Datos del explorador: HTTP ${response.status}`);
      data = await response.json();

      for (const category of data.categories) {
        const label = html("label", undefined, "explorador-leyenda-item");
        const input = html("input");
        input.type = "checkbox";
        input.checked = true;
        input.value = category.id;
        const mark = html("span", undefined, "explorador-muestra");
        mark.setAttribute("aria-hidden", "true");
        mark.style.backgroundColor = category.color;
        label.append(input, mark, html("span", category.label));
        legend.append(label);
        legendInputs.push(input);
      }
      legend.addEventListener("change", () => {
        const checked = legendInputs.filter((input) => input.checked);
        for (const input of legendInputs) input.disabled = checked.length === 1 && input.checked;
        refresh(false);
      });

      const params = new URLSearchParams(location.search);
      setOptions(surveySelect, data.surveys, params.get("encuesta"));
      refresh(false, { year: params.get("anio"), view: params.get("vista") });

      surveySelect.addEventListener("change", () => refresh(true, { year: "" }));
      viewSelect.addEventListener("change", () => refresh());
      yearSelect.addEventListener("change", () => refresh());
      showChart.addEventListener("click", () => { mode = "grafico"; showMode(); });
      showTable.addEventListener("click", () => { mode = "tabla"; showMode(); });
      chart.addEventListener("keydown", (event) => {
        const change = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -1, ArrowDown: 1 }[event.key];
        if (change === undefined) return;
        event.preventDefault();
        setSelection(Math.min(current.rows.length - 1, Math.max(0, activeIndex + change)));
      });
      new ResizeObserver(buildChart).observe(chart);
      filters.disabled = false;
      showChart.parentElement.hidden = false;
    } catch (error) {
      announce("No pudimos cargar los datos del explorador. Puedes consultar las series publicadas más abajo.", true);
      console.error(error);
    } finally {
      explorer.removeAttribute("aria-busy");
    }
  }

  start();
})();
