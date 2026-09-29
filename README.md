# chatbot-copilot

A Flutter chat app connected to a **Microsoft Copilot Studio** agent through the **Direct Line** API.

## Workshop setup

Do these once, in order. You'll connect the app to your own Copilot Studio
agent.

### 1. Install the tools

- **Flutter 3.41 or newer** (check with `flutter --version`), plus an Android
  emulator, iOS simulator or phone.

### 2. Create your agent

1. In [Copilot Studio](https://copilotstudio.microsoft.com), create an agent.
   Add a website or upload a document as its knowledge if you want to see
   citations.
2. Open **Settings → Security → Authentication** and choose **No
   authentication**. The token endpoint only appears with this setting.
3. Click **Publish**. The app talks to the published agent, so publish again
   after every change.

### 3. Copy the token endpoint

Open **Channels → Mobile app** and copy the **Token Endpoint** URL. The app
asks this URL for a short-lived token, so no secret lives in the app.

### 4. Get the code and add your `.env`

```bash
git clone https://github.com/Meranzlan/chatbot-copilot-workshop.git
```

```bash
cd chatbot-copilot-workshop
```

```bash
cp .env.example .env
```

Open `.env` and replace the example `DIRECT_LINE_TOKEN_ENDPOINT` with the URL
from step 3. `.env` is gitignored: don't commit it or share it. The app and
the tests won't build until this file exists.

### 5. Run the app

```bash
flutter pub get
```

```bash
flutter run
```

Send a message. If your agent answers, you're set up. After changing `.env`,
fully restart the app (`R`); hot reload doesn't reread it.

## How it talks to Copilot Studio

Four HTTP calls, all in `lib/repository/chatbot_repository.dart`:

| Step | Call | What it does |
|---|---|---|
| 1 | `GET` token endpoint | Gets a short-lived token (no secret in the app) |
| 2 | `POST /conversations` | Opens a conversation |
| 3 | `POST /conversations/{id}/activities` | Sends your message |
| 4 | `GET /conversations/{id}/activities?watermark=…` | Checks for new replies, once a second |

The **watermark** is a bookmark: Direct Line only returns messages newer than it.

## Where things live

```
lib/
├── main.dart                        Starts the app, loads .env
├── config/
│   ├── app_config.dart              Settings from .env (bot name, token endpoint)
│   ├── app_colors.dart              Every colour in the app
│   └── demo_config.dart             On/off switches for features
├── models/
│   ├── chat_message.dart            One chat bubble
│   └── chat_citation.dart           One source the bot used
├── repository/
│   ├── chatbot_repository.dart      ★ The 4 Direct Line calls
│   └── api_client.dart              HTTP plumbing
├── controllers/
│   └── chat_controller.dart         ★ Chat state + the "any new replies?" loop
├── utils/
│   ├── citation_extractor.dart      Cleans replies, pulls out citations
│   └── open_link.dart               Opens links in a browser
└── views/
    ├── screens/home_page.dart       ★ The chat screen
    └── widgets/                     The pieces of the screen
```

Start with the three ★ files. The rest is polish you can read later.

## Things to try

- Flip a switch in `lib/config/demo_config.dart`, save, and press `r` in the terminal (hot reload).
- Change a colour in `lib/config/app_colors.dart` and hot reload.
- Change `BOT_NAME` in `.env`, then fully restart the app (`R`).
- Run the tests: `flutter test`

## Troubleshooting

**`No file or variants found for asset: .env`** (when building or testing)
There's no `.env` file yet. Do Workshop setup step 4 (`cp .env.example .env`).

**"DIRECT_LINE_TOKEN_ENDPOINT in .env is still the example"** or **"Add
DIRECT_LINE_TOKEN_ENDPOINT to your .env file"**
`.env` is missing or still has the placeholder. Do Workshop setup steps 3–4,
then restart the app (`R`).

**"Copilot Studio refused to start a chat"**
The token endpoint is wrong, or the agent isn't published or still requires
sign-in. Check Workshop setup step 2, copy the endpoint again, then restart
the app (`R`).

**"Can't reach Copilot Studio"**
No internet on the device or emulator. Fix the connection, then tap ↻.

**"Your session expired"**
Direct Line tokens only last a while. Tap ↻ to start a new conversation with
a fresh token.

**"… did not reply"**
The agent took longer than 60 seconds. Ask again. If it keeps happening, test
the agent in Copilot Studio's test pane.
