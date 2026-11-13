---
description: Capture portable working context directly in on-track/handoffs/.
---

Run the `ot-handoff` skill. The focus comes from the arguments. The skill writes directly to `on-track/handoffs/YYYY-MM-DD-HHmmssZ-<slug>.md`, with `captured` set to the same UTC instant, preserves active user instructions verbatim, lists next steps in one ordered `## Next actions` list, orders by `captured`, validates the new handoff before archiving, and archives older handoffs before running the index. It stops on active or archive path collisions without overwriting.
