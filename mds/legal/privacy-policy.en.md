# nIpay Privacy Policy

> **Draft of 2026-10-25, to be reviewed by a lawyer before publication.**
> English version of [privacy-policy.it.md](privacy-policy.it.md); the
> notes for the reviewer are only in the Italian file.

**Last updated:** {{DATA_PUBBLICAZIONE}}

## Controller details

| | |
|---|---|
| Data controller | {{RAGIONE_SOCIALE}} ("ALUM", "we") |
| Registered office | {{INDIRIZZO_SEDE}} |
| VAT / Tax ID | {{PARTITA_IVA}} |
| Privacy contact | {{EMAIL_PRIVACY}} |

We have not appointed a Data Protection Officer: for any question, write
to the privacy contact above.

## 1. In short

- nIpay is an app to keep track of expenses and income. **You can use it
  without an account**: in that case your data stays on your device and
  we receive nothing.
- If you create an account, your data is **synced to our servers in the
  European Union** (Frankfurt), so you can find it on other devices.
- If you use **Friends**, some information becomes visible to the people
  you connect with (section 5).
- **We do not sell your data, show ads, or use analytics or tracking
  tools.**
- Chat messages are **not end-to-end encrypted** (section 9).

## 2. What data we process

### 2.1 Account

- **Email** and **password**. We never see your password: our provider
  stores it encrypted with a one-way algorithm (hash).
- Account creation date, last sign-in, email confirmation.
- If you ask to delete your account, the **date of the request**.

### 2.2 Financial data you enter

Synced only if you have an account:

- **wallets**: name, colour, icon, currency, initial balance, order,
  archived state;
- **transactions**: type, amount, date, category, description, notes,
  original currency and amount if different from the wallet's;
- **categories, tags, budgets, recurring rules, dashboard layout**;
- **custom fields**: any information you choose to add;
- **expense reports**: cost centres, expense reports and their status,
  "reimbursable" and "e-invoice" flags.

Free-text fields (descriptions, notes, custom fields) contain whatever you
write. **Please do not put sensitive data in them**, such as health
information, or personal data about other people.

### 2.3 Receipt photos

Photos you attach to transactions **stay on your device**: we do not
currently upload them to our servers. When you pick a photo, the app
removes its GPS location and other metadata (EXIF). If we start syncing
them in the future, we will update this policy before doing so.

### 2.4 Friends, chat and shared expenses

Only if you use these features:

- **profile**: display name and friend code (a random code you can
  regenerate);
- **friendships**: who you are friends with, requests sent and received,
  blocked people;
- **chat**: the conversations and groups you belong to, your role, the
  messages you send and when you last read a conversation;
- **shared expenses**: description, total, currency, date, who paid,
  participants and shares, settlements and their status;
- **reports** you send: reason, optional details, and a copy of the
  reported message.

### 2.5 Technical data

- **Rate limits**: to prevent abuse we record the time of some actions,
  for example how many friend requests you send. Each record is used for
  at most 24 hours and is deleted by the following day, and in any case
  together with the account.
- **Server logs**: for security and operation, our provider records IP
  address, time and type of request. These logs are kept for the short
  period set by its service.
- **Exchange rates**: to convert currencies the app downloads public rates
  from Frankfurter (api.frankfurter.dev), a service based on European
  Central Bank data. The request contains none of your data; the service
  only sees your device's IP address, like any website.

### 2.6 What we do NOT collect

We do not collect your location, contacts, usage data, advertising data
or identifiers, or crash reports. **The camera** is used only to
photograph receipts and to scan a friend's QR code: the QR image is not
stored.

## 3. Why we process it and on what legal basis

| Purpose | Legal basis (GDPR) |
|---|---|
| Create and manage the account, sync data, run Friends, chat and shared expenses | Performance of the contract, i.e. the Terms of Use (Art. 6(1)(b)) |
| Security, abuse prevention, rate limits, technical logs | Legitimate interest in protecting the service and its users (Art. 6(1)(f)) |
| Handling reports and moderating content | Legitimate interest in user safety and the obligation to act on illegal content (Art. 6(1)(f) and 6(1)(c)) |
| Answering your privacy requests | Legal obligation (Art. 6(1)(c)) |

We do not use your data for profiling, automated decisions or marketing.

## 4. Who we share it with

- **Supabase Inc.** provides our database, authentication and servers. It
  is our **processor** (Art. 28 GDPR) under its data processing agreement
  (DPA, https://supabase.com/legal/dpa). Data is stored in the **EU region
  in Frankfurt** (Germany), on Amazon Web Services infrastructure. If a
  Supabase sub-processor accesses data from outside the European Economic
  Area, the transfer is covered by the European Commission's Standard
  Contractual Clauses included in the DPA.
- **Apple and Google** distribute the app through the App Store and Google
  Play and process your store account data as independent controllers,
  under their own policies.
- **Authorities**, only when the law requires it.

We do not share your data with anyone else.

## 5. What other users see

- Anyone who knows your **friend code** (because you showed or sent it)
  can see your **display name** and send you a friend request. The code
  does not let anyone search for you by name or email: your email is
  never visible to others.
- Your **friends** see your display name and since when you have been
  friends.
- People in your **chats** see the messages you send. In a group, people
  who join later only see messages sent after they joined.
- Participants in a **shared expense** see its description, total, date,
  who paid, everyone's share and whether each person has registered their
  share. Between two people, the settlements that concern them are
  visible.
- If you **block** someone, they are not told. In groups you share you
  both stay, but their messages disappear for you.
- **Reports** are confidential: the reported person does not know who
  reported them.
- **Your personal financial data** (wallets, transactions, budgets and so
  on) is never visible to other users. Only the expenses you choose to
  share are.

## 6. How long we keep it

| Data | Retention |
|---|---|
| Account, financial data, profile, friendships | As long as you have the account |
| Messages | As long as the sender's account exists |
| Text of a message you deleted | 90 days after deletion, for moderation only; others immediately see "Message deleted" |
| Copy of the message in a report | While the report is open; when we close it, the copy is deleted |
| Closed reports (without text) | As long as the reporter's account exists |
| Rate limits | At most 2 days |
| Provider's technical logs | The short period set by the Supabase service |

### Account deletion

You can delete your account in the app (Account → Delete account). After
the request:

1. For **30 days** the account is pending: you can change your mind and
   cancel the deletion by signing in again. During this period you can
   only read your data and settle debts with friends: you cannot send
   messages, add friends, join chats or create shared expenses.
2. After 30 days we **permanently** delete the account and all linked
   data: financial data, profile, friendships, blocks, chat memberships,
   message texts.
3. Some shared information stays with others, **no longer linked to you
   in any way**, because it is part of their accounts: in shared expenses
   and settlements the amounts remain, but your name disappears. In chats
   your messages remain as messages from a deleted user, without text.

You control the data on your device: when signing out you can choose to
remove it, or uninstall the app.

## 7. Your rights

You have the right to:

- **access** your data and get a copy (Art. 15);
- **rectify** it (Art. 16): you can change much of it directly in the
  app, for example your display name;
- **erase** it (Art. 17): from the app, as described above;
- **restrict** its processing (Art. 18);
- receive it in a **machine-readable format** (portability, Art. 20): on
  request we send you a JSON file with all your data, social data
  included;
- **object** to processing based on legitimate interest (Art. 21).

To exercise them, write to {{EMAIL_PRIVACY}} from your account's email.
We reply within one month. We may ask you to confirm your identity before
handing over any data.

You also have the right to lodge a complaint with the Italian **Garante
per la protezione dei dati personali** (www.garanteprivacy.it) or with
the authority of the EU country where you live.

## 8. Minimum age

nIpay with an account is for people **aged 16 or over**. If we find that
an account belongs to someone younger, we delete it. If you are a parent
and think your child has created an account, contact us.

## 9. Security

- Communication between the app and the servers is **encrypted
  (HTTPS/TLS)**.
- Data on the servers is **encrypted at rest** by our provider, and each
  user can read only their own data, thanks to access rules enforced by
  the database itself.
- Sign-in credentials are stored in the device's secure storage (Keychain
  on iOS, Keystore on Android).
- **Messages are not end-to-end encrypted.** They are encrypted in transit
  and on the servers, but technically whoever runs the service could read
  them. **We do not**, except for a message that is **reported** to us: to
  decide on the report we read that message. For the same reason, the
  text of a deleted message remains accessible to us for 90 days.
- The app's local database is protected by the device's encryption
  (active when the phone is locked with a passcode), not by encryption of
  its own.

No system is 100% secure. If a breach puts your data at risk, we notify
the Garante and, where required, you.

## 10. Changes

If we change this policy in a significant way, we will tell you in the
app before the changes apply. The date at the top shows the latest
version.
