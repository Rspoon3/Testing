# SwiftUI Currency TextField Formats Prematurely, Causing Unexpected Input Behavior

Is there a way to prevent `TextField` with `.currency` format from reformatting during active editing? Or is a custom solution (e.g., a `String`-backed text field with manual formatting on commit) the only reliable approach for currency input?

## Problem

I'm using a SwiftUI `TextField` with a currency `FormatStyle` and an optional `Double?` binding. I want the field to start with a placeholder (`$100`), and when the user types `2` then `5`, the result should be `$25.00`.

**What actually happens:**

1. The field starts with the placeholder — good.
2. I type `2` — the field immediately reformats to `$2.00`.
3. I type `5` — instead of `$25.00`, I get `$2.005` because the cursor is placed after the formatted value.

The currency format is applied **during** editing rather than **after** editing ends, which breaks multi-digit input.

## Code

```swift
struct ContentView: View {
    @State private var value: Double?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            TextField(
                "$100",
                value: $value,
                format: .currency(code: Locale.current.currency?.identifier ?? "USD")
            )
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
        }
    }
}
```

## What I've Tried

### `NumberFormatter` without `isLenient`

```swift
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.maximumFractionDigits = 2

TextField("$0.00", value: $value, formatter: formatter)
```

When dismissing the keyboard, the value **does not save at all** — the field reverts to the placeholder. The formatter fails to parse plain number input like `"25"` because it expects a currency-formatted string (e.g. `"$25.00"`).

### `NumberFormatter` with `isLenient = true`

```swift
formatter.isLenient = true
```

This fixes the parsing issue — the value now saves. However, it introduces the **same premature formatting problem**: typing `2` immediately reformats to `$2.00`, and the next digit `5` appends to produce `$2.005`.

## Expected Behavior

- User types `2` → field shows `2`
- User types `5` → field shows `25`
- User taps "Done" → field formats to `$25.00`

The formatting should only be applied **after** editing ends, not on every keystroke.

## Environment

- Xcode 26
- iOS 26
- SwiftUI `TextField` with `value:format:` initializer

