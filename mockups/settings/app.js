/* Review fixtures only. No file operations, persistence, or requests. */
const $ = (selector) => document.querySelector(selector);
const scenarios = ["default", "empty", "unreadable", "delete-error", "deleting"];
let scenario, count, unreadable, deleting, deletionFailed, deleted, operationTimer;

function render() {
  $("#rule-count").textContent = unreadable ? "Unavailable" : String(count);
  $("#storage-error").hidden = !unreadable;
  $("#delete-rules").disabled = deleting || (!unreadable && count === 0);
  $("#delete-rules").textContent = deleting ? "Deleting local rules…" : "Delete all local rules…";
  $("#data-note").textContent = !unreadable && count === 0 ? "No local rules are saved on this device." : "Deletes all rules, including their schedules, targets, and pauses. This can’t be undone.";
  $("#operation-status").hidden = !deleting && !deleted;
  $("#operation-status").textContent = deleting ? "Removing local rule data…" : "All local rules deleted. Simulated restrictions are cleared.";
  $("#delete-error").hidden = !deletionFailed;
  $("#data-title").closest("section").setAttribute("aria-busy", String(deleting));
}

function selectScenario(key) {
  clearTimeout(operationTimer);
  if ($("#delete-dialog").open) $("#delete-dialog").close();
  scenario = scenarios.includes(key) ? key : "default";
  count = scenario === "empty" ? 0 : 4;
  unreadable = scenario === "unreadable";
  deleting = scenario === "deleting";
  deletionFailed = deleted = false;
  document.querySelectorAll("[data-scenario]").forEach((button) => {
    const selected = button.dataset.scenario === scenario;
    button.classList.toggle("is-selected", selected);
    button.setAttribute("aria-pressed", String(selected));
  });
  $("#app-scroll").scrollTop = 0;
  render();
}

$("#delete-rules").addEventListener("click", () => {
  $("#dialog-copy").textContent = unreadable
    ? "This permanently deletes the unreadable local rule file so you can start again. Its rule count is unknown. This can’t be undone."
    : `This permanently deletes all ${count} saved ${count === 1 ? "rule" : "rules"}, including schedules, targets, and pauses, and clears simulated restrictions. This can’t be undone.`;
  $("#delete-dialog").showModal();
});
$("#cancel-delete").addEventListener("click", () => $("#delete-dialog").close());
$("#confirm-delete").addEventListener("click", () => {
  $("#delete-dialog").close();
  deleting = true; deleted = deletionFailed = false; render();
  // Short review-only delay to expose the pending state, not a native requirement.
  operationTimer = setTimeout(() => {
    deleting = false;
    if (scenario === "delete-error") deletionFailed = true;
    else { count = 0; unreadable = false; deleted = true; }
    render();
    const result = $(deletionFailed ? "#delete-error" : "#operation-status");
    result.tabIndex = -1; result.focus();
  }, 350);
});
$("#large-text").addEventListener("change", (event) => {
  document.querySelector(".device-screen").classList.toggle("large-text", event.target.checked);
  $("#delete-dialog").classList.toggle("large-dialog", event.target.checked);
});
document.querySelectorAll("[data-scenario]").forEach((button) => button.addEventListener("click", () => selectScenario(button.dataset.scenario)));
selectScenario(new URLSearchParams(location.search).get("scenario"));
