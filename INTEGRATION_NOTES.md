# SEAfety Travel — Auth + Travel Agency Module (Integration Notes)

This document covers the parts I implemented: authentication, role-based
navigation, the full Travel Agency module, and the shared integration code
other modules build on. Tourist / Officer / Admin screens are placeholders
only — your teammates own those.

---

## 1. Files created

### Setup & app entry
- `lib/main.dart` — initialises Firebase, loads the theme, shows `AuthGate`.
- `pubspec.yaml` — added `firebase_auth`, `cloud_firestore`, `image_picker`;
  registered `assets/images/`.

### Shared (used by everyone)
- `lib/shared/theme/app_theme.dart` — blue / light-blue / white Material theme.
- `lib/shared/models/app_user.dart` — maps `users/{uid}`.
- `lib/shared/models/destination_model.dart` — maps `destinations/{id}`.
- `lib/shared/models/package_model.dart` — maps `packages/{id}`.
- `lib/shared/models/booking_model.dart` — maps `bookings/{id}`.
- `lib/shared/models/conversation_model.dart` — maps `conversations/{id}`
  and the `messages` sub-collection.
- `lib/shared/services/auth_service.dart` — sign in / sign up / sign out.
- `lib/shared/services/user_service.dart` — create/read the `users` doc.
- `lib/shared/auth/login_screen.dart` — login page.
- `lib/shared/auth/signup_screen.dart` — signup page (always role 0 Tourist).
- `lib/shared/widgets/auth_gate.dart` — auth-state listener + role routing +
  reusable `LogoutButton`.

### Travel Agency module
- `lib/agency/services/package_service.dart` — package CRUD.
- `lib/agency/services/destination_service.dart` — read-only destinations.
- `lib/agency/services/booking_service.dart` — booking status / payment updates.
- `lib/agency/services/conversation_service.dart` — enquiries + chat messages.
- `lib/agency/screens/agency_home.dart` — bottom-nav shell.
- `lib/agency/screens/packages_screen.dart` — list + delete packages.
- `lib/agency/screens/package_form_screen.dart` — add/edit package, Cloudinary
  image upload.
- `lib/agency/screens/destinations_screen.dart` — browse published destinations.
- `lib/agency/screens/bookings_screen.dart` — manage booking status / payment.
- `lib/agency/screens/enquiries_screen.dart` — list customer enquiries.
- `lib/agency/screens/chat_screen.dart` — chat, set status, set follow-up.

### Placeholders (teammates replace these)
- `lib/tourist/screens/tourist_home.dart`
- `lib/officer/screens/officer_home.dart`
- `lib/admin/screens/admin_home.dart`

### Security
- `firestore.rules` — role-based access rules.

---

## 2. What the Travel Agency module does

- **Packages** — create, edit, delete travel packages. Each package links to a
  destination, has a price (MYR), duration, inclusions, availability
  (available/limited/unavailable), and a published toggle. Images upload to
  Cloudinary and only the returned URL is stored in Firestore.
- **Destinations** — browse destinations published by the Tourism Officer
  (read-only for the agency).
- **Bookings** — view bookings assigned to the agency and update their status
  (pending/confirmed/cancelled) and payment status (unpaid/partial/paid). Every
  change appends an entry to `changehistory`.
- **Enquiries + chat** — see conversations assigned to the agency, open a chat,
  send messages, change the enquiry status
  (new/in_progress/waiting_for_customer/confirmed), and set a follow-up date
  (`followupat`).

Roles: `0` Tourist, `1` Travel Agency, `2` Tourism Officer, `3` Administrator.
Normal signup always creates role `0`. Privileged roles must be set in the
Firebase console or by an Administrator.

---

## 3. Manual configuration steps

1. **Install packages**

   ```
   flutter pub get
   ```

2. **Enable Firebase Authentication → Email/Password**
   Firebase console → Authentication → Sign-in method → enable Email/Password.

3. **Create a Firestore database** (if not already)
   Firebase console → Firestore Database → Create database.

4. **Create a Travel Agency test account**
   - Sign up in the app (creates role 0).
   - In Firestore, open that user's doc in `users/` and change `role` to `1`.
   - Log out and back in to land on the agency dashboard.

5. **Seed a published destination** (so the package form has something to pick)
   Add a doc to `destinations/` with: `name`, `country`, `region`,
   `description`, `categories` (array), `imageurl`, `published: true`,
   `updatetime`.

6. **Windows desktop only** — enable Developer Mode for plugin symlinks:

   ```
   start ms-settings:developers
   ```

   (Not needed for Android/iOS builds.)

7. **Cloudinary** — already configured in `lib/cloudinary_service.dart`
   (unsigned upload preset `seafety_travel`). No secrets in the app. No change
   needed.

8. **Google Maps (optional, for teammates)** — `google_maps_flutter` is already
   a dependency but no agency screen uses a map, so no key is required for this
   module. When the Tourist/Officer modules need maps, add the key to the native
   config (Android: `android/app/src/main/AndroidManifest.xml`; iOS:
   `ios/Runner/AppDelegate.swift`). Do not hardcode it in Dart.

---

## 4. Required Firestore indexes

Firestore auto-creates single-field indexes. One **composite index** is needed:

- Collection `conversations`, fields:
  - `staffuserid` (Ascending)
  - `type` (Ascending)

Reason: `agencyConversations()` filters on both `staffuserid` and `type`.
The first time you run that screen, Firestore throws a `failed-precondition`
error with a direct link to create the index — click it, or add it under
Firestore → Indexes.

No other agency query needs a composite index (the rest use a single filter,
and the chat `messages` query orders by a single field `sentat`).

---

## 5. Deploying the security rules

The app cannot deploy rules for you. Two options:

**A. Firebase console (quickest)**
1. Firebase console → Firestore Database → Rules.
2. **Review the existing rules first** (do not blindly overwrite).
3. Paste the contents of `firestore.rules`, then Publish.

**B. Firebase CLI**
```
firebase deploy --only firestore:rules
```
(Requires `firebase login` and a `firebase.json` entry pointing to
`firestore.rules`. The current `firebase.json` is Flutter-only, so add a
`firestore` section if you go this route.)

The rules enforce: users read/update only their own profile (role fixed to 0 on
create), destinations writable only by Officer/Admin, agencies manage only their
own packages, booking access limited to the tourist + assigned agency, and
conversation/message access limited to participants.

---

## 6. Known limitations / notes

- **Booking and conversation creation** happen in the Tourist module (not mine).
  My booking/enquiry screens assume those documents already exist. If you want
  to test before the Tourist module is ready, add sample `bookings` and
  `conversations` docs in the console (include the agency's uid in
  `agencyuserid` / `staffuserid` and in `participantids`).
- `traveldate` is read but not edited by the agency (tourists set it).
- No pagination yet — lists stream all matching docs. Fine for an assignment;
  add `.limit()` later if volume grows.
- Image upload has no size/type restriction beyond what Cloudinary's preset
  enforces.
- The two `avoid_print` analyzer infos are in the pre-existing
  `cloudinary_service.dart`, left untouched on purpose.

---

## 7. Testing walkthrough

1. `flutter pub get`, then run the app.
2. **Signup** a new account → lands on the Tourist placeholder (role 0 works).
3. **Logout** (top-right icon).
4. In Firestore set that user's `role` to `1`, log back in → agency dashboard.
5. **Packages tab** → `+` → fill the form, pick an image, Save → appears in the
   list. Edit it, then delete it.
6. **Destinations tab** → shows seeded published destinations.
7. **Bookings tab** → with a sample booking present, change status and payment;
   confirm a `changehistory` entry is added in Firestore.
8. **Enquiries tab** → with a sample conversation present, open the chat, send a
   message (appears instantly via stream), change status, set a follow-up date
   (an alarm icon shows on the enquiry).
9. Confirm the composite index prompt appears once on the Enquiries tab and
   create it.
