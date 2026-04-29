# PropertEase

Aplikacija za upravljanje iznajmljivanjem nekretnina. Olakšava komunikaciju između iznajmljivača i klijenata te pruža kompletan tok od pretrage nekretnina do plaćanja i ocjenjivanja.

**Tech stack:** .NET 7 API · Flutter Desktop (Admin/Iznajmljivač) · Flutter Mobile (Klijent) · SQL Server · RabbitMQ

---

## Pokretanje aplikacije (Docker)

### Preduslovi

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instaliran i pokrenut
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (za pokretanje UI aplikacija)

### 1. Konfiguracija okruženja

Raspakovati .env.zip file koristeći lozinku poslanu na dlwms


### 2. Pokretanje backend servisa

```bash
docker compose up --build
```

Ovo pokreće:

| Servis | URL |
|--------|-----|
| API | http://localhost:5000 |
| RabbitMQ Management UI | http://localhost:15672 (guest / guest) |
| SQL Server | localhost:1433 |

Baza podataka se automatski kreira i popunjava seed podacima pri prvom pokretanju.

```bash
# Provjera statusa servisa
docker compose ps
docker compose logs api --tail=50
```

---

## Desktop aplikacija (Admin / Iznajmljivač)

### Pokretanje

```bash
cd UI/propertease_admin

```

### Test kredencijali

| Uloga | Korisničko ime | Lozinka |
|-------|----------------|---------|
| **Admin** | `desktop` | `test` |
| **Iznajmljivač** | `izdavac` | `test` |

---

## Mobilna aplikacija (Klijent)

### Pokretanje

```bash
cd UI/propertease_client

```

Za Android emulator API base URL je `http://10.0.2.2:5000/api/`.  

### Test kredencijali

| Uloga | Korisničko ime | Lozinka |
|-------|----------------|---------|
| **Klijent** | `mobile` | `test` |

### PayPal Sandbox

Za testiranje plaćanja koristiti sljedeće PayPal sandbox podatke:

| Polje | Vrijednost |
|-------|------------|
| Email | `sb-nw4747c49814272@personal.example.com` |
| Lozinka | `K*6k0M-Q` |

---

## Upute za korištenje

### Statusi rezervacije

| Status | Opis |
|--------|------|
| **Na čekanju** | Rezervacija kreirana, čeka odluku iznajmljivača |
| **Potvrđena** | Iznajmljivač potvrdio — klijent može izvršiti plaćanje; ostaje Potvrđena i nakon plaćanja |
| **Plaćena** | Klijent izvršio plaćanje |
| **Završena** | Rezervacija je istekla (datum boravka je prošao) |
| **Otkazana** | Odbijeno ili otkazano |


---

### Kreiranje rezervacije (Klijent — mobilna app)

1. Prijavi se sa korisničkim imenom `mobile` i lozinkom `test`
2. Na početnom ekranu pregledaj dostupne nekretnine
3. Koristi filtere (grad, tip, cijena, datumi) za sužavanje pretrage
4. Otvori željenu nekretninu i klikni **Rezerviši**
5. Odaberi datume boravka i broj gostiju, potvrdi kreiranje
6. Rezervacija se pojavljuje u **Moje rezervacije** sa statusom *Na čekanju*

> Klijent prima in-app notifikaciju čim iznajmljivač donese odluku.

---

### Potvrđivanje rezervacije (Iznajmljivač / Admin — desktop app)

1. Prijavi se kao `izdavac` (ili `desktop` za admin)
2. U bočnom meniju odaberi **Rezervacije**
3. Pronađi rezervaciju sa statusom *Na čekanju* i otvori detalje
4. Klikni **Potvrdi** — otvara se dijalog za potvrdu
5. Nakon potvrde:
   - Status prelazi na *Potvrđena*
   - Klijent dobija email i in-app notifikaciju s pozivom na plaćanje
   
---

### Odbijanje rezervacije (Iznajmljivač / Admin — desktop app)

1. Otvori detalje rezervacije sa statusom *Na čekanju*
2. Klikni **Odbij**
3. Upiši razlog odbijanja (obavezno polje)
4. Klijent dobija notifikaciju s navedenim razlogom

---

### Plaćanje (Klijent — mobilna app)

1. Nakon što iznajmljivač potvrdi rezervaciju, otvori detalje rezervacije
2. Pojavljuje se dugme **Plati putem PayPal**
3. Klikni dugme — otvara se PayPal sandbox forma
4. Uloguj se s PayPal sandbox podacima navedenim gore
5. Potvrdi plaćanje
6. Plaćanje je evidentirano — status rezervacije postaje *Plaćena*

---

### Otkazivanje rezervacije

#### Otkazivanje potvrđene (neplaćene) rezervacije — Iznajmljivač / Admin

1. Otvori detalje potvrđene rezervacije
2. Klikni **Otkaži rezervaciju i refunduj**
3. Upiši razlog otkazivanja
4. Klijent dobija email i notifikaciju s razlogom i imenom osobe koja je otkazala

#### Otkazivanje od strane klijenta — mobilna app

1. Otvori detalje aktivne rezervacije
2. Klikni **Otkaži rezervaciju**
3. Upiši razlog i potvrdi
4. Ako je rezervacija plaćena, refund se automatski procesira

#### Logika brisanja plaćenih rezervacija

Plaćene (aktivne) rezervacije **ne mogu se direktno obrisati**. Jedini način je otkazivanje kroz tok koji uključuje razlog i procesiranje povrata novca. Nakon otkazivanja rezervacija dobija status *Otkazana* i prikazuje se ko je otkazao, kad i zašto. Brisanje je dostupno samo za rezervacije koje su u statusu *Na čekanju* ili *Otkazana*.

---

### Ocjenjivanje

#### Ocjena nekretnine (Klijent — mobilna app)

1. Rezervacija mora biti u statusu *Završena*
2. Otvori detalje završene rezervacije ili nekretnine
3. Klikni **Ostavi recenziju**
4. Odaberi ocjenu (1–5 zvjezdica) i upiši komentar
5. Recenzija je vidljiva svim korisnicima u detaljima nekretnine

#### Ocjena iznajmljivača (Klijent — mobilna app)

1. Nakon završene rezervacije, na profilu iznajmljivača dostupna je opcija ocjenjivanja
2. Ocjena se prikazuje na profilu iznajmljivača s prosječnom ocjenom



### Upravljanje nekretninama (Iznajmljivač / Admin — desktop app)

- **Dodavanje nekretnine:** Klikni **Dodaj nekretninu** u gornjem desnom uglu liste nekretnina, popuni formu (naziv, tip, grad, cijene, sadržaj, fotografije, lokacija)
- **Uređivanje:** Klikni ikonu olovke u redu nekretnine
- **Brisanje:** Klikni ikonu kante — prikazuje se dijalog za potvrdu; nekretnine s aktivnim rezervacijama ne mogu se obrisati
- **Detalji:** Klikni ikonu informacije — pregled fotografija, mape, recenzija, preporuka i iznajmljivača

#### Admin filter po iznajmljivaču

Admin može u listi nekretnina i listi rezervacija koristiti dropdown **Iznajmljivač** za filtriranje po konkretnom iznajmljivaču.

---

### Poruke / Chat

- Klijent može inicirati razgovor s iznajmljivačem direktno iz detalja nekretnine (mobilna app)
- Iznajmljivač odgovara putem **Inbox** sekcije u bočnom meniju (desktop app)
- Badge s brojem nepročitanih poruka prikazuje se u meniju u realnom vremenu (SignalR)

---

### Notifikacije

- Vidljive u ikoni zvona (gornji desni ugao) u oba interfejsa
- Notifikacije se generišu za: novu rezervaciju, potvrdu, odbijanje, plaćanje, otkazivanje i završetak rezervacije
- Klikni na notifikaciju za direktan prelaz na detalje rezervacije
- Za testiranje email notifikacije, editovati korisnikov email i promijeniti ga u svoj 

---

### Izvještaji (Desktop app — Admin / Iznajmljivač)

- U meniju odaberi **Izvještaji**
- Generišu se PDF izvještaji o rezervacijama po periodu
- Iznajmljivač vidi samo svoje rezervacije, admin vidi sve

---

## Administracija (Desktop app — samo Admin)

| Sekcija | Opis |
|---------|------|
| **Korisnici** | Pregled, dodavanje, uređivanje i brisanje korisnika; dodjela uloga |
| **Države** | Upravljanje listom država |
| **Gradovi** | Upravljanje listom gradova |
| **Tipovi nekretnina** | Upravljanje kategorijama nekretnina |
| **Uloge** | Upravljanje sistemskim ulogama |
| **Plaćanja** | Pregled svih transakcija |

---




---

## Arhitektura

```
PropertEaseApp/
├── PropertEase.Core/           # Entiteti, DTO-ovi, filteri, enumeracije
├── PropertEase.Infrastructure/ # EF Core, repozitoriji, migracije, RabbitMQ
├── PropertEase.Services/       # Poslovna logika, validacija, izvještaji, preporuke
├── PropertEase.Shared/         # Konstante, modeli, ekstenzije
├── PropertEaseApi/             # ASP.NET Core Web API
├── PropertEase.Worker/         # Background servis (RabbitMQ consumer, email)
├── UI/propertease_admin/       # Flutter Desktop — Admin + Iznajmljivač
└── UI/propertease_client/      # Flutter Mobile — Klijent
```
