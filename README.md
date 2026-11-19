# Bacheca Lavoro - App

App Flutter sviluppata per il compito individuale del corso di Programmazione Mobile.
È una bacheca di annunci di lavoro:

- le aziende si registrano, fanno il login, pubblicano annunci e guardano le candidature
  ricevute, compreso il curriculum allegato;
- i candidati non devono registrarsi: consultano la bacheca e si candidano inserendo i
  propri dati e caricando il curriculum in PDF.

Il back-end è nel repository
[bacheca-lavoro-server](https://github.com/DoctorMike46/bacheca-lavoro-server).

## Requisiti

- Flutter 3.41 o successivo
- Android 5.0+ oppure iOS 15+
- il server avviato e raggiungibile dal dispositivo

## Come avviarla

Prima di tutto va avviato il server (le istruzioni sono nel suo README). Poi:

```bash
flutter pub get
flutter run
```

Sul simulatore iOS e sull'emulatore Android non serve configurare niente: l'app usa
`http://localhost:8080` su iOS e `http://10.0.2.2:8080` su Android (è l'indirizzo con cui
l'emulatore vede il computer).

Su un telefono vero bisogna indicare l'IP del computer, che il server stampa all'avvio, e
il telefono deve essere sulla stessa rete Wi-Fi. Se l'app non trova il server, nella
schermata di errore c'è il pulsante "Cambia indirizzo server": l'indirizzo inserito viene
controllato e salvato. In alternativa si può passare già in fase di build:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

## Scenari

S1, pubblicare un annuncio: dalla bacheca si va in "Area aziende", si registra l'azienda,
si fa il login e dall'area riservata si tocca "Nuovo annuncio". Dopo la pubblicazione
l'annuncio compare nella bacheca.

S2, candidarsi: senza fare il login si apre un annuncio dalla bacheca, si tocca
"Candidati", si compilano nome, cognome ed email, si allega il PDF e si invia. Alla fine
compare una schermata di conferma.

S3, consultare le candidature e uscire: dall'area riservata si apre un annuncio, si
sceglie una candidatura e con "Apri curriculum" si vede il PDF. Con il pulsante di logout
si torna alla bacheca e per rientrare nell'area aziende serve di nuovo il login.

Il login resta attivo anche se si chiude l'app, perché il token è salvato sul dispositivo,
finché non si fa il logout.

## Struttura del codice

```
lib/
  main.dart                  avvio, tema e lingua italiana
  models/models.dart         Company, Job, JobApplication
  services/api_client.dart   chiamate HTTP al server
  state/session.dart         sessione dell'azienda e indirizzo del server (Provider)
  screens/public/            bacheca, dettaglio annuncio, candidatura
  screens/auth/              login e registrazione
  screens/company/           area riservata, nuovo annuncio, candidature
  widgets/                   widget riusati in più schermate
```

## Note

- Siccome il server locale usa HTTP e non HTTPS, ho abilitato il traffico in chiaro
  (`usesCleartextTraffic` su Android e `NSAppTransportSecurity` su iOS).
- Il curriculum viene scaricato in una cartella temporanea e aperto con il visualizzatore
  PDF del sistema.
