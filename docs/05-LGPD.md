# 05 — LGPD Compliance

Brazilian Data Protection Law (Lei nº 13.709/2018) compliance map for Roteirizador Pro.

> **Why this matters:** This app processes data of Brazilian citizens. LGPD applies. Non-compliance fines reach BRL 50M per infraction or 2% of revenue, capped at BRL 50M.

## Personal Data We Collect

| Data | Purpose | Legal basis (Art. 7 LGPD) |
|---|---|---|
| Email | Authentication, notifications | Execução de contrato |
| Phone | Account recovery, support | Execução de contrato |
| Name | Identification, payment receipts | Execução de contrato |
| Home address (lat/lng) | "Sentido casa" optimization | Consentimento explícito |
| Delivery addresses | Core route planning feature | Execução de contrato |
| CPF (only of partners receiving split) | Pix split routing per Efí | Obrigação legal |
| Pix payment data (txid, e2eId) | Subscription processing | Execução de contrato |

## User Rights to Support (Art. 18 LGPD)

The app must allow the user to exercise:

- Confirmation that we process their data.
- Access to their data.
- Correction of incomplete or inaccurate data.
- Anonymization, blocking, or deletion of unnecessary data.
- Portability of data to another service.
- Deletion of data processed under consent.
- Information about with whom we share data (Efí Bank, Sentry, etc.).
- Revocation of consent.

These rights are exposed in-app under **Settings → Privacy** in M2.

## Data Retention Policy

- **Active accounts**: retained while subscription is active + 12 months for billing/legal.
- **Inactive accounts** (180 days no login): notified by email, then anonymized.
- **Webhook event logs**: 90 days.
- **Backups**: 30 days rolling.
- **Subscription/payment records**: retained per Brazilian tax law (5 years minimum).

## DPO (Data Protection Officer)

To be defined when the app is published. Email placeholder: `dpo@roteirizadorpro.com.br`.

## Implementation Checklist

These items must be in place before public launch (track in `TODO.md`):

- [ ] Privacy policy page on landing site (`roteirizadorpro.com.br/privacy`).
- [ ] In-app privacy notice on first launch with consent capture.
- [ ] Data export endpoint: `GET /user/me/export` returning JSON.
- [ ] Data deletion endpoint: `DELETE /user/me` (soft-delete first, hard-delete after 30 days).
- [ ] Cookie banner on landing (if we add analytics).
- [ ] DPA (Data Processing Agreement) signed with Efí Bank.
- [ ] DPA signed with Sentry (or alternative error tracker).
- [ ] DPO email/contact published.
- [ ] Internal incident response runbook for data breaches (notify ANPD within reasonable time per Art. 48).

## Third-Party Processors

Every service that processes user data must be listed here with its purpose:

| Service | Data shared | Purpose | DPA status |
|---|---|---|---|
| Efí Bank | Email, name, CPF (partners only), payment metadata | Payment processing | Pending |
| Sentry (or similar) | Error stack traces, anonymized user ID | Error monitoring | Pending |
| DigitalOcean | All app data (server provider) | Hosting | Standard ToS |

## References

- LGPD full text: https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm
- ANPD (national authority): https://www.gov.br/anpd/
- Cartilha LGPD para desenvolvedores (ANPD).
