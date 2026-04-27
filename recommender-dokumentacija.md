# Sistem preporuka – tehnička dokumentacija

## 1. Pregled

PropertEase sistem preporuka koristi algoritam asocijativnih pravila zasnovan na **Apriori metodi**. Cilj sistema je preporučiti korisniku nekretnine koje su drugi korisnici sa sličnim obrascima rezervacija birali zajedno s nekretninama koje je taj korisnik već rezervisao.

Sistem ima dva odvojena načina rada:
- **Preporuke po korisniku** – zasnovane na cjelokupnoj historiji rezervacija korisnika.
- **Preporuke po nekretnini** – zasnovane na ko-pojavljivanju konkretne nekretnine s drugim nekretninama u rezervacijama.

---

## 2. Ključni pojmovi

| Pojam | Definicija |
|---|---|
| **Transakcija** | Skup svih nekretnina koje je jedan klijent ikada rezervisao. |
| **Support (podrška)** | Udio transakcija u kojima se određena nekretnina pojavljuje: `support(A) = broj transakcija s A / ukupan broj transakcija` |
| **Confidence (pouzdanost)** | Vjerovatnoća da korisnik koji je rezervisao A rezerviše i B: `confidence(A → B) = support(A ∪ B) / support(A)` |
| **Antecedent** | Nekretnina koju je korisnik već rezervisao (polazišna tačka pravila). |
| **Candidate** | Nekretnina koju korisnik nije rezervisao, a koja se predlaže kao preporuka. |

---

## 3. Konfiguracija

Parametri sistema nalaze se u klasi `RecommendationConfig` i mogu se podesiti u `appsettings.json`.

| Parametar | Zadana vrijednost | Opis |
|---|---|---|
| `MinSupport` | `0.05` | Minimalna podrška (5 %). Nekretnine ispod ovog praga ignorišu se u pravilima. |
| `MinConfidence` | `0.30` | Minimalna pouzdanost (30 %). Pravila s pouzdanošću ispod praga se odbacuju. |
| `MaxRecommendations` | `5` | Maksimalan broj preporuka koje se vraćaju po zahtjevu. |

---

## 4. Preporuke po korisniku (`GetRecommendationsAsync`)

**Implementacija:** `AssociationRulesEngine.GetRecommendationsAsync(int userId)`

### Koraci algoritma

1. **Učitavanje podataka**  
   Sve rezervacije se učitavaju iz baze. Svaki klijent čini jednu transakciju – skup ID-ova nekretnina koje je rezervisao.

2. **Hladni start (novi korisnik)**  
   Ako korisnik nema nijednu rezervaciju, vraćaju se najpopularnije nekretnine po ukupnom broju rezervacija.

3. **Računanje podrške stavki**  
   Za svaku nekretninu računa se njen support:
   ```
   support(A) = broj transakcija koje sadrže A / ukupan broj transakcija
   ```

4. **Generisanje kandidata**  
   Za svaku nekretninu A koju je korisnik rezervisao (antecedent):
   - Provjerava se da li `support(A) >= MinSupport`.
   - Prolazi se kroz sve transakcije koje sadrže A.
   - Za svaku nekretninu B u tim transakcijama (koja nije u korisnikovom skupu) bilježi se ko-pojavljivanje.
   - Provjerava se da li `support(B) >= MinSupport`.

5. **Normalizacija na confidence**  
   ```
   confidence(A → B) = broj ko-pojavljivanja B / max(broj transakcija koje sadrže bilo koji A korisnika)
   ```

6. **Filtriranje i sortiranje**  
   Zadržavaju se samo kandidati gdje `confidence >= MinConfidence`. Rezultat se sortira silazno po confidence i ograničava na `MaxRecommendations`.

### Dijagram toka

```
Učitaj sve rezervacije
        │
        ▼
Korisnik ima rezervacije?
   NE ──► Vrati najpopularnije nekretnine
   DA ──► Izgradi transakcije po klijentu
              │
              ▼
        Računaj support za sve stavke
              │
              ▼
        Za svaki antecedent korisnika:
          ├─ support(A) < MinSupport? → preskoči
          └─ Broji ko-pojavljivanje s candidatima
              │
              ▼
        Normaliziraj na confidence
              │
              ▼
        Filtriraj: confidence >= MinConfidence
              │
              ▼
        Sortiraj silazno, uzmi top N
```

---

## 5. Preporuke po nekretnini (`GetRecommendationsByPropertyAsync`)

**Implementacija:** `AssociationRulesEngine.GetRecommendationsByPropertyAsync(int propertyId)`

Ovaj metod je optimizovan za performanse – teško računanje prenosi se na SQL bazu podataka putem `PropertyReservationRepository.GetRecommendationDataAsync`.

### Koraci algoritma

1. **SQL upit** vraća tri vrijednosti:
   - `totalClientCount` – ukupan broj distinktnih klijenata u sistemu.
   - `propertyClientCount` – broj klijenata koji su rezervisali traženu nekretninu.
   - `coOccurrences` – mapa `{PropertyId → broj klijenata koji su rezervisali i traženu i tu nekretninu}`.

2. **Računanje metrika**  
   Za svaku ko-pojavnu nekretninu B:
   ```
   support(B)          = coOccurrences[B] / totalClientCount
   confidence(A → B)   = coOccurrences[B] / propertyClientCount
   antecedentSupport   = propertyClientCount / totalClientCount
   ```

3. **Primjena pragova**  
   Ako `antecedentSupport >= MinSupport`, primjenjuju se oba praga (`MinSupport` i `MinConfidence`).

4. **Fallback mehanizam**  
   Ako primjena pragova eliminira sve kandidate (premalo podataka), vraćaju se rezultati sortirani samo po confidence – bez filtriranja pragovima.

5. **Rezultat**  
   Lista objekata `RecommendationItem(PropertyId, Confidence)` sortiranih silazno po confidence, ograničena na `MaxRecommendations`.

---

## 6. Gdje se sistem koristi

| Endpoint | Metod | Opis |
|---|---|---|
| `GET /api/Property/{id}/Recommendations` | `GetRecommendationsByPropertyAsync` | Vraća nekretnine slične datoj nekretnini. Koristi se na detaljnom pregledu nekretnine u mobilnoj aplikaciji. |
| Interno pri listanju | `GetRecommendationsAsync` | Personalizovane preporuke za prijavljenog korisnika. |

---

## 7. Ograničenja i napomene

- **Minimalni podaci:** Algoritam daje smislene rezultate tek kada postoji dovoljan broj transakcija. Na novim bazama s malo rezervacija preporuke se oslanjaju na popularnost (hladni start).
- **In-memory obrada (metod po korisniku):** Sve rezervacije se učitavaju u memoriju. Za sisteme s velikim brojem rezervacija (>100 000) preporučuje se optimizacija ekvivalentna metodu po nekretnini.
- **Asocijativna pravila, ne kolaborativno filtriranje:** Sistem ne analizira ocjene ni eksplicitne preferencije – samo obrasce ko-rezervisanja.
- **Bez personalizacije po sadržaju:** Karakteristike nekretnina (lokacija, tip, cijena) ne ulaze u algoritam. Sistem se oslanja isključivo na ponašanje korisnika.
