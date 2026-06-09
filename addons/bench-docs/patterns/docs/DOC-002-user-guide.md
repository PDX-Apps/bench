# User guide — structure

A user guide tells **a person using the product how to accomplish a task** — what to click, what to type, what they'll see. It's written for an **end user, not a developer**: no code, no file paths, no internals. Optimize for someone following along with the screen in front of them.

## Who it's for

The reader has the app open and a goal ("invite a teammate", "export my data", "set up notifications"). They don't care how it's built — only the steps to get the outcome. Write in plain language, second person ("you"), present tense.

## Ground it in the real UI

Even though there's no code in the output, the steps must match what the app **actually** does. Read the real UI to get them right:

- the **route/page** the task starts on, and its real **navigation path** (which menu, which button label),
- the actual **labels** of buttons, fields, and links (quote them exactly — "click **Save changes**", not "click the save button"),
- the real **flow and branches** (what screen comes next, what a toggle does, what validation blocks),
- the **end state** the user should see (a confirmation, a new item in a list).

Pull these from the components/pages/routes — never invent a button or screen that isn't there.

## Structure

```markdown
# {Task the user wants to accomplish}

{1 sentence: what this lets you do and when you'd want to.}

**Before you start:** {prerequisites in user terms — "you need an admin account", "you must be signed in". Omit if none.}

## Steps

1. {Plain action with the real label} — e.g. "From the sidebar, click **Settings**."
2. {Next action} — "In the **Team** tab, click **Invite member**."
3. {What to type/choose} — "Enter the person's email and pick a **role**."
4. {Submit} — "Click **Send invite**."

{Optionally, a screenshot reference after a step where seeing it helps: `![Invite dialog](images/invite-dialog.png)`}

## What you'll see

{The success state — "The teammate appears in the list marked *Pending* until they accept."}

## Troubleshooting

{Common snags in user terms — "Didn't get the email? Check spam, or resend from the list." Only real, observed cases. Omit if none.}
```

## Conventions

- **End-user voice** — no code, no file paths, no jargon. "Click", "type", "choose", "you'll see".
- **Exact labels** — quote the real on-screen text in **bold** so the reader can match it to the screen.
- **Task-oriented** — one guide per task the user wants to do, titled by the goal, not by a feature name.
- **Grounded** — every step, label, and screen is verified against the actual UI; mark anything you couldn't confirm as an open question rather than inventing it.
- **Screenshots where they earn it** — reference an image at the steps that are easy to get lost on; don't paper the whole guide with them. (The writer notes where a screenshot belongs; capturing it may be a follow-up.)
