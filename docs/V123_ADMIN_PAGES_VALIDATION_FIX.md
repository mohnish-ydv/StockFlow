# StockFlow v1.2.3 — Admin Pages validation fix

Target: `1.2.3+21`

## CI failure

The admin page is valid HTML and intentionally loads Leaflet with an external `<script src=...></script>` plus one inline StockFlow application `<script>...</script>`. The GitHub Pages validation job incorrectly asserted that the document had exactly one closing `</script>` tag.

## Fix

The validator now checks:

- opening and closing script tags are balanced;
- there is exactly one inline StockFlow application script;
- an external Leaflet script is present;
- one HTML root is present;
- privileged credentials remain forbidden in `docs/admin`.

No production feature or UI behavior was removed.
