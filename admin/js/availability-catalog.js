(() => {
  'use strict';
  const core=window.AdminCore,branch='nuitee-availability-2026-10-08';
  const cards=document.getElementById('availability-cards'),summary=document.getElementById('availability-summary');
  let catalog,rows=[],expiryTimer;
  async function init(){
    const admin=await core.requireAuth();if(!admin)return;
    core.mountShell({active:'suppliers',title:'Actuele aanbodtest',subtitle:'Beveiligde sandboxcatalogus — geen publieke voorraad of boekingen.'},admin);
    if(!['superadmin','platform_admin'].includes(admin.role))throw Error('Je rol mag deze test niet uitvoeren.');
    const deals=(await window.AdminOfferData.all('/deals')).filter(d=>d.source==='provider_sync' && d.status==='active' && d.approved_at && !d.deleted_at);
    for(const deal of deals){const detail=await core.request('/supplier-deals/'+encodeURIComponent(deal.id),{headers:{'X-Branch':branch},cache:'no-store'});if(detail.supplier_deal?.provider==='nuitee' && detail.supplier_deal.environment==='sandbox')rows.push({...deal,supplier:detail.supplier_deal});}
    catalog=window.SeasonDealsAvailabilityCatalog.createCatalog({request:async deal=>{
      const input=deal.supplier.supplier_mapping?.request;if(!input)throw Error('Mapping ontbreekt.');
      const abort=new AbortController(),timeout=setTimeout(()=>abort.abort(),20000);
      try{return await core.request('/supplier-deals/'+encodeURIComponent(deal.id)+'/availability?'+new URLSearchParams({checkin:input.checkin,checkout:input.checkout,guests:input.occupancies?.[0]?.adults}),{signal:abort.signal,headers:{'X-Branch':branch},cache:'no-store'});}finally{clearTimeout(timeout);}
    },render:(available,states)=>{
      summary.textContent=available.length+' van '+states.length+' goedgekeurde sandboxdeals actueel beschikbaar voor hun opgeslagen verblijfsdata. Controle iedere 45 seconden; dit reserveert geen kamer.';
      cards.replaceChildren();
      for(const deal of available){const card=document.createElement('article');card.className='panel';const hotel=deal.supplier.supplier_content?.hotel;const image=core.imageUrl(deal.images)||core.imageUrl(deal.external_image_urls);if(image){const img=document.createElement('img');img.src=image;img.alt=hotel?.name||deal.title;img.style.cssText='width:100%;height:200px;object-fit:cover';card.append(img);}const title=document.createElement('h2');title.textContent=hotel?.name||deal.title;const price=document.createElement('p');price.textContent=core.money(deal.price)+' · actueel beschikbaar · exact kameraantal niet geleverd';const link=document.createElement('a');link.className='secondary-button';link.href='../nuitee-availability-preview.html?portal=admin&id='+encodeURIComponent(deal.id);link.textContent='Verblijf controleren';card.append(title,price,link);cards.append(card);}
      if(!available.length){const empty=document.createElement('p');empty.textContent='Geen vers bevestigd aanbod om te tonen. Deals worden niet verwijderd of afgekeurd; na een geslaagde controle verschijnen ze opnieuw.';cards.append(empty);}
    }});
    document.getElementById('availability-refresh').addEventListener('click',()=>catalog.refresh(rows));
    document.addEventListener('visibilitychange',()=>{if(!document.hidden)catalog.refresh(rows);});
    expiryTimer=setInterval(()=>catalog.expire(),1000);
    window.addEventListener('pagehide',()=>{catalog.dispose();clearInterval(expiryTimer);},{once:true});
    await catalog.refresh(rows);
  }
  init().catch(e=>{summary.textContent=e.message;cards.replaceChildren();});
})();
