// Presentation only: retain amounts and conditions, translate known facility labels.
function dealAmenityDetail(label, detail) {
  const translations = {
    'wifi available':'Wifi','wifi':'Wifi','wi-fi':'Wifi','parking':'Parkeren',
    'accessible parking':'Toegankelijk parkeren','parking garage':'Parkeergarage',
    'self parking':'Zelf parkeren','private parking':'Privéparkeerplaats',
    'welcome drink':'Welkomstdrankje','late check-out':'Late check-out',
    'paid':'Tegen betaling'
  };
  const parts = String(detail || '').split(' · ');
  const status = parts.shift() || '';
  const rest = parts.map(text => translations[text.toLowerCase()] || text
    .replace(/if available|subject to availability/gi,'afhankelijk van beschikbaarheid')
    .replace(/on request|upon request/gi,'op aanvraag')
    .replace(/surcharge/gi,'toeslag'));
  return [status,...new Set(rest.filter(text => text.toLowerCase() !== String(label).toLowerCase() && text.toLowerCase() !== status.toLowerCase()))].join(' · ');
}
if (typeof module !== 'undefined') module.exports = {dealAmenityDetail};
