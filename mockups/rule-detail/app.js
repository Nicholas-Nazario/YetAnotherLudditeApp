// Fixed review fixtures only. Native calculations remain in Shared/Rules.
const fixtures = {
  active: {name: 'Work Hours', state: 'active', days: 'Weekdays', time: '9:00 AM–5:00 PM', next: 'Ends today at 5:00 PM.', apps: ['Sample App A', 'Sample App B'], websites: [{host: 'youtube.com', scope: 'All subdomains'}]},
  upcoming: {name: 'Work Hours', state: 'upcoming', days: 'Weekdays', time: '9:00 AM–5:00 PM', next: 'Starts tomorrow at 9:00 AM.', apps: ['Sample App A', 'Sample App B'], websites: []},
  paused: {name: 'Work Hours', state: 'active', paused: true, days: 'Weekdays', time: '9:00 AM–5:00 PM', next: 'Ends today at 5:00 PM.', apps: ['Sample App A', 'Sample App B'], websites: [{host: 'youtube.com', scope: 'All subdomains'}]},
  disabled: {name: 'Work Hours', state: 'active', paused: true, disabled: true, days: 'Weekdays', time: '9:00 AM–5:00 PM', next: 'Ends today at 5:00 PM.', apps: ['Sample App A'], websites: [{host: 'youtube.com', scope: 'This website'}]},
  overnight: {name: 'Evening Quiet', state: 'active', days: 'Mon–Fri', time: '10:00 PM–7:00 AM next day', next: 'Ends tomorrow at 7:00 AM.', apps: ['Sample App C'], websites: [{host: 'reddit.com', scope: 'This website'}], overnight: true},
  long: {name: 'Space for reading, thinking, and a quieter evening', state: 'upcoming', days: 'Mon, Wed, Fri', time: '10:00 PM–7:00 AM next day', next: 'Starts Wednesday at 10:00 PM.', apps: ['Sample App A', 'Sample App B', 'Sample App C'], websites: [{host: 'a-long-community-name.example.com', scope: 'All subdomains'}, {host: 'youtube.com', scope: 'This website'}], overnight: true},
  error: {name: 'Work Hours', state: 'active', days: 'Weekdays', time: '9:00 AM–5:00 PM', next: 'Ends today at 5:00 PM.', apps: ['Sample App A'], websites: [], failure: true}
};
const content = document.querySelector('#detail-content');
let current;
let selected;
let toastTimer;
const escapeHTML = value => String(value).replace(/[&<>"']/g, char => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[char]));
function notify(message) {
  const toast = document.querySelector('#prototype-toast');
  toast.textContent = message;
  toast.classList.add('is-visible');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('is-visible'), 3500);
}
function render() {
  document.querySelector('#rule-title').textContent = current.name;
  const state = current.disabled ? 'disabled' : current.paused ? 'paused' : current.state;
  const labels = {active: 'Active', upcoming: 'Upcoming', paused: 'Paused', disabled: 'Disabled'};
  const count = `${current.apps.length} ${current.apps.length === 1 ? 'app' : 'apps'} and ${current.websites.length} ${current.websites.length === 1 ? 'website' : 'websites'}`;
  const descriptions = {active: `This rule would restrict ${count}.`, upcoming: 'Outside its scheduled hours.', paused: 'Paused until today at 12:35 PM.', disabled: 'This rule does not apply until you enable it.'};
  const next = state === 'disabled' ? (current.paused ? 'A pause is retained until today at 12:35 PM. Enabling before then keeps this rule paused.' : 'Enable this rule to use its schedule.') : state === 'paused' ? 'Scheduled restrictions resume at 12:35 PM; this window ends at 5:00 PM.' : current.next;
  content.innerHTML = `${current.failure ? '<div class="error-banner" role="alert"><strong>Couldn’t save your change.</strong><br>The rule is unchanged. Try again.</div>' : ''}
    <section class="detail-section rule-group status-card" aria-label="Current rule status">
      <span class="status-label ${state}">${labels[state]}</span><p class="status-description">${escapeHTML(descriptions[state])}</p><p class="next-change">${escapeHTML(next)}</p>
      ${state !== 'disabled' ? `<button class="primary-action ${state === 'paused' ? 'resume-action' : 'pause-action'}" id="pause-action">${state === 'paused' ? 'Resume now' : 'Pause rule'}</button>` : ''}
    </section>
    <section class="detail-section"><h3 class="section-label">Schedule</h3><div class="rule-group schedule-content"><p class="schedule-days">${escapeHTML(current.days)}</p><p class="schedule-time">${escapeHTML(current.time)}</p></div>${current.overnight ? '<p class="helper">Selected days are the days this schedule starts.</p>' : ''}</section>
    <section class="detail-section"><h3 class="section-label">Apps · ${current.apps.length}</h3><div class="rule-group">${current.apps.length ? current.apps.map(name => `<button class="target-row" data-app="${escapeHTML(name)}" aria-label="View current restriction explanation for ${escapeHTML(name)}"><span class="target-badge" aria-hidden="true">${escapeHTML(name.slice(-1))}</span><span class="target-copy"><strong>${escapeHTML(name)}</strong><small>View current restrictions</small></span><span class="chevron" aria-hidden="true">›</span></button>`).join('') : '<p class="empty-target">No apps in this rule.</p>'}</div><p class="helper">Simulator examples, not apps installed on your phone.</p></section>
    <section class="detail-section"><h3 class="section-label">Websites · ${current.websites.length}</h3><div class="rule-group">${current.websites.length ? current.websites.map(site => `<button class="target-row" data-host="${escapeHTML(site.host)}" aria-label="Check website for ${escapeHTML(site.host)}, ${escapeHTML(site.scope)}"><span class="target-copy"><strong>${escapeHTML(site.host)}</strong><small>${escapeHTML(site.scope)} · Check website</small></span><span class="chevron" aria-hidden="true">›</span></button>`).join('') : '<p class="empty-target">No websites in this rule.</p>'}</div><p class="helper">Other rules may still restrict these targets when this rule is paused, disabled, or deleted.</p></section>
    <section class="detail-section"><h3 class="section-label">Rule controls</h3><div class="rule-group"><div class="enabled-row"><div><strong id="enabled-label">Enabled</strong><small id="enabled-help">Turn off to stop this rule indefinitely.</small></div><label class="switch"><input id="enabled" type="checkbox" role="switch" aria-labelledby="enabled-label" aria-describedby="enabled-help" ${!current.disabled ? 'checked' : ''}><span class="switch-track" aria-hidden="true"></span></label></div></div></section>
    <section class="detail-section"><div class="rule-group"><button class="delete-row" id="delete">Delete rule</button></div></section>`;
  document.querySelector('#enabled').addEventListener('change', event => {
    if (current.failure) { render(); document.querySelector('#enabled').focus(); notify('Illustrative storage failure: rule unchanged.'); return; }
    current.disabled = !event.target.checked;
    render(); document.querySelector('#enabled').focus();
    notify(current.disabled ? 'Rule disabled in this review fixture.' : current.paused ? 'Rule enabled; retained pause still applies.' : 'Rule enabled in this review fixture.');
  });
  document.querySelector('#pause-action')?.addEventListener('click', () => {
    if (current.failure) { notify('Illustrative storage failure: rule unchanged.'); return; }
    if (current.paused) { current.paused = false; render(); document.querySelector('#pause-action').focus(); notify('Pause ended in this review fixture. Other rules still apply.'); }
    else notify('Destination: pause duration and overlap confirmation. No pause applied.');
  });
  document.querySelector('#delete').addEventListener('click', () => document.querySelector('#delete-dialog').showModal());
  content.querySelectorAll('[data-app]').forEach(button => button.addEventListener('click', () => notify(selected === 'active' && button.dataset.app === 'Sample App A' ? 'Explanation destination: Work Hours and Lunch both apply; Lunch ends at 1 PM, Work Hours at 5 PM.' : `Destination: current reasons for ${button.dataset.app}, across all rules.`)));
  content.querySelectorAll('[data-host]').forEach(button => button.addEventListener('click', () => notify(`Destination: website checker for ${button.dataset.host}.`)));
}
function selectScenario(name) {
  clearTimeout(toastTimer);
  document.querySelector('#prototype-toast').classList.remove('is-visible');
  selected = fixtures[name] ? name : 'active';
  current = structuredClone(fixtures[selected]);
  document.querySelectorAll('[data-scenario]').forEach(button => { const active = button.dataset.scenario === selected; button.classList.toggle('is-selected', active); button.setAttribute('aria-pressed', String(active)); });
  render(); document.querySelector('#app-scroll').scrollTop = 0;
}
document.querySelectorAll('[data-scenario]').forEach(button => button.addEventListener('click', () => selectScenario(button.dataset.scenario)));
document.querySelector('#edit').addEventListener('click', () => notify('Destination: edit this saved rule in the Rule editor.'));
document.querySelector('#settings').addEventListener('click', () => notify('Destination: Settings.'));
document.querySelector('#cancel-delete').addEventListener('click', () => document.querySelector('#delete-dialog').close());
document.querySelector('#confirm-delete').addEventListener('click', () => {
  document.querySelector('#delete-dialog').close();
  if (current.failure) { notify('Illustrative storage failure: rule was not deleted.'); return; }
  content.innerHTML = '<div class="empty-state"><h3>This rule has been deleted.</h3><p>In the native app, successful deletion returns to Rules.</p><a class="spec-link" href="../rules/index.html">Back to Rules</a></div>';
  document.querySelector('#edit').disabled = true;
});
document.querySelectorAll('[data-scenario]').forEach(button => button.addEventListener('click', () => { document.querySelector('#edit').disabled = false; }));
selectScenario(new URLSearchParams(location.search).get('scenario'));
