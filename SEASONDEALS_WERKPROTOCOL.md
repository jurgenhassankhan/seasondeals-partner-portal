# Vast protocol — wijzigingen en livegang

Eigenaar: SeasonDeals. Vastgelegd op verzoek van Jurgen, 11 oktober 2026.

## Twee bestanden, twee vragen

- [SEASONDEALS_STATUS.md](SEASONDEALS_STATUS.md): wat is gebouwd en aantoonbaar getest?
- [SEASONDEALS_LIVEGANG.md](SEASONDEALS_LIVEGANG.md): wat draait waar, wat moet nog over en wat blijft achter?

Dit protocol geldt bij iedere volgende code-, Xano-, Webflow-, Stripe-, Resend- of configuratiewijziging. Lees beide bestanden bij de start van een werksessie. Een chat of de naam van een branch is geen releasebewijs.

## Bij iedere wijziging

1. Zoek de bijbehorende vaste ID in de liveganglijst of voeg een nieuwe rij toe.
2. Noteer vóór de wijziging de bron en bestemming: repository/branch/bestand en commit, of Xano-workspace/branch/type/naam/ID. Bij Xano ook vermelden of het om een draft of gepubliceerde versie gaat.
3. Noteer afhankelijkheden, wat wel en niet wordt overgezet en de terugvalmogelijkheid. Ontbrekende gegevens krijgen letterlijk **TE VERIFIËREN**, nooit een gok.
4. Voer het geautoriseerde werk uit. Test alleen de relevante wijziging en concrete risico's. Een al bewezen sandboxstap wordt niet opnieuw opengezet omdat productie nog wacht.
5. Werk **zowel status als liveganglijst** bij vóór de afsluitende terugkoppeling. Verwijs naar hetzelfde bewijs en dezelfde release-ID. Noteer bij alleen documentatiewerk expliciet dat geen software of configuratie is uitgerold.
6. Meld kort: gewijzigd, getest, waar actief en wat nog openstaat. Bij een blokkade ook de exacte blokkade en eerstvolgende actie vastleggen.

Bij een PR horen de documentwijzigingen bij dezelfde PR. Als backendpublicatie en GitHub niet tegelijk kunnen gebeuren, registreer de werkelijke tussenstand direct en vul de definitieve controle daarna aan. Een uitgevoerde deployment mag niet ongemerkt als “nog over te zetten” blijven staan.

## Statussen hebben elk een eigen betekenis

Houd drie zaken apart:
- **Bouw/test:** open, gebouwd, sandbox bewezen, of productie bewezen.
- **Plaatsing:** alleen ontwikkelbranch, al op main/v1, of alleen historisch.
- **Vrijgave:** sandbox, privé-admin, of publiek/productie vrijgegeven.

“Gepubliceerd in een Xano-testbranch” is niet hetzelfde als “naar v1 overgezet”. Code op v1 kan nog steeds uitsluitend sandboxdiensten aanroepen. Een verstuurde sandboxmail bewijst geen echte hotelreservering.

## Vóór een overzetactie

Maak per release een concrete selectie met:
- release-ID, datum en uitvoerder;
- broncommit of Xano-bronexport, branch en publicatiestatus;
- exact geselecteerde bestanden/endpoints/functies/taken/configuraties;
- bron-ID én doel-ID (Xano-ID's kunnen verschillen);
- uitgesloten onderdelen, inclusief testhulpfuncties en drafts;
- afhankelijkheden, geplande volgorde en bewijs van relevante tests;
- terugvalcommit/branch/export en herstelstappen;
- bestaande autorisatie en eventuele nog vereiste productie-go/no-go.

Voer een selectieve merge uit; selecteer niet automatisch een hele Xano-branch of middleware. Leg ook nieuw aangetroffen verschillen vast die bewust achterblijven.

Xano-branches delen hier databasebron `live`. Een branchback-up is dus geen databack-up. Neem een aparte dataherstelmaatregel op als een release gegevens wijzigt. Sla geen sleutels, tokens, wachtwoorden, volledige gastgegevens of betaalgegevens op in Git.

## Na de overzetactie

- Controleer de versie op de bestemming en de uitkomst van de deployment.
- Controleer het bedoelde gedrag via de werkelijk aangesloten route of portal; een lokale test alleen is geen bewijs van publicatie.
- Noteer resultaat, tijdstip, bron/doel, commit/PR/deployment en resterende beperkingen in de liveganglijst.
- Markeer alleen het werkelijk gecontroleerde onderdeel als overgezet en geverifieerd.
- Bij fouten: stop verdere vrijgave, herstel of rol gericht terug en registreer de daadwerkelijke toestand.
- Verwijder oude branches/testrecords pas als afzonderlijk besloten is dat bewaring en terugval niet meer nodig zijn.

## Vaste afsluitcheck

- [ ] Statusbestand en liveganglijst spreken elkaar niet tegen.
- [ ] Nieuwe of gewijzigde onderdelen hebben een vaste ID en vindbare bron.
- [ ] Test versus productie en geplaatst versus vrijgegeven zijn expliciet.
- [ ] Overzetbewijs of concrete blokkade is ingevuld.
- [ ] Historische testcode is niet als productiefunctionaliteit meegeselecteerd.
- [ ] De volgende stap is concreet; geen afhankelijkheid van chatgeheugen.

Deze afspraak organiseert het werk; zij geeft geen aanvullende toestemming voor echte betalingen, boekingen of publieke productieactivering.

## Aanvullende eigenaarafspraak — 16 oktober 2026

Kritisch controleren met snelle, professionele en schaalbare livegang als doel. Los fouten in de automatische keten op, niet door afzonderlijke deals handmatig op te poetsen. Controleer brongegevens, verschillende relevante aanbodvarianten, foutafhandeling en consistente weergave in admin/website. Meld ontbrekend bewijs expliciet. Werk livegangblokkades op risico en afhankelijkheid af; herhaal bewezen controles alleen bij een relevante wijziging of concrete fout.
