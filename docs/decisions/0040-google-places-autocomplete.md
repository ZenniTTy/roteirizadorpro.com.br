# ADR 0040: Adoption of google_maps_webservice for Places Autocomplete

## Status
Accepted

## Context
In Milestone 2, Slice 2, Area 4 (Add Stop), we need to implement the "Adicionar parada — texto + autocomplete" feature.
The roadmap specifies: "Usa `google_maps_webservice` Places Autocomplete API."
This requires hitting the Google Places API to provide search suggestions as the user types an address. 
Since we already decided to adopt Google Maps as our primary map engine (ADR 0039) and we already have a `MAPS_API_KEY`, using a robust, community-maintained wrapper for the Places API is safer and faster than writing our own `http` client calls and parsing the JSON responses manually.

## Decision
We initially planned to use `google_maps_webservice`. However, due to a dependency conflict with `http ^0.13.0` (which conflicts with `google_fonts` depending on `http ^1.0.0`), we will implement a lightweight wrapper around the Google Places Autocomplete API directly using our existing `dio` client.

## Consequences
- **Positive:** No new third-party dependencies added to the project, avoiding version-solving issues.
- **Positive:** Smaller bundle size and full control over the API responses.
- **Negative:** We must manually define the DTOs (`AutocompletePrediction`, etc.) and handle the HTTP requests.
- **Implementation Note:** Debouncing will be handled manually via `dart:async` `Timer`.
