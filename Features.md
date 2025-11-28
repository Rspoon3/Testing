# Features

## Transcript Download & Viewing Prototype

**Description:** Initial prototype for downloading audiobook transcripts and viewing segments at specific timestamps.

**Components:**
- Models for Highlight, HighlightSegment, and TranscriptSegment
- Database manager for highlights storage using SQLiteData
- Transcript downloader service for fetching SQLite databases from backend
- Transcript repository for querying downloaded transcript files
- Demo view with timestamp input and segment display

**Status:** In Development

## Audiobook Library View

**Description:** Library interface for browsing and selecting audiobooks that have downloaded transcripts.

**Components:**
- Audiobook model with metadata (ID, highlight count, last accessed)
- AudiobookRepository service for discovering audiobooks from transcript files
- LibraryView for displaying list of available audiobooks
- LibraryViewModel for managing audiobook discovery and selection
- Navigation from library to transcript view for selected audiobooks
- Last accessed tracking using UserDefaults

**Status:** Completed
