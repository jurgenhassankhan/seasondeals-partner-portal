# SeasonDeals — vaste werkwijze voor agents

Op verzoek van de projecteigenaar geldt voor werk in deze repository:

1. Lees bij de start `SEASONDEALS_STATUS.md`, `SEASONDEALS_LIVEGANG.md` en `SEASONDEALS_WERKPROTOCOL.md`.
2. Houd bij elke relevante wijziging zowel de projectstatus als de livegang-/overzetlijst bij, met vaste onderdeel-ID's, exacte bron/bestemming en bewijs. Leg een blokkade of onbekende bron expliciet vast.
3. Onderscheid sandbox getest, geplaatst op main/v1 en vrijgegeven voor publieke productie. Een achtergebleven branch betekent niet dat het werk nog open is.
4. Heropen bewezen stappen niet zonder concrete nieuwe fout of relevante wijziging. Stap 4 is sandbox bewezen; stap 5 privé-admin is gepubliceerd en ingelogd geverifieerd.
5. Selecteer bij Xano-merges alleen bedoelde onderdelen. Laat testhulpfuncties, oude drafts, afwijkende partnerroutes en middleware buiten de selectie tenzij hun wijziging expliciet onderdeel is van de taak.
6. Xano-branches delen databasebron live. Noteer afzonderlijke dataherstelmaatregelen bij datawijzigingen; een branchback-up bewaart alleen logica.
7. Geen geheimen of volledige klant-/betaalgegevens in Git. Maak geen nieuwe boeking om alleen een overzicht of mailopmaak te controleren.
8. Rond geautoriseerd werk zelfstandig af. Het protocol introduceert geen extra toestemming voor gewone reversibele wijzigingen; het geeft evenmin toestemming voor echte transacties of productieactivering.
9. Meld in de eindreactie wat is gewijzigd, waar het actief is, wat daadwerkelijk getest is en welke concrete punten openblijven.

Het volledige onderhouds- en releaseprotocol staat in `SEASONDEALS_WERKPROTOCOL.md`.
