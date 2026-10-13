/* Review fixtures and form behavior only. This does not save or evaluate real rules. */
const dayButtons = [...document.querySelectorAll("[data-day]")];
const appChecks = [...document.querySelectorAll('input[name="app"]')];
const websiteInput = document.querySelector("#website-input");
const matchPreview = document.querySelector("#match-preview");
const websiteList = document.querySelector("#website-list");
const composer = document.querySelector("#website-composer");
const appScroll = document.querySelector("#app-scroll");
const toast = document.querySelector("#prototype-toast");
const dialog = document.querySelector("#discard-dialog");
const examples = {
  "demo.app.a": "Sample App A",
  "demo.app.b": "Sample App B",
  "demo.app.c": "Sample App C",
};
let websites = [];
let scope = "host";
let mode = "new";
let toastTimer;
let initialSnapshot = "";

function setDays(days) {
  dayButtons.forEach((button) => {
    const selected = days.includes(button.dataset.day);
    button.setAttribute("aria-pressed", String(selected));
  });
  updateScheduleSummary();
}

function selectedDays() {
  return dayButtons.filter((button) => button.getAttribute("aria-pressed") === "true").map((button) => button.dataset.day);
}

function updateScheduleSummary() {
  const days = selectedDays();
  const summary = document.querySelector("#schedule-summary");
  if (!days.length) {
    summary.textContent = "Choose at least one day";
    return;
  }
  const start = document.querySelector("#start-time").value;
  const end = document.querySelector("#end-time").value;
  const dayLabel = days.length === 7 ? "Every day" : days.join(", ");
  summary.textContent = `${dayLabel} · ${formatTime(start)}–${formatTime(end)}${end < start ? " next day" : ""}`;
}

function formatTime(value) {
  if (!value) return "—";
  const [hour, minute] = value.split(":").map(Number);
  const period = hour >= 12 ? "PM" : "AM";
  const hour12 = hour % 12 || 12;
  return `${hour12}:${String(minute).padStart(2, "0")} ${period}`;
}

function normalizeHost(raw) {
  let value = raw.trim();
  if (!value) throw new Error("Enter a website domain.");
  if (value.startsWith("*.")) value = value.slice(2);
  const withScheme = value.includes("://") ? value : `https://${value}`;
  let parsed;
  try { parsed = new URL(withScheme); } catch { throw new Error("Enter a valid domain, such as youtube.com."); }
  if (parsed.username || parsed.password || !parsed.hostname) throw new Error("Enter a valid domain, such as youtube.com.");
  let host = parsed.hostname.toLowerCase().replace(/^www\./, "").replace(/\.+$/, "");
  const labels = host.split(".");
  if (host.length > 253 || labels.length < 2 || labels.some((label) => !label || label.length > 63 || !/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/i.test(label))) {
    throw new Error("Enter a valid domain, such as youtube.com.");
  }
  return host;
}

function updatePreview() {
  const raw = websiteInput.value.trim();
  if (!raw) {
    matchPreview.textContent = scope === "host"
      ? "Includes the website and its www version. Other subdomains are not included."
      : "Includes the website and all subdomains, such as m.youtube.com.";
    return;
  }
  try {
    const host = normalizeHost(raw);
    matchPreview.textContent = scope === "host"
      ? `Includes ${host} and www.${host}. Other subdomains are not included.`
      : `Includes ${host} and all subdomains, such as m.${host}.`;
  } catch {
    matchPreview.textContent = scope === "host"
      ? "Includes the website and its www version. Other subdomains are not included."
      : "Includes the website and all subdomains, such as m.youtube.com.";
  }
}

function renderWebsites() {
  websiteList.replaceChildren();
  websiteList.hidden = websites.length === 0;
  document.querySelector("#website-count").textContent = `${websites.length} ${websites.length === 1 ? "website" : "websites"} added`;
  websites.forEach((website, index) => {
    if (index) {
      const divider = document.createElement("div");
      divider.className = "form-divider website-divider";
      websiteList.append(divider);
    }
    const row = document.createElement("div");
    row.className = "website-item";
    const copy = document.createElement("span");
    copy.className = "website-item-copy";
    const host = document.createElement("span");
    host.className = "website-host";
    host.textContent = website.host;
    const match = document.createElement("span");
    match.className = "website-scope";
    match.textContent = website.scope === "host" ? "This website" : "All subdomains";
    copy.append(host, match);
    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "remove-website";
    remove.setAttribute("aria-label", `Remove ${website.host}`);
    remove.innerHTML = '<svg class="icon" aria-hidden="true"><use href="#icon-minus"></use></svg>';
    remove.addEventListener("click", () => {
      websites.splice(index, 1);
      renderWebsites();
      refreshTargetsError();
    });
    row.append(copy, remove);
    websiteList.append(row);
  });
}

function showToast(message) {
  clearTimeout(toastTimer);
  toast.textContent = message;
  toast.classList.add("is-visible");
  toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 2400);
}

function snapshot() {
  return JSON.stringify({
    name: document.querySelector("#rule-name").value,
    enabled: document.querySelector("#enabled-toggle").checked,
    days: selectedDays(),
    start: document.querySelector("#start-time").value,
    end: document.querySelector("#end-time").value,
    apps: appChecks.filter((input) => input.checked).map((input) => input.value),
    websites,
    websiteInput: websiteInput.value,
    scope,
  });
}

function clearErrors() {
  ["name", "schedule", "targets"].forEach((id) => {
    const error = document.querySelector(`#${id}-error`);
    error.hidden = true;
    error.textContent = "";
    document.querySelector(`[data-section="${id}"]`)?.classList.remove("has-error", "is-focused-error");
  });
  document.querySelector("#website-error").hidden = true;
  document.querySelector("#website-error").textContent = "";
  composer.classList.remove("has-error");
}

function setError(id, message) {
  const element = document.querySelector(`#${id}-error`);
  element.textContent = message;
  element.hidden = false;
  document.querySelector(`[data-section="${id}"]`)?.classList.add("has-error");
}

function validateAndSave() {
  clearErrors();
  const name = document.querySelector("#rule-name").value.trim();
  const days = selectedDays();
  const start = document.querySelector("#start-time").value;
  const end = document.querySelector("#end-time").value;
  let firstIssue = null;
  if (!name) {
    setError("name", "Give this rule a name.");
    firstIssue ??= { section: "name", focus: "#rule-name" };
  }

  const [startHour, startMinute] = start.split(":").map(Number);
  const [endHour, endMinute] = end.split(":").map(Number);
  const duration = (endHour * 60 + endMinute - (startHour * 60 + startMinute) + 1440) % 1440;
  const scheduleIssues = [];
  if (!days.length) scheduleIssues.push("Choose at least one day.");
  if (duration < 15) scheduleIssues.push("A schedule must last at least 15 minutes.");
  if (scheduleIssues.length) {
    setError("schedule", scheduleIssues.join(" "));
    firstIssue ??= { section: "schedule", focus: days.length ? "#start-time" : ".day-button" };
  }

  const hasTargets = appChecks.some((input) => input.checked) || websites.length > 0;
  const draftWebsite = websiteInput.value.trim();
  if (!hasTargets) {
    setError("targets", "Choose at least one app or website.");
    firstIssue ??= { section: "targets", focus: draftWebsite ? "#website-input" : "#app-list input" };
  }
  if (draftWebsite) {
    document.querySelector("#website-error").textContent = "Add this website or clear the field before saving.";
    document.querySelector("#website-error").hidden = false;
    composer.classList.add("has-error");
    firstIssue ??= { section: "targets", focus: "#website-input" };
  }
  if (firstIssue) {
    focusIssue(firstIssue);
    return;
  }
  initialSnapshot = snapshot();
  showToast(mode === "editing" ? "Changes saved" : "Rule saved");
}

function focusIssue(issue) {
  const section = document.querySelector(`[data-section="${issue.section}"]`);
  section.classList.remove("is-focused-error");
  requestAnimationFrame(() => {
    section.classList.add("is-focused-error");
    section.scrollIntoView({ behavior: "smooth", block: "start" });
    setTimeout(() => document.querySelector(issue.focus)?.focus?.({ preventScroll: true }), 220);
  });
}

function refreshTargetsError() {
  const active = !document.querySelector("#targets-error").hidden;
  if (active && (appChecks.some((input) => input.checked) || websites.length)) {
    document.querySelector("#targets-error").hidden = true;
    document.querySelector("[data-section='targets']").classList.remove("has-error");
  }
}

function addWebsite() {
  const error = document.querySelector("#website-error");
  error.hidden = true;
  error.textContent = "";
  composer.classList.remove("has-error");
  try {
    const host = normalizeHost(websiteInput.value);
    if (websites.some((website) => website.host === host && website.scope === scope)) throw new Error("This website match is already in the rule.");
    websites.push({ host, scope });
    websiteInput.value = "";
    renderWebsites();
    updatePreview();
    refreshTargetsError();
    showToast(`${host} added`);
  } catch (problem) {
    error.textContent = problem.message;
    error.hidden = false;
    composer.classList.add("has-error");
    websiteInput.focus();
  }
}

function setScope(nextScope) {
  scope = nextScope;
  document.querySelectorAll("[data-match]").forEach((button) => {
    const selected = button.dataset.match === scope;
    button.classList.toggle("is-selected", selected);
    button.setAttribute("aria-pressed", String(selected));
  });
  updatePreview();
}

function loadScenario(nextMode) {
  mode = nextMode;
  clearErrors();
  document.querySelector("#screen-title").textContent = nextMode === "editing" ? "Edit Rule" : "New Rule";
  websites = [];
  scope = "host";
  document.querySelector("#rule-name").value = "";
  document.querySelector("#enabled-toggle").checked = true;
  document.querySelector("#start-time").value = "09:00";
  document.querySelector("#end-time").value = "17:00";
  websiteInput.value = "";
  document.querySelectorAll('input[name="app"]').forEach((input) => { input.checked = false; });
  setDays([]);
  renderWebsites();
  setScope("host");

  if (nextMode === "editing" || nextMode === "unsaved") {
    document.querySelector("#rule-name").value = "Evening Reset";
    document.querySelector("#start-time").value = "22:00";
    document.querySelector("#end-time").value = "07:00";
    setDays(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]);
    document.querySelector('input[value="demo.app.a"]').checked = true;
    document.querySelector('input[value="demo.app.b"]').checked = true;
    websites.push({ host: "youtube.com", scope: "subdomains" });
    renderWebsites();
    setScope("subdomains");
  }
  initialSnapshot = snapshot();
  if (nextMode === "unsaved") document.querySelector("#rule-name").value = "Evening Reset — updated";
  if (nextMode === "errors") {
    document.querySelector("#rule-name").value = "";
    document.querySelector("#start-time").value = "09:00";
    document.querySelector("#end-time").value = "09:00";
    setDays([]);
    document.querySelector("#website-input").value = "youtube.com";
    updatePreview();
    requestAnimationFrame(() => validateAndSave());
  }
  if (nextMode !== "unsaved") initialSnapshot = snapshot();
  dialog.hidden = nextMode !== "unsaved";
  appScroll.scrollTop = 0;
}

function requestCancel() {
  if (snapshot() !== initialSnapshot) {
    dialog.hidden = false;
    document.querySelector("#stay-button").focus();
  } else {
    showToast("Return to rules");
  }
}

dayButtons.forEach((button) => button.addEventListener("click", () => {
  const selected = button.getAttribute("aria-pressed") === "true";
  button.setAttribute("aria-pressed", String(!selected));
  updateScheduleSummary();
  const error = document.querySelector("#schedule-error");
  if (!selected) { error.hidden = true; document.querySelector("[data-section='schedule']").classList.remove("has-error"); }
}));
document.querySelectorAll("#start-time, #end-time").forEach((input) => input.addEventListener("input", updateScheduleSummary));
document.querySelector("#rule-name").addEventListener("input", () => {
  if (document.querySelector("#rule-name").value.trim()) {
    document.querySelector("#name-error").hidden = true;
    document.querySelector("[data-section='name']").classList.remove("has-error");
  }
});
appChecks.forEach((input) => input.addEventListener("change", refreshTargetsError));
document.querySelectorAll("[data-match]").forEach((button) => button.addEventListener("click", () => setScope(button.dataset.match)));
websiteInput.addEventListener("input", updatePreview);
document.querySelector("#add-website").addEventListener("click", addWebsite);
websiteInput.addEventListener("keydown", (event) => { if (event.key === "Enter") { event.preventDefault(); addWebsite(); } });
document.querySelector("#save-button").addEventListener("click", validateAndSave);
document.querySelector("#cancel-button").addEventListener("click", requestCancel);
document.querySelector("#stay-button").addEventListener("click", () => { dialog.hidden = true; document.querySelector("#cancel-button").focus(); });
document.querySelector("#discard-button").addEventListener("click", () => { dialog.hidden = true; showToast("Changes discarded · Return to rules"); });

document.querySelectorAll("[data-scenario]").forEach((button) => button.addEventListener("click", () => {
  document.querySelectorAll("[data-scenario]").forEach((candidate) => {
    const selected = candidate === button;
    candidate.classList.toggle("is-selected", selected);
    candidate.setAttribute("aria-pressed", String(selected));
  });
  loadScenario(button.dataset.scenario);
}));

setDays([]);
setScope("host");
renderWebsites();
initialSnapshot = snapshot();
const queryScenario = new URLSearchParams(window.location.search).get("scenario");
if (["editing", "errors", "unsaved"].includes(queryScenario)) {
  const activeButton = document.querySelector(`[data-scenario="${queryScenario}"]`);
  document.querySelectorAll("[data-scenario]").forEach((button) => {
    const selected = button === activeButton;
    button.classList.toggle("is-selected", selected);
    button.setAttribute("aria-pressed", String(selected));
  });
  loadScenario(queryScenario);
}
