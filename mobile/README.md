# E-Ticaret (Flutter)

Consumer marketplace client for the Express API in the parent folder.

## Architecture

- **Domain**: repository interfaces (`lib/domain/repositories/`).
- **Data**: REST clients, models, repository implementations (`lib/data/`).
- **Presentation**: screens, widgets, **Provider** (`ChangeNotifier`) for auth and catalog (`lib/presentation/`).

## API base URL

Default (see `lib/core/config/app_config.dart`):

| Platform | URL |
|----------|-----|
| Android emulator | `http://10.0.2.2:3000/api` |
| iOS simulator / desktop | `http://127.0.0.1:3000/api` |
| Web | `http://localhost:3000/api` |

Override at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Start the backend from the repo root: `npm start` (port **3000**).

## Run

```bash
cd mobile
flutter pub get
flutter run
```

## Features

- **Home**: paginated product list, pull-to-refresh, infinite scroll.
- **Product detail**: description and variants.
- **Auth**: login / register (JWT stored with `shared_preferences`); register does not log in automatically—switch to **Log in** after sign-up.

## Backend CORS

Ensure `.env` has `CORS_ORIGIN=*` or your Flutter web origin when testing on web.
