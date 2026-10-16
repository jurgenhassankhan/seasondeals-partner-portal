const {test}=require('node:test');
const assert=require('node:assert/strict');
const {dealAmenityDetail}=require('../backend/nuitee/amenity-label.js');
test('live supplier labels become concise Dutch while preserving fees and conditions',()=>{
 assert.equal(dealAmenityDetail('Wifi','Beschikbaar; kosten niet bevestigd · WiFi available · WiFi'),'Beschikbaar; kosten niet bevestigd');
 assert.equal(dealAmenityDetail('Parkeren','Tegen betaling · Parking · Accessible parking · Parking garage · PAID'),'Tegen betaling · Toegankelijk parkeren · Parkeergarage');
 assert.match(dealAmenityDetail('Parkeren','Tegen betaling · EUR 25 per day'),/EUR 25 per day/);
 assert.match(dealAmenityDetail('Late check-out','Onder voorwaarden · Late check-out if available'),/afhankelijk van beschikbaarheid/);
});
