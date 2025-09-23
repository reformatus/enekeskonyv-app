# News System Documentation

## Overview

The Énekeskönyv app includes a news system that allows delivering messages directly to users through the app. This system is designed to be non-intrusive and works seamlessly with the existing app architecture.

## Features

- **Popup news display**: Unread news appears as modal dialogs when the app starts
- **Markdown support**: News content supports rich text formatting
- **Action buttons**: News can include optional action buttons with links
- **Read tracking**: The app tracks which news items have been read per user
- **Archiving**: News can be archived to stop showing to new users
- **Graceful degradation**: If the news API is unavailable, the app continues to work normally

## Architecture

### Components

1. **News Model** (`lib/models/news.dart`)
   - `News`: Main news item with ID, title, markdown content, archived flag, and action buttons
   - `NewsActionButton`: Optional action buttons with title and URI

2. **News Service** (`lib/services/news_service.dart`)
   - Fetches news from remote API
   - Filters unread news based on user preferences
   - Handles network errors gracefully

3. **News Dialog** (`lib/widgets/news_dialog.dart`)
   - Displays individual news items in modal dialogs
   - Supports markdown rendering and action buttons
   - Manages sequential display of multiple news items

4. **Settings Integration** (`lib/settings_provider.dart`)
   - Tracks read news IDs in SharedPreferences
   - Provides methods to mark news as read
   - Follows existing preference storage patterns

## API Format

The news API should return a JSON array of news objects:

```json
[
  {
    "id": "unique-news-id",
    "title": "News Title",
    "markdownText": "News content with **markdown** support",
    "archived": false,
    "actionButtons": [
      {
        "title": "Button Text", 
        "uri": "https://example.com"
      }
    ]
  }
]
```

### Field Descriptions

- `id` (string, required): Unique identifier for the news item
- `title` (string, required): News title displayed in dialog header
- `markdownText` (string, required): News content with markdown formatting
- `archived` (boolean, required): If true, news won't be shown to new users
- `actionButtons` (array, optional): Array of action button objects

### Action Button Format

- `title` (string, required): Text displayed on the button
- `uri` (string, required): URL to open when button is pressed

## Configuration

### API Endpoint

The default news API endpoint is:
```
https://reformatus.github.io/enekeskonyv-app/news.json
```

To change this, modify the `defaultNewsApiUrl` constant in `lib/services/news_service.dart`.

### Behavior

- News checking occurs after the app is fully initialized
- Only non-archived news that haven't been read are displayed
- News are displayed sequentially as modal dialogs
- Read news IDs are stored persistently in SharedPreferences
- Network errors are handled silently (app continues normally)

## Testing

Use the included `example_news_api.json` file as a reference for the expected API response format. This file can be served from any static hosting service.

## Deployment

1. Create a JSON file with your news content following the API format
2. Deploy it to a publicly accessible URL (e.g., GitHub Pages)
3. Update the API endpoint in the app if needed
4. Users will see new news items on their next app launch

## Privacy

- Only news IDs are stored locally to track read status
- No personal information is sent to the news API
- Users can clear their read status through app settings reset