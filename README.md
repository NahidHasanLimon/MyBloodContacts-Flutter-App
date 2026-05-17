# Blood Contacts

> **Tagline:** **Not a blood database. Your own blood-contact network to reach people you know and help save lives.**

Blood Contacts is a mobile-first app focused on your personal donor network. It helps you organize your own blood contacts, create urgent blood requests, and quickly reach trusted people in your circle when every minute matters.

## What The App Does

- Maintains a searchable donor directory with blood group, phone, and availability.
- Lets users create blood need requests with patient, requester, and contact-person details.
- Tracks request lifecycle with statuses like `Open`, `Fulfilled`, `Closed`, and `Cancelled`.
- Shows potential donors per request based on matching blood group.
- Provides call/share actions for faster donor communication.

## Core Features

### Donor Management

- Add donors manually or from phone contacts.
- Edit and remove donor entries.
- Save optional donor notes and last donation date.
- Prevents duplicate donors by normalized phone number.
- Contact photo support with size control and compression.

### Need Management

- Create and update blood requests with:
  - blood group
  - required units
  - date/time needed
  - hospital/location
  - requester details
  - contact person details
- Optional “contact person same as requester” behavior with manual override.
- Add/remove potential donors from a filtered donor list.

### Search, Filter, and Sorting

- Search donors by name or phone.
- Filter by blood group and availability context.
- Search and filter needs by blood group, urgency, and status.
- Sorting options for better request browsing.

### Request Details and Actions

- Detailed request view with structured sections.
- Share request summary text.
- Status actions (fulfill/close/cancel) with confirmations.
- Visual status treatment for active vs non-active requests.

### Notifications and Sync Awareness

- In-app notification center for sync outcomes and reminders.
- Sync history with concise, human-readable status/error messages.
- Distinct notification behavior for event-based sync updates.

## UX Highlights

- Mobile-focused card layout and quick actions.
- Confirmation before sensitive actions (for example, calling a donor).
- Clear/intentional controls for optional fields (for example, clearing selected time).
- Readability-focused status cues across needs and recent activity.
