/**
 * Today screen interaction plan.
 *
 * This file supplies review fixtures, not production rule evaluation. The SwiftUI
 * screen should consume a view model derived from RuleEvaluator and enforcement
 * status. See README.md for the exact component and state mapping.
 */

const DEMO_TIME = "2026-10-12T12:20";

const reviewScenarios = {
  overlap: { time: DEMO_TIME, mode: "normal" },
  quiet: { time: "2026-10-12T18:30", mode: "normal" },
  paused: { time: DEMO_TIME, mode: "paused" },
  unavailable: { time: DEMO_TIME, mode: "unavailable" },
  "no-rules": { time: DEMO_TIME, mode: "no-rules" },
};

const icons = {
  globe: '<svg class="icon" aria-hidden="true"><use href="#icon-globe" /></svg>',
  clock: '<svg class="icon" aria-hidden="true"><use href="#icon-clock" /></svg>',
  plus: '<svg class="icon" aria-hidden="true"><use href="#icon-plus" /></svg>',
  chevron: '<svg class="icon target-chevron" aria-hidden="true"><use href="#icon-arrow" /></svg>',
};

const elements = {
  date: document.querySelector("#today-date"),
  summary: document.querySelector("#summary"),
  summaryStatus: document.querySelector("#summary-status"),
  summaryTitle: document.querySelector("#summary-title"),
  summaryDescription: document.querySelector("#summary-description"),
  previewLabel: document.querySelector("#preview-time-label"),
  previewInput: document.querySelector("#preview-datetime"),
  targetHeading: document.querySelector("#targets-title"),
  targetCount: document.querySelector("#target-count"),
  targetList: document.querySelector("#target-list"),
  nextCard: document.querySelector("#next-change"),
  nextIcon: document.querySelector("#next-icon-use"),
  nextLabel: document.querySelector("#next-label"),
  nextTitle: document.querySelector("#next-title"),
  nextDescription: document.querySelector("#next-description"),
  toast: document.querySelector("#prototype-toast"),
};

let selectedTime = DEMO_TIME;
let selectedMode = "normal";
let toastTimer;

function formatDate(date, options) {
  return new Intl.DateTimeFormat("en-US", options).format(date);
}

function atTime(date, hour, minute = 0, dayOffset = 0) {
  const result = new Date(date);
  result.setDate(result.getDate() + dayOffset);
  result.setHours(hour, minute, 0, 0);
  return result;
}

function formatNext(date) {
  return formatDate(date, { hour: "numeric", minute: "2-digit" });
}

function appTarget(name, reasons, status = "simulated") {
  return { kind: "app", name, type: "Sample app · example only", reasons, status };
}

function siteTarget(name, scope, reasons, status = "simulated") {
  return { kind: "site", name, type: scope, reasons, status };
}

/** Returns the information the Today view needs, with no markup. */
function todayViewState(date, mode) {
  const weekday = date.getDay() >= 1 && date.getDay() <= 5;
  const hour = date.getHours() + date.getMinutes() / 60;
  const workHours = weekday && hour >= 9 && hour < 17;
  const lunch = weekday && hour >= 12 && hour < 13;
  const evening = hour >= 22 || hour < 7;

  if (mode === "no-rules") {
    return {
      tone: "inactive", title: "A fresh start", description: "Create a rule to see your boundaries here.",
      heading: "Restricted in preview", targets: [], empty: "no-rules",
      nextLabel: "SCHEDULE", nextTitle: "No changes scheduled", nextDescription: "Your next change will appear after you create a rule.",
    };
  }

  if (mode === "unavailable") {
    return {
      tone: "error", title: "2 targets need attention", description: "Rules are scheduled, but this device cannot enforce them.",
      heading: "Unable to enforce", targets: [
        appTarget("Sample App A", ["Work Hours", "Lunch"], "unavailable"),
        siteTarget("youtube.com", "This domain + subdomains", ["Work Hours"], "unavailable"),
      ],
      nextLabel: "ACTION NEEDED", nextTitle: "Check access", nextDescription: "Open Settings to restore the permission or extension needed for blocking.",
    };
  }

  if (mode === "paused" && workHours && lunch) {
    return {
      tone: "paused", title: "1 target stays restricted", description: "Work Hours is paused until 12:35 PM. Lunch still applies.",
      heading: "Restricted in preview", targets: [appTarget("Sample App A", ["Lunch"])],
      nextTitle: "12:35 PM · Work Hours resumes", nextDescription: "Sample App A stays restricted; youtube.com would become restricted again.",
    };
  }

  if (evening) {
    const next = hour >= 22 ? atTime(date, 7, 0, 1) : atTime(date, 7);
    return {
      tone: "active", title: "2 targets would be restricted", description: "Evening Wind Down is active in this preview.",
      heading: "Restricted in preview", targets: [
        appTarget("Sample App B", ["Evening Wind Down"]),
        siteTarget("instagram.com", "Exact host", ["Evening Wind Down"]),
      ],
      nextTitle: `${formatNext(next)} · Wind Down ends`, nextDescription: "Both targets would become available again.",
    };
  }

  if (workHours) {
    const next = lunch ? atTime(date, 13) : atTime(date, hour < 12 ? 12 : 17);
    return {
      tone: "active", title: "2 targets would be restricted", description: lunch ? "Two active rules shape your afternoon." : "Work Hours is active in this preview.",
      heading: "Restricted in preview", targets: [
        appTarget("Sample App A", lunch ? ["Work Hours", "Lunch"] : ["Work Hours"]),
        siteTarget("youtube.com", "This domain + subdomains", ["Work Hours"]),
      ],
      nextTitle: lunch ? `${formatNext(next)} · Lunch ends` : hour < 12 ? `${formatNext(next)} · Lunch begins` : `${formatNext(next)} · Work Hours ends`,
      nextDescription: lunch ? "Sample App A stays restricted by Work Hours." : hour < 12 ? "Lunch adds another reason for Sample App A." : "Both targets would become available until evening.",
    };
  }

  const next = weekday && hour < 9 ? atTime(date, 9) : atTime(date, 22);
  return {
    tone: "inactive", title: "Nothing restricted now", description: "Your boundaries are ready for the next scheduled window.",
    heading: "Restricted in preview", targets: [], empty: "quiet",
    nextTitle: weekday && hour < 9 ? `${formatNext(next)} · Work Hours begins` : `${formatNext(next)} · Wind Down begins`,
    nextDescription: weekday && hour < 9 ? "Sample App A and youtube.com would become restricted." : "Sample App B and instagram.com would become restricted.",
  };
}

function createTargetCard(target) {
  const card = document.createElement("article");
  card.className = `target-card${target.status === "unavailable" ? " is-unavailable" : ""}`;
  const ruleCount = target.reasons.length;
  const statusText = target.status === "unavailable" ? "Unable to enforce" : `${ruleCount} ${ruleCount === 1 ? "rule" : "rules"}`;
  const reasonText = target.status === "unavailable" ? "Scheduled · access needed" : target.reasons.join(" + ");
  const actionText = target.status === "unavailable" ? "How to fix" : target.kind === "site" ? "Check host" : "Why blocked";
  card.innerHTML = `
    <div class="target-main">
      <span class="target-icon ${target.kind}">${target.kind === "site" ? icons.globe : target.name.slice(-1)}</span>
      <span class="target-name-group"><span class="target-name">${target.name}</span><span class="target-type">${target.type}</span></span>
      ${icons.chevron}
    </div>
    <div class="target-foot">
      <span><span class="rule-pill${target.status === "unavailable" ? " is-warning" : ""}">${statusText}</span><br /><span class="target-reasons">${reasonText}</span></span>
      <button class="text-link" type="button" data-target-action="${actionText}" aria-label="${actionText}: ${target.name}">${actionText}</button>
    </div>`;
  return card;
}

function createEmptyState(kind) {
  const state = document.createElement("div");
  state.className = "empty-state";
  state.innerHTML = kind === "no-rules"
    ? `<span class="empty-symbol">${icons.plus}</span><h4>No rules yet</h4><p>Choose an app or website and a schedule to create your first boundary.</p><button class="text-link" type="button" data-target-action="Create rule">Create rule →</button>`
    : `<span class="empty-symbol">${icons.clock}</span><h4>Nothing active at this time</h4><p>Your next scheduled change is shown below.</p>`;
  return state;
}

function render() {
  const date = new Date(selectedTime);
  const state = todayViewState(date, selectedMode);
  elements.date.textContent = formatDate(date, { weekday: "long", month: "long", day: "numeric" }).toUpperCase();
  elements.previewLabel.textContent = formatDate(date, { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
  elements.previewInput.value = selectedTime;
  elements.summary.dataset.tone = state.tone;
  elements.summaryStatus.textContent = state.empty === "no-rules" ? "No rules" : { active: "Active", paused: "Paused", inactive: "Inactive", error: "Alert" }[state.tone];
  elements.summaryTitle.textContent = state.title;
  elements.summaryDescription.textContent = state.description;
  document.querySelector(".targets-section").dataset.tone = state.tone;
  elements.targetHeading.textContent = state.heading;
  elements.targetCount.textContent = String(state.targets.length);
  elements.targetList.replaceChildren(...(state.targets.length ? state.targets.map(createTargetCard) : [createEmptyState(state.empty)]));
  elements.nextLabel.textContent = state.nextLabel || "NEXT EXPECTED CHANGE";
  elements.nextIcon.setAttribute("href", state.tone === "error" ? "#icon-alert" : "#icon-calendar");
  elements.nextTitle.textContent = state.nextTitle;
  elements.nextDescription.textContent = state.nextDescription;
  elements.nextCard.dataset.tone = state.tone;
}

function showToast(message) {
  clearTimeout(toastTimer);
  elements.toast.textContent = message;
  elements.toast.classList.add("is-visible");
  toastTimer = setTimeout(() => elements.toast.classList.remove("is-visible"), 2800);
}

document.querySelectorAll("[data-scenario]").forEach((button) => {
  button.addEventListener("click", () => {
    const scenario = reviewScenarios[button.dataset.scenario];
    selectedTime = scenario.time;
    selectedMode = scenario.mode;
    document.querySelectorAll("[data-scenario]").forEach((candidate) => {
      const selected = candidate === button;
      candidate.classList.toggle("is-selected", selected);
      candidate.setAttribute("aria-pressed", String(selected));
    });
    render();
    document.querySelector(".app-scroll").scrollTop = 0;
  });
});

elements.previewInput.addEventListener("change", (event) => {
  if (!event.target.value) return;
  selectedTime = event.target.value;
  selectedMode = "normal";
  document.querySelectorAll("[data-scenario]").forEach((button) => {
    button.classList.remove("is-selected");
    button.setAttribute("aria-pressed", "false");
  });
  render();
});

document.querySelector("#reset-preview").addEventListener("click", () => {
  document.querySelector('[data-scenario="overlap"]').click();
  document.querySelector("#preview-control").open = false;
});

document.querySelector("#add-rule-button").addEventListener("click", () => showToast("Rule editor will be a separate mockup."));
elements.targetList.addEventListener("click", (event) => {
  const action = event.target.closest("[data-target-action]");
  if (action) showToast(`${action.dataset.targetAction} will open a separate screen mockup.`);
});
document.querySelectorAll("[data-future-tab]").forEach((button) => {
  button.addEventListener("click", () => showToast(`${button.dataset.futureTab} will be a separate screen mockup.`));
});

// A direct URL can open a review fixture: index.html?scenario=paused.
const requestedScenario = new URLSearchParams(window.location.search).get("scenario");
if (requestedScenario && reviewScenarios[requestedScenario]) {
  document.querySelector(`[data-scenario="${requestedScenario}"]`).click();
} else {
  render();
}
