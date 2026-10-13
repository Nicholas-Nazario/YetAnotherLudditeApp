/**
 * Rules list review fixtures. These examples do not evaluate schedules or
 * infer status from time; the production app remains the source of truth.
 */

const scenarios = {
  mixed: [
    { name: "Morning Focus", state: "active", schedule: "Mon, Wed, Fri · 7:30 AM–9:00 AM", apps: 2, websites: 1, timeRemaining: "42m" },
    { name: "Deep Work", state: "active", schedule: "Weekdays · 9:00 AM–5:00 PM", apps: 4, websites: 2, timeRemaining: "2h 40m" },
    { name: "Evening Reset", state: "paused", schedule: "Every day · 10:00 PM–7:00 AM next day", apps: 3, websites: 2, pauseUntil: "2:35 PM" },
    { name: "Family Time", state: "upcoming", schedule: "Weekends · 4:00 PM–8:00 PM", apps: 1, websites: 3 },
    { name: "Study Block", state: "upcoming", schedule: "Tue–Sat · 6:00 PM–9:00 PM", apps: 5, websites: 1 },
    { name: "Social Break", state: "disabled", schedule: "Weekdays · 12:00 PM–1:00 PM", apps: 2, websites: 0 },
  ],
  "no-rules": [],
  "paused-disabled": [
    { name: "Evening Reset", state: "paused", schedule: "Every day · 10:00 PM–7:00 AM next day", apps: 3, websites: 2, pauseUntil: "2:35 PM" },
    // This fixture has an unexpired pause value. Disabled takes precedence,
    // so the row belongs in Disabled and does not show the pause expiry.
    { name: "Social Break", state: "disabled", schedule: "Weekdays · 12:00 PM–1:00 PM", apps: 2, websites: 0, pauseUntil: "2:35 PM" },
  ],
};

const stateOrder = ["active", "paused", "upcoming", "disabled"];
const stateLabels = { active: "Active", paused: "Paused", upcoming: "Upcoming", disabled: "Disabled" };
const content = document.querySelector("#rules-content");
const scrollArea = document.querySelector("#app-scroll");
const toast = document.querySelector("#prototype-toast");
let toastTimer;

function icon(name, className = "icon") {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("class", className);
  svg.setAttribute("aria-hidden", "true");
  const use = document.createElementNS("http://www.w3.org/2000/svg", "use");
  use.setAttribute("href", `#${name}`);
  svg.append(use);
  return svg;
}

function targetSummary(rule) {
  const parts = [];
  if (rule.apps) parts.push(`${rule.apps} ${rule.apps === 1 ? "app" : "apps"}`);
  if (rule.websites) parts.push(`${rule.websites} ${rule.websites === 1 ? "website" : "websites"}`);
  return parts.join(" · ");
}

function createRuleRow(rule) {
  const row = document.createElement("button");
  row.type = "button";
  row.className = "rule-row";
  const parts = [rule.name, rule.schedule, targetSummary(rule)];

  const name = document.createElement("span");
  name.className = "rule-name";
  name.textContent = rule.name;

  const schedule = document.createElement("span");
  schedule.className = "rule-schedule";
  schedule.textContent = rule.schedule;

  const counts = document.createElement("span");
  counts.className = "rule-counts";
  counts.textContent = targetSummary(rule);

  row.append(name, icon("icon-chevron", "icon rule-chevron"), schedule, counts);
  if (rule.state === "active") {
    const countdown = document.createElement("span");
    countdown.className = "active-countdown";
    countdown.textContent = `Ends in ${rule.timeRemaining}`;
    parts.push(countdown.textContent);
    row.append(countdown);
  }
  if (rule.state === "paused") {
    const expiry = document.createElement("span");
    expiry.className = "pause-expiry";
    expiry.textContent = `Paused until ${rule.pauseUntil}`;
    parts.push(expiry.textContent);
    row.append(expiry);
  }
  parts.push("Opens rule details");
  row.setAttribute("aria-label", parts.join(". "));
  row.addEventListener("click", () => showToast(`Open rule details: ${rule.name}`));
  return row;
}

function createSection(state, rules) {
  if (!rules.length) return null;
  const section = document.createElement("section");
  section.className = "rule-section";
  section.dataset.state = state;

  const heading = document.createElement("header");
  heading.className = "section-heading";
  const title = document.createElement("h3");
  title.textContent = stateLabels[state];
  const count = document.createElement("span");
  count.className = "section-count";
  count.textContent = String(rules.length);
  count.setAttribute("aria-label", `${rules.length} ${rules.length === 1 ? "rule" : "rules"}`);
  heading.append(title, count);

  const group = document.createElement("div");
  group.className = "rule-group";
  group.setAttribute("role", "group");
  group.setAttribute("aria-label", `${stateLabels[state]} rules`);
  rules
    .slice()
    .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }))
    .forEach((rule) => group.append(createRuleRow(rule)));
  section.append(heading, group);
  return section;
}

function render(scenarioName) {
  const rules = scenarios[scenarioName] ?? scenarios.mixed;
  content.replaceChildren();
  if (!rules.length) {
    const empty = document.createElement("section");
    empty.className = "empty-state";
    empty.setAttribute("aria-labelledby", "empty-title");
    const symbol = document.createElement("span");
    symbol.className = "empty-symbol";
    symbol.append(icon("icon-rules"));
    const title = document.createElement("h3");
    title.id = "empty-title";
    title.textContent = "No rules yet";
    const description = document.createElement("p");
    description.textContent = "Rules let you set schedules for selected apps and websites.";
    empty.append(symbol, title, description);
    content.append(empty);
    return;
  }

  stateOrder.forEach((state) => {
    const section = createSection(state, rules.filter((rule) => rule.state === state));
    if (section) content.append(section);
  });
}

function showToast(message) {
  clearTimeout(toastTimer);
  toast.textContent = message;
  toast.classList.add("is-visible");
  toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 2400);
}

const params = new URLSearchParams(window.location.search);
const initialScenario = scenarios[params.get("scenario")] ? params.get("scenario") : "mixed";
render(initialScenario);
document.querySelectorAll("[data-scenario]").forEach((button) => {
  const selected = button.dataset.scenario === initialScenario;
  button.classList.toggle("is-selected", selected);
  button.setAttribute("aria-pressed", String(selected));
});

document.querySelectorAll("[data-scenario]").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll("[data-scenario]").forEach((candidate) => {
      const selected = candidate === button;
      candidate.classList.toggle("is-selected", selected);
      candidate.setAttribute("aria-pressed", String(selected));
    });
    const scenario = button.dataset.scenario;
    render(scenario);
    scrollArea.scrollTop = 0;
  });
});

document.querySelector("#add-rule").addEventListener("click", () => showToast("Open the rule editor"));

document.querySelectorAll(".tab[data-tab]").forEach((tab) => {
  tab.addEventListener("click", (event) => {
    event.preventDefault();
    showToast(`${tab.dataset.tab} tab is outside this prototype`);
  });
});
