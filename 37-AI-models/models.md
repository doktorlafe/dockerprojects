# AI models stack

V tomhle adresari ted bezi:

- `ollama` na `http://localhost:11434`
- `open-webui` na `http://localhost:3000`

## Co dela Open WebUI

Open WebUI je webove GUI nad Ollamou. Diky tomu nemusis resit LiteLLM proxy, virtual keys ani databazi jen kvuli tomu, abys mel normalni chat rozhrani.

Pro bezne lokalni pouziti je to jednodussi varianta:

- modely bezici v Ollame vidis rovnou v GUI
- muzes si je stahovat a zkouset pres web
- odpadne auth vrstva a DB pozadavky z LiteLLM

## Jak se k tomu prihlasit

Open WebUI ma vlastni web rozhrani na `http://localhost:3000`.

Pri prvnim otevreni si typicky vytvoris lokalni uzivatelsky ucet primo v GUI. To prihlaseni resi Open WebUI samo, bez extra Postgres databaze v tomhle stacku.

## Start

```bash
docker compose up -d
```

Po startu:

- Ollama API bezi na `http://localhost:11434`
- Open WebUI bezi na `http://localhost:3000`

## Stazeni modelu do Ollamy

Model si muzes natahnout bud pres GUI, nebo primo pres CLI:

```bash
docker exec -it ollama ollama pull deepseek-r1:8b
docker exec -it ollama ollama pull llama3.1:8b
```

Pak je Open WebUI uvidi jako dostupne modely.

## Primy test Ollamy

```bash
curl http://localhost:11434/api/tags
```

## K cemu je to dobre

- jednoduche GUI nad Ollamou
- lokalni prihlaseni primo v Open WebUI
- zadna extra DB jen kvuli zakladnimu pouziti
- pohodlnejsi chat a sprava modelu nez pres holou CLI

## Poznamka k LiteLLM

Soubor `litellm-config.yaml` tu muze zatim zustat bokem, ale tenhle Compose stack ho uz nepouziva.

Pokud by ses nekdy chtel vratit k LiteLLM kvuli OpenAI-compatible proxy nebo key managementu, je lepsi ho resit jako samostatnou variantu s Postgres databazi.
