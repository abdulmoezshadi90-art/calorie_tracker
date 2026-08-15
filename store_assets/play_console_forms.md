# Play Console forms prep

Draft answers based on what the app actually does today (local-only storage,
no backend, no network permission, no accounts). Verify each one yourself
inside the actual Play Console questionnaire, wording and options change
between Google's form versions and I can't see your account.

## Data safety

The core question the whole form hinges on: does the app collect or share
any user data? For Zibda, the honest answer is no.

- Data collection: none. Everything (logs, goals, profile, saved meals,
  settings) is stored in `shared_preferences`, on-device only. Nothing is
  transmitted anywhere.
- Data sharing: none, there's no backend to share to.
- The one exception worth declaring accurately: the feedback feature opens
  the user's own email app with a pre-filled draft (a mail `Intent`, not an
  API call) — the app itself never sends or sees that email. Whether Google
  wants this declared depends on the current form's exact wording for
  "does your app... provide a way for users to contact you" vs. actual data
  collection; read that section's help text when you get there.
- Security practices section: data isn't encrypted in transit because
  nothing is ever in transit. Data deletion: uninstalling the app deletes
  everything, there's no account to separately delete.

## Content rating (IARC questionnaire)

Answer these as asked, this is just a preview so the actual questionnaire
doesn't surprise you:

- Violence, sexual content, profanity, controlled substances, gambling:
  none, answer no to all of it.
- User-generated content / user interaction / sharing personal info with
  other users: no, there's no social feature of any kind.
- Location sharing: no.
- Digital purchases: no, nothing is sold in-app.
- Likely result: rated for all ages (equivalent to PEGI 3 / ESRB Everyone),
  though Google's tool computes the exact final rating, this is just what
  to expect.

## Target audience and content

- Not designed for or directed at children. A calorie tracker with medical
  disclaimers isn't a children's app by any reasonable reading, so don't
  select a child-directed age range.
- Likely target age range: 18+, or whatever your honest read is, this
  affects some Play policies (ads, certain APIs) that don't apply to Zibda
  anyway since there are none.

## App access

- All functionality is available without restrictions, no login gate, no
  paywall, nothing hidden behind a special account. Declare "all
  functionality is available without special access."

## Store listing category

Health & Fitness is the standard category for calorie/macro trackers on
Play (this is where MyFitnessPal, Lose It, etc. sit).
