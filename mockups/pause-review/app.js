// Fixed developer fixtures, not production schedule or domain evaluation.
const appA = {name:'Sample App A', other:'Lunch until 1:00 PM.'};
const appB = {name:'Sample App B', other:null};
const website = {name:'youtube.com · All subdomains', addresses:[{host:'youtube.com + www',effect:'Would be unrestricted'},{host:'m.youtube.com',effect:'Still restricted · Mobile Break until 2 PM'}]};
const fixtures = {
 overlap:{name:'Work Hours', apps:[appA,appB], websites:[website]},
 clear:{name:'Work Hours', apps:[appB,{name:'Sample App C',other:null}],websites:[]},
 all:{name:'Work Hours',apps:[appA,{name:'Sample App B',other:'Study Time until 3:00 PM.'}],websites:[]},
 upcoming:{name:'Afternoon Focus',apps:[appA,appB],websites:[],upcoming:true},
 websites:{name:'Website Quiet',apps:[],websites:[website]},
 invalid:{name:'Work Hours',apps:[appA,appB],websites:[website],invalid:true},
 error:{name:'Work Hours',apps:[appA,appB],websites:[website],failure:true}
};
const $ = selector => document.querySelector(selector);
const escapeHTML = text => String(text).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let fixture, duration=15, custom=false, timer;
const anchor = new Date(2026,9,12,12,20);
function notify(text) { $('#prototype-toast').textContent=text; $('#prototype-toast').classList.add('is-visible'); clearTimeout(timer); timer=setTimeout(()=>$('#prototype-toast').classList.remove('is-visible'),4000); }
function updateTiming() {
 const hours=Number($('#custom-hours').value);
 const minutePart=Number($('#custom-minutes').value);
 const minutes=custom ? hours*60+minutePart : duration;
 const valid=Number.isInteger(minutes) && minutes>=15 && minutes<=1440;
 $('#custom-fields').hidden=!custom;
 $('#duration-error').hidden=valid;
 $('#duration-error').textContent=valid ? '' : hours===24 && minutePart>0 ? 'For 24 hours, choose 0 minutes.' : 'Choose at least 15 minutes and no more than 24 hours.';
 $('#custom-minutes').setAttribute('aria-invalid',String(!valid));
 $('#custom-hours').setAttribute('aria-invalid',String(!valid));
 $('#confirm').disabled=!valid;
 document.querySelectorAll('[data-minutes]').forEach(button=>button.setAttribute('aria-pressed',String(custom ? button.dataset.minutes==='custom' : Number(button.dataset.minutes)===duration)));
 if(!valid) { $('#pause-end').textContent='Choose a valid duration'; $('#schedule-note').textContent='Your chosen duration must be valid before confirming.'; return; }
 const end=new Date(anchor.getTime()+minutes*60000);
 const nextDay=end.getDate()!==anchor.getDate();
 $('#pause-end').textContent=`${nextDay ? 'Tomorrow' : 'Today'} at ${end.toLocaleTimeString('en-US',{hour:'numeric',minute:'2-digit'})}`;
 if(fixture.upcoming) {
   $('#schedule-note').textContent=minutes<=40 ? 'This pause ends before the 1:00 PM start. The next scheduled start stays today at 1:00 PM.' : minutes<220 ? 'The 1:00 PM start falls within this pause. Scheduled restrictions would begin when the pause ends.' : 'This pause covers the rest of today’s 1:00–4:00 PM window. Next scheduled start: tomorrow at 1:00 PM.';
 } else {
   const minuteOfDay=end.getHours()*60+end.getMinutes();
   const inWindow=minuteOfDay>=540 && minuteOfDay<1020;
   $('#schedule-note').textContent=inWindow ? 'This rule’s scheduled restrictions would resume then. Other rules still apply.' : 'The schedule is inactive when this pause ends. Next scheduled start: tomorrow at 9:00 AM.';
 }
}
function renderEffects() {
 const free=fixture.apps.filter(app=>!app.other).length, retained=fixture.apps.length-free;
 let lines=[];
 if(fixture.upcoming) lines.push('<p><strong>Nothing changes now.</strong><br>This rule is outside its scheduled hours.</p>');
 else {
  if(free) lines.push(`<p><strong>${free} ${free===1?'app':'apps'}</strong> would no longer be restricted.</p>`);
  if(retained) lines.push(`<p><strong>${retained} ${retained===1?'app':'apps'}</strong> would remain restricted by ${retained===1?'another rule':'other rules'}.</p>`);
 }
 if(fixture.websites.length) lines.push('<p>Website effects vary by address.</p>');
 $('#effect-summary').innerHTML=lines.join('');
 $('#target-list').innerHTML=fixture.apps.map(app=>`<div class="target-detail"><h4>${escapeHTML(app.name)}</h4><p>${fixture.upcoming ? 'This rule does not restrict this app now. ' : ''}${app.other ? `Would remain restricted by ${escapeHTML(app.other)}` : fixture.upcoming ? 'No other active rule restricts this app now.' : 'Would no longer be restricted. No other active rule includes this app.'}</p></div>`).join('')+fixture.websites.map(site=>`<div class="target-detail"><h4>${escapeHTML(site.name)}</h4><dl class="website-effects">${site.addresses.map(address=>`<div><dt>${escapeHTML(address.host)}</dt><dd>${escapeHTML(address.effect)}</dd></div>`).join('')}</dl></div>`).join('')+(fixture.websites.length ? '<p class="website-note">Other addresses may differ.</p>' : '');
}
function selectScenario(name) {
 const selected=fixtures[name] ? name : 'overlap'; fixture=fixtures[selected]; duration=15;custom=!!fixture.invalid;
 $('#custom-hours').value='0';
 $('#custom-minutes').value=fixture.invalid?'5':'15';
 $('#rule-title').textContent=fixture.name;
 $('#target-details').open=false;
 $('#save-error').hidden=true;
 $('#confirm').hidden=false;
 $('#confirm').textContent='Confirm pause';
 $('#prototype-toast').classList.remove('is-visible');
 document.querySelectorAll('[data-scenario]').forEach(button=>{const on=button.dataset.scenario===selected;button.setAttribute('aria-pressed',String(on));button.classList.toggle('is-selected',on);});
 updateTiming();renderEffects();$('#app-scroll').scrollTop=0;
}
document.querySelectorAll('[data-minutes]').forEach(button=>button.addEventListener('click',()=>{custom=button.dataset.minutes==='custom';if(!custom)duration=Number(button.dataset.minutes);updateTiming();if(custom)$('#custom-hours').focus();}));
$('#custom-hours').addEventListener('change',updateTiming);
$('#custom-minutes').addEventListener('change',updateTiming);
document.querySelectorAll('[data-scenario]').forEach(button=>button.addEventListener('click',()=>selectScenario(button.dataset.scenario)));
$('#cancel').addEventListener('click',()=>notify('Return to Rule detail. No pause applied in this review.'));
$('#confirm').addEventListener('click',()=>{
 if(fixture.failure) { $('#save-error').hidden=false;$('#save-error').textContent='Couldn’t save the pause. The rule is unchanged. Your chosen duration is kept; try again.';$('#save-error').scrollIntoView({block:'nearest'});return; }
 notify('Review success: the native sheet would close and Rule detail would show the saved pause.');
});
$('#custom-hours').innerHTML=Array.from({length:25},(_,i)=>`<option value="${i}">${i}</option>`).join('');
$('#custom-minutes').innerHTML=Array.from({length:60},(_,i)=>`<option value="${i}">${String(i).padStart(2,'0')}</option>`).join('');
selectScenario(new URLSearchParams(location.search).get('scenario'));
