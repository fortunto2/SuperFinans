---
title: Privacy Policy
permalink: /privacy/
---

# Privacy Policy — Freedom Year

**Last updated: 19 August 2026**

Freedom Year works out the year your investments start covering your life. Every amount you
type to get that answer stays on your phone. There is no account, no server holding your
finances, and no third party in the loop.

This document is specific about the one exception, because "we value your privacy" pages
that hide a counter in paragraph nine are why nobody reads them.

## What never leaves your device

Your monthly spending, your invested savings, your monthly contribution, your birth year,
your accounts, your transactions and every number derived from them — the freedom year
itself included. The arithmetic runs on the phone. Nothing about your money is transmitted,
because there is nowhere for it to go: the app has no backend that stores financial data.

If you turn on iCloud sync, that data syncs through **your own** iCloud account, under
Apple's terms. We cannot read it.

## The one thing that is sent

An anonymous usage counter, so we know whether people open the app twice and which features
get used. It sends:

- that the app was launched, and which of a handful of actions happened (a plan was created,
  a plan was restated in another currency)
- the app version, the platform, and the currency **code** you picked — `USD`, `TRY` — never
  an amount
- a random identifier created on first launch

That identifier is not the Advertising Identifier (IDFA), not your device ID, and not tied
to your Apple ID, your name or your email. Deleting the app deletes it; reinstalling makes a
new one. It is not shared with anybody, not sold, and not used for advertising — which is
why the app shows no App Tracking Transparency prompt: there is no tracking to ask about.

**Settings → Privacy → Anonymous usage stats turns it off.** Nothing else changes when you do.

The counter is our own — [superduper-analytics](https://analytics.superduperai.co), running on
our Cloudflare account. No Google Analytics, no Firebase, no advertising SDK, no attribution
network.

## Exchange rates

To show your plan in a second currency, the app asks two public rate services
([Frankfurter](https://frankfurter.dev) and [open.er-api.com](https://open.er-api.com)) for
the day's rates. The request contains no personal data — it asks "what is a dollar worth
today", not "what does this person own". Rates are cached so the app works offline.

## Notifications

One reminder a month, scheduled on your device by iOS. No push server is involved and no
notification token is collected.

## Purchases

Payment is handled by Apple. We never see your card, and we receive no personal data from
the transaction.

## Children

The app is not directed at children and collects nothing that could identify one.

## Your rights

Since we hold no personal data tied to you, there is nothing to export or delete on our
side. Your financial data is deletable by deleting the app, and exportable at any time via
Settings → Export Data.

## Changes

Material changes will appear here with a new date, and in the app's release notes.

## Contact

Questions: [info@superduperai.co](mailto:info@superduperai.co) ·
Source: [github.com/fortunto2/SuperFinans](https://github.com/fortunto2/SuperFinans)
