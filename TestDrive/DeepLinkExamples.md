# TestDrive Deep Link Examples

## Navigation Deep Links (Push to Navigation Stack)
- `testdrive://color/red` - Navigate to red screen
- `testdrive://color/blue` - Navigate to blue screen  
- `testdrive://color/green` - Navigate to green screen
- `testdrive://color/yellow` - Navigate to yellow screen
- `testdrive://color/purple` - Navigate to purple screen

## Sheet Deep Links (Modal Presentation)
- `testdrive://color/red?sheet=true` - Present red screen as sheet
- `testdrive://color/blue?sheet=true` - Present blue screen as sheet
- `testdrive://color/orange?sheet=true` - Present orange screen as sheet
- `testdrive://color/pink?sheet=true` - Present pink screen as sheet
- `testdrive://color/purple?sheet=true` - Present purple screen as sheet

## Testing Queue Behavior

### Single Link Test
1. Open any single deep link above
2. Watch the 2-second network simulation delay
3. See the screen/sheet appear after processing

### Multiple Links Test (Cold Start)
1. Kill the app completely
2. Rapidly open multiple deep links in Safari:
   - `testdrive://color/red`
   - `testdrive://color/blue?sheet=true` 
   - `testdrive://color/green`
3. App will queue all links and process them one by one

### Queue Test via App
1. Open the app
2. Tap "Queue 3 Links" button
3. Watch as links are processed sequentially with delays

## URL Format
`testdrive://host/path?queryParameters`

- **Scheme**: Always `testdrive`
- **Host**: `color` for color-based actions
- **Path**: Color name (red, blue, green, etc.)
- **Query**: `sheet=true` for modal presentation

## Expected Behavior
- Each deep link waits 2 seconds (simulated network call)
- Links are processed in FIFO order
- Cold start links are queued and processed after app initialization
- Queue status is visible in the main UI
- Navigation links push to navigation stack
- Sheet links present modally over current content