# Project Overview

This project is a web application that contains a list of major problems and then associated "pitches" that Washington DC has today. The intent is to be a place to go to find "work" to do in DC that is meaningful.

## Folder Structure

- `/src`: Contains the source code for the frontend.
- `/pitches`: Contains markdown files for pitches
- `/problems`: Contains markdown files for problems

## Libraries and Frameworks

- React and Tailwind CSS for the frontend using NextJS.
- There is no backend and pitches and problems are associated via information in the markdown files.

## Coding Standards

Each problem must follow this structure:
```
# Problem: [Problem Name]

## Overview
Brief description of the problem and why it matters.  
Example: "Urban trash accumulation impacts public health, wildlife, and community well-being."

## Key Data & References
- Stat 1 (Source)
- Stat 2 (Source)
- Related organizations or initiatives

## Pitches Summary
Below is a list of pitches currently proposed for this problem.

| Pitch Title | Short Description | Impact (1–5) | Level of Effort (1–5) | Related Opportunities |
|-------------|------------------|--------------|-----------------------|-----------------------|
| [Pitch Name](pitch-file.md) | One-line summary of solution | 5 | 2 | [Grant X](link), [Competition Y](link) |
| [Another Pitch](another-pitch-file.md) | Short summary | 4 | 3 | [Funding Z](link) |

**Legend:**
- **Impact:** 1 = low effect on the problem, 5 = transformative  
- **Level of Effort:** 1 = easy/quick start, 5 = long-term complex  

## Opportunities
List of relevant funding, competitions, or business opportunities linked to this problem.

## Suggested Next Steps
- Which pitches could start quickly?  
- Which have funding already available?  
- Where is volunteer skill most needed?

## Related Problems
Links to other problems in the repo that share context.
```

Each pitch must follow this structure:

```markdown
# Pitch: [Pitch Title]

## Problem Context
Briefly restate the specific aspect of the larger problem this pitch addresses.  
Example: "Neighborhood trash build-up due to infrequent public bin emptying."

## Proposed Solution
Describe the solution clearly and concisely.  
Example: "Deploy community-managed smart bins that notify when full."

## Impact Estimate (1–5)
How much this pitch could move the needle on the problem.  
- **1:** Minimal impact  
- **5:** Transformative impact

### Impact Rationale
Provide reasoning for the impact score, backed by data if possible.  
Example:  
> "Based on DC Department of Public Works 2023 data, 40% of trash complaints are overflow-related. Smart bins in similar cities reduced overflow incidents by ~60%, suggesting a 20–25% total reduction in complaints for DC."

## Level of Effort Estimate (1–5)
Rough estimate of difficulty/complexity to start and execute.  
- **1:** Quick start, low resource needs  
- **5:** Multi-year, complex project

## Scope (Shape Up style)
- **Appetite**: How much time/resources we’re willing to spend  
- **Boundaries**: What’s explicitly out of scope  
- **No-Gos**: Approaches we won’t take

## Why This Could Work
Support with data, examples, or past successes.

## Risks
List key risks and unknowns for this pitch.

## Success Metrics
What measurable outcomes would indicate success?  
Example: “Reduce trash overflow complaints by 50% in 6 months.”

## Resources
Links to relevant research, tools, or prior art.

## Related Opportunities
- [Grant name](link) – deadline  
- [Competition name](link) – prize amount  
- [Revenue opportunity](link) – summary

## Contributors
Names / handles of people working on this pitch.
```

## UI guidelines
- The application should be responsive and accessible.
- Use a consistent color scheme and typography throughout the app.
- Provide clear feedback for user actions (e.g., loading indicators, success messages).
- Ensure all interactive elements are easily tappable/clickable.
