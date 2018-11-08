# RUAIN API

Registr RUIAN je užitečná věc. Ale připojit se na něj obnáší prokousat se nehoráznými stohy dokumentace. A co za to dostanete?
SOAP rozhraní… 👎

Protože máme raději REST (JSON over HTTP) než SOAP, vyřešili jsme si to po svém.
Data RUIANu jsou naštěstí volně ke stažení a jsme tak malá zemička, že se všechny naše adresy dají obsluhovat in-memory.
A když už to máme, proč se nerozdělit.

## ... as a service

Viz: https://ruian.fnx.io/

## Závislosti

Spustění je závislé na <a href="https://webdev.dartlang.org/tools/sdk/archive">dart SDK >=1.21 <2.0 </a>, a standardních unix nástrojích `recode` a `bash`.

## Před spuštěním

Před spuštěním serveru je potřeba stáhnout závislosti (`pub get`).

## Spuštění serveru

```bash
dart bin/main.dart --src=test/test-data/ --port=8123 --path=$(pwd)
```

Server se spouští s 2 parametry - výchozí data a port. 

Výchozí data směřují na složku, ve které se nachází `*.csv` soubory s daty. Po spuštění aplikace autonomně ověří data a pokud je možné stáhnout aktualizaci, stáhne ji, zpracuje soubory a vymění data. 

Jako port se uvádí celé číslo (`int`) portu, např. `8123`.

První start zabere tak minutu až dvě - server si stáhne aktuální data a zpracuje je.

## Validátor

Validátor validuje adresu, přijímá menší odchylky (chybějící písmena, písmena navíc, ...). 

```
http://localhost:8123/api/v1/ruian/validate?municipalityId=546801&zip=37842&cp=2&street=zameeckaaaa
```

### Parametry

- `municipalityName` (fulltext)
- `zip` (musi sedet presne)
- `street` (fulltext)
- `cp`, `ce`, `co` (popisné, evidenční, orientační, musí být uvedeno alespoň jedno)

### Odpověď

```json
{
  "status": "POSSIBLE",
  "message": null,
  "place": {
     "confidence": 0.9413223140495868,
     "municipalityId": 546801,
     "municipalityName": "Nová Včelnice",
     "streetName": "Zámecká",
     "ce": null,
     "cp": "2",
     "co": null,
     "zip": 37842
  }
}
```

### Možné stavy

- ERROR - neco je uplne spatne, viz message
- NOT_FOUND - nenasel jsem nic dostatecne podobneho
- POSSIBLE - no - mozna by tu neco bylo
- MATCH - jo, to celkem sedi, to bude dorucitelne

## Builder

Sestavování adresy region -> obec -> ulice -> místo.

### Regiony

```
http://localhost:8123/api/v1/ruian/build/regions
```

### Obce

Paremetry jsou `regionId`.

```
http://localhost:8123/api/v1/ruian/build/municipalities?regionId=CZ051
```

### Ulice

Paremetry jsou `municipalityId`.

```
http://localhost:8123/api/v1/ruian/build/streets?municipalityId=561380
```

### Místa

Paremetry jsou `municipalityId` a `streetName`.

```
http://localhost:8123/api/v1/ruian/build/places?municipalityId=561380&streetName=Českokamenická
```

### Status kódy

* `200` OK.
* `422` Chybějící parametry.
* `500` Interní chyba serveru.
