# Audiobook Marginalia App

## Overview

iOS app that allows users to create highlights and comments on audiobooks by using timestamped transcripts.

Users listen to audiobooks in their preferred podcast player (that supports sharing the timestamp for the current book). The app itself does not play audio.

At a high level, this app should enable users to:

- Download transcripts for audiobooks from my backend server
- Create highlights from audiobook passages using Shortcuts (or manually in the app)
- View / manage their highlights with optional comments
- Store all highlights and comments in iCloud
- Take notes fully offline once a transcript is downloaded

## Architecture

### Backend Integration

My backend server will provide audiobook transcripts via an endpoint like this:

`GET /audiobook/{audiobookId}/transcript`

Example request:
`GET https://vu.santiago.nyc/audiobook/ctx_2iyAq3QN4e7n9Kkt1Q8uyr/transcript`

- No authentication required
- No need for a way to browse all possible transcripts from the app. We'll only need this single endpoint to retrieve the transcript for one specific audiobook file at a time

### Data Storage

#### Transcript Storage

We'll need to do lookups on audiobook id + timestamp and each audiobook could have over 10,000 records in the transcript. The server will send the transcript as a SQLite database file that will just be merged into the app's local database. An alternative could have been to send the transcript as a large JSON file that the app would then need to parse and insert into its database.

**Transcript Schema:**

```sql
CREATE TABLE transcript_segment (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  audiobook_id TEXT NOT NULL,
  start_time REAL NOT NULL,
  end_time REAL NOT NULL,
  text TEXT NOT NULL,
);
```

#### Highlight Storage

After playing around with a few options, here's what I'm thinking for storing highlights.

- Since highlights will almost always span multiple segments, we'll need a mapping table to keep track of the segments used in a highlight
- Storing the full highlighted text across all segments in the highlight table allows for easy displaying and searching
- For editing, we can use character offsets in the the segment mappings table to exactly reconstruct the highlight view

```sql
CREATE TABLE highlight (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  audiobook_id TEXT NOT NULL,
  timestamp REAL NOT NULL,
  highlighted_text TEXT NOT NULL,
  comment TEXT,
  created_at TEXT NOT NULL,
  modified_at TEXT NOT NULL
);

CREATE TABLE highlight_segment (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  highlight_id INTEGER NOT NULL,
  segment_id INTEGER NOT NULL,
  start_char_offset INTEGER NOT NULL,  -- 0 means from beginning of segment
  end_char_offset INTEGER NOT NULL,    -- segment length means to end of segment
  FOREIGN KEY (highlight_id) REFERENCES highlight(id) ON DELETE CASCADE,
  FOREIGN KEY (segment_id) REFERENCES transcript_segment(id),
);
```

**Example Highlight:**

```sql
INSERT INTO highlight VALUES (
  1, 'ctx', 24320,
'He stepped into the store and waited for the cab to disappear down the street before emerging for the two-block walk to his safe house. Around him, tiny shops'
  'Here is a comment', '2025-11-19T10:30:00Z', '2025-11-19T10:30:00Z'
);

INSERT INTO highlight_segment VALUES
  (1, 1, 11, 1, 77), -- entire segment
  (2, 1, 12, 0, 57), -- entire segment
  (3, 1, 13, 0, 22); -- partial segment
```

## Features

### iOS Shortcuts Integration

The app exposes two shortcuts:

**1. Download Transcription Shortcut**

- Input: Audiobook ID
- Action: Opens app and initiates download of transcription for the specified audiobook

**2. Create Highlight Shortcut**

- Input: Audiobook ID, Timestamp (in seconds)
- Action:
  - Opens app
  - Looks up the transcription segments at the given timestamp
  - Displays the segment text along with surrounding context
  - User selects portion of text to highlight
  - User can optionally add a comment
  - User saves the highlight

### In-App Experience

**Library View** (main screen)

- List of downloaded audiobook transcripts
- Tapping an audiobook in this list shows its highlights

**Highlights View** (per audiobook)

- List of all highlights for the selected audiobook in order (maybe the user can choose to order by date or by timestamp?)
- Shows highlighted text and any associated comments
- User can edit or delete existing highlights and their comments
- User can also create a new highlight in this view
  - Hitting the add button will ask the user for a timestamp and from there, the flow is the same as it is via the shortcut

## Open Questions

1. **Missing transcription handling**
   How should we handle the scenario of the user running the shortcut to create a highlight at a timestamp but the transcript for the given audiobook id hasn't been downloaded yet?

   - Automatically download the transcript first, then proceed?
   - Show an error and present a button to manually download the missing transcript?

2. **Context window size**
   How many segments should be shown before and after the target timestamp?

   - Fixed number? (X segments before and after)
   - Time-based? (Y seconds before and after)

3. **Error handling**
   How should the app handle scenarios like:
   - Network failures during transcription download
   - iCloud sync conflicts
