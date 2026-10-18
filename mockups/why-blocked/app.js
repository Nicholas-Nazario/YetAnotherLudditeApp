/* Local review fixtures only. Swift remains the rule-evaluation source of truth. */
const $ = (selector) => document.querySelector(selector);
const work = { id: "work", name: "Work Hours", schedule: "Weekdays · 9:00 AM–5:00 PM", end: "5:00 PM", host: "youtube.com", scope: "subdomains" };
const lunch = { id: "lunch", name: "Lunch", schedule: "Every day · 12:00 PM–1:00 PM", end: "1:00 PM", host: "m.youtube.com", scope: "exact" };
const fixtures = {
  overlap: { rules: [work, lunch] },
  single: { rules: [work] },
  website: { website: true, host: "m.youtube.com", rules: [work, lunch] },
  none: { rules: [] },
  many: { rules: [work, lunch, ...Array.from({ length: 6 }, (_, i) => ({ id: `extra-${i}`, name: `Focus boundary ${i + 1} · Reading, writing, and uninterrupted project time`, schedule: "Weekdays · 10:00 AM–6:00 PM", end: "6:00 PM" }))] },
  error: { error: true, rules: [] },
};
let scenario, fixture, checkedHost, paused = new Set(), ended = false, pendingRule, clockMinutes = 12 * 60 + 20;
const escapeHTML = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
function matchingRules() {
  return fixture.rules.filter((rule) => !paused.has(rule.id) && !(ended && rule.id === "lunch") && (!fixture.website || checkedHost === rule.host || (rule.scope === "subdomains" && checkedHost.endsWith(`.${rule.host}`))));
}
function render() {
  const rules = matchingRules();
  $("#target-kind").textContent = fixture.website ? "Checked host" : "Sample app";
  $("#target-name").textContent = fixture.website ? checkedHost : "Sample App A";
  $("#target-badge").textContent = fixture.website ? "◎" : "A";
  $("#target-note").textContent = fixture.website ? "The website and its www version are treated as equivalent. Other subdomains may differ." : "Example identity, not an app installed on your phone.";
  $("#website-inspector").hidden = !fixture.website;
  $("#result-card").hidden = !!fixture.error;
  $("#rules-section").hidden = !!fixture.error || !rules.length;
  $("#timing-note").hidden = !!fixture.error;
  $("#data-error").hidden = !fixture.error;
  $("#result-card").classList.toggle("is-clear", !rules.length);
  $("#result-label").textContent = ended ? "Simulated state · 1:00 PM" : "Simulated state · 12:20 PM";
  $("#result-title").textContent = rules.length ? `Restricted by ${rules.length} ${rules.length === 1 ? "rule" : "rules"}` : "No active restriction";
  $("#result-copy").textContent = rules.length ? "This target remains restricted while any listed rule applies. Pausing one rule may leave others in effect." : "No active rule restricts this target now. Paused, disabled, and rules outside their scheduled hours do not apply.";
  $("#rule-list").innerHTML = rules.map((rule) => `<article class="reason-card"><a class="reason-link" href="../rule-detail/index.html" data-detail="${escapeHTML(rule.id)}"><h4>${escapeHTML(rule.name)}</h4><p>${escapeHTML(rule.schedule)}</p><p class="end-time">Current window ends today at ${escapeHTML(rule.end)}</p>${fixture.website ? `<p>${rule.scope === "subdomains" ? `Matches ${escapeHTML(rule.host)} and its subdomains` : `Matches ${escapeHTML(rule.host)} and its www version`}</p>` : ""}<span class="chevron" aria-hidden="true">›</span></a><div class="reason-footer"><span>Applies now</span><button class="pause-action" data-pause="${escapeHTML(rule.id)}" aria-label="Pause ${escapeHTML(rule.name)}">Pause…</button></div></article>`).join("");
  $("#advance").disabled = !!fixture.error || ended || !rules.some((r) => r.id === "lunch");
}
function selectScenario(key) {
  scenario = fixtures[key] ? key : "overlap";
  fixture = fixtures[scenario]; checkedHost = fixture.host; paused = new Set(); ended = false; clockMinutes = 740;
  $("#address-details").open = false;
  $("#address-error").hidden = true;
  $("#address").removeAttribute("aria-invalid");
  $("#address").value = checkedHost || "";
  $("#app-scroll").scrollTop = 0;
  document.querySelectorAll("[data-scenario]").forEach((button) => { const selected = button.dataset.scenario === scenario; button.classList.toggle("is-selected", selected); button.setAttribute("aria-pressed", selected); });
  render();
}
function normalizeHost(input) {
  if (!input.trim()) throw Error("Enter a website domain or URL.");
  if (input.includes("*")) throw Error("Enter a concrete host, such as m.youtube.com, rather than a wildcard.");
  let url;
  try { url = new URL(input.includes("://") ? input.trim() : `https://${input.trim()}`); } catch { throw Error("Enter a valid domain, such as youtube.com."); }
  const host = url.hostname.toLowerCase().replace(/^\.+|\.+$/g, "").replace(/^www\./, "");
  if (url.username || url.password || !["http:", "https:"].includes(url.protocol) || host.length > 253 || host.split(".").length < 2 || host.split(".").some((part) => part.length > 63 || !/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/.test(part))) throw Error("Enter a valid domain. Use ASCII or Punycode for international domains.");
  return host;
}
$("#address-form").addEventListener("submit", (event) => {
  event.preventDefault();
  try {
    checkedHost = normalizeHost($("#address").value);
    $("#address-error").hidden = true; $("#address").removeAttribute("aria-invalid"); render();
  } catch (error) {
    $("#address-error").textContent = `${error.message} The result still describes ${checkedHost}.`;
    $("#address-error").hidden = false; $("#address").setAttribute("aria-invalid", "true"); $("#address").focus();
  }
});
function timeLabel(minutes) { const hour = Math.floor(minutes / 60); return `${hour % 12 || 12}:${String(minutes % 60).padStart(2, "0")} ${hour >= 12 ? "PM" : "AM"}`; }
function updatePause() {
  $("#pause-timing").textContent = `Pause ends today at ${timeLabel(clockMinutes + Number($("#pause-duration").value))}.`;
  const others = matchingRules().filter((rule) => rule.id !== pendingRule.id);
  $("#pause-effect").textContent = others.length ? `${fixture.website ? checkedHost : "Sample App A"} would remain restricted by ${others.map((rule) => rule.name).join(", ")}.` : `${fixture.website ? checkedHost : "Sample App A"} would be unrestricted now.`;
}
$("#rule-list").addEventListener("click", (event) => {
  const pause = event.target.closest("[data-pause]");
  if (pause) {
    pendingRule = matchingRules().find((rule) => rule.id === pause.dataset.pause);
    $("#pause-title").textContent = `Pause ${pendingRule.name}`;
    $("#pause-duration").value = "15"; updatePause(); $("#pause-dialog").showModal();
  }
  const detail = event.target.closest("[data-detail]");
  if (detail) { event.preventDefault(); toast("Prototype: open Rule detail for " + fixture.rules.find((r) => r.id === detail.dataset.detail).name + "."); }
});
$("#pause-duration").addEventListener("change", updatePause);
$("#confirm-pause").addEventListener("click", () => {
  paused.add(pendingRule.id); $("#pause-dialog").close(); render();
  $("#result-card").tabIndex = -1; $("#result-card").focus();
});
let toastTimer;
function toast(message) { clearTimeout(toastTimer); $("#prototype-toast").textContent = message; $("#prototype-toast").classList.add("is-visible"); toastTimer = setTimeout(() => $("#prototype-toast").classList.remove("is-visible"), 4000); }
$("#advance").addEventListener("click", () => { ended = true; clockMinutes = 780; render(); });
$("#retry").addEventListener("click", () => { selectScenario("overlap"); $("#result-card").tabIndex = -1; $("#result-card").focus(); });
$("#large-text").addEventListener("change", (event) => document.querySelector(".device-screen").classList.toggle("large-text", event.target.checked));
document.querySelectorAll("[data-scenario]").forEach((button) => button.addEventListener("click", () => selectScenario(button.dataset.scenario)));
selectScenario(new URLSearchParams(location.search).get("scenario"));
