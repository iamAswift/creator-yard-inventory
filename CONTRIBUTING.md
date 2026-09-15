# Contributing to Creator Yard

Thank you for your interest in contributing to Creator Yard.

Creator Yard is a Flutter-based offline-first POS and inventory platform designed for retail businesses. The project is intended to be improved through contributions from developers, hardware integrators, implementation partners, and other members of the community.

We welcome bug fixes, documentation improvements, testing, feature development, architecture discussions, hardware testing, and other meaningful contributions.

---

## Before You Contribute

Before making a significant change, take some time to understand the project.

Start with:

1. `README.md`
2. `ROADMAP.md`, if available
3. The relevant documentation under `docs/`
4. Existing GitHub Issues and Discussions

For questions, design proposals, and ideas that are not yet clearly defined, use GitHub Discussions before opening an Issue.

---

## GitHub Discussions

Use Discussions for conversations that do not yet represent a concrete development task.

Good topics for Discussions include:

* Development questions
* Architecture discussions
* Database design
* Feature ideas
* Android and POS hardware experiences
* Integration ideas
* Questions about the codebase
* Community suggestions
* Contribution planning

A discussion can later become an Issue when the required work is clearly defined.

---

## GitHub Issues

Use Issues for actionable development work.

Create an Issue when you have:

* A reproducible bug
* A specific implementation task
* A defined feature
* A documentation task
* A concrete improvement
* A clearly identified technical problem

### Before opening a bug report

Please check whether the problem has already been reported.

When possible, include:

* Flutter version
* Dart version
* Operating system
* Device or POS hardware
* Creator Yard version or commit
* Steps to reproduce
* Expected behavior
* Actual behavior
* Relevant error messages or logs
* Screenshots when useful

Avoid posting passwords, API credentials, installation credentials, private customer information, or other sensitive data.

---

## Pull Requests

Pull Requests should be focused and reviewable.

A good Pull Request should:

* Address one logical change
* Explain what was changed
* Explain why the change was necessary
* Identify relevant Issues or Discussions
* Avoid unrelated changes
* Include testing information
* Include screenshots for significant UI changes when useful

Keep Pull Requests reasonably small where possible. Smaller changes are easier to review, test, and maintain.

---

## Development Workflow

A typical contribution should follow this process:

```text
Discussion / Issue
        ↓
Understand the requirement
        ↓
Create a focused change
        ↓
Run formatting and analysis
        ↓
Test the change
        ↓
Create Pull Request
        ↓
Code review
        ↓
Revision if required
        ↓
Merge
```

For larger changes, discuss the proposed approach before beginning implementation.

---

## Working With the Database

Creator Yard uses Drift/SQLite for local application data.

Database changes require additional care because existing installations may already contain important business data.

When modifying:

* tables
* DAOs
* database models
* migrations
* generated Drift files
* settings
* business data

consider existing installations and data compatibility.

Do not introduce destructive database changes without a clear migration and recovery strategy.

Never ask users to uninstall the application or clear application data as a routine solution to a database problem.

---

## Generated Files

Some project files are generated from source definitions.

When working with Drift or other generated code:

1. Modify the source definition.
2. Run the appropriate generator.
3. Review the generated changes.
4. Test the application.
5. Include generated files when they are tracked by the repository and required by the project.

Do not manually modify generated files unless there is a specific reason to do so.

---

## UI and Design Contributions

Creator Yard uses shared theme and responsive design patterns.

When changing the UI:

* Prefer existing theme tokens and shared styles.
* Prefer existing responsive utilities.
* Avoid unnecessary hard-coded dimensions.
* Consider phone, tablet, desktop, and POS layouts.
* Preserve accessibility and readable touch targets.
* Avoid introducing a new visual pattern when an existing project component already solves the problem.

UI changes should be tested at the relevant screen sizes when possible.

---

## Hardware Contributions

Creator Yard may be deployed on Android tablets and POS hardware.

If your contribution involves hardware, document the hardware you tested with when relevant.

Useful information includes:

* Device manufacturer
* Device model
* Android version
* Display resolution
* Printer/scanner model
* Connection method
* Relevant permissions
* Reproduction steps

Hardware-specific behavior should not be assumed to work on every Android device without testing.

---

## Testing

Before submitting a Pull Request, run the checks relevant to your change.

At minimum, for Flutter code changes:

```bash
flutter analyze
```

Format changed Dart files as appropriate:

```bash
dart format <changed-files>
```

Run relevant tests when available:

```bash
flutter test
```

For UI or hardware changes, test on the relevant target device when possible.

Do not claim that a change was tested on hardware that you did not actually test.

---

## Commit Messages

Use clear commit messages that describe the change.

Examples:

```text
Add supplier payment validation
Fix product edit form state handling
Improve POS product grid layout
Add daily report export
Update contributor documentation
```

Avoid vague messages such as:

```text
fix stuff
changes
update
test
```

---

## Keep Changes Focused

Avoid combining unrelated changes in one Pull Request.

For example, a Pull Request fixing a supplier payment bug should not also contain:

* unrelated UI redesigns
* package upgrades
* formatting of unrelated files
* database restructuring
* unrelated documentation changes

Keeping changes focused makes review safer and faster.

---

## Security

Do not publicly disclose security vulnerabilities through a normal Issue or Discussion.

Do not commit:

* API credentials
* access tokens
* passwords
* private keys
* installation credentials
* customer data
* production database files
* private configuration files

For security-sensitive issues, follow the project's security reporting process.

---

## Commercial Use and Partnerships

Creator Yard is an open development project, but cloning or contributing to the public repository does not automatically grant commercial resale, redistribution, implementation, or partnership rights.

Commercial deployment, redistribution, licensing, implementation partnerships, and reseller arrangements are subject to the applicable Creator Yard licensing and partnership terms.

Contributors may participate in the public development of the project without being authorized commercial partners.

---

## Community Conduct

Contributors are expected to:

* Be respectful.
* Assume good faith.
* Discuss technical issues objectively.
* Provide useful information when reporting problems.
* Accept constructive technical feedback.
* Avoid personal attacks.
* Avoid harassment or discriminatory behavior.
* Keep discussions relevant to Creator Yard.
* Respect project maintainers and other contributors.

Technical disagreement is welcome. Personal hostility is not.

The goal is to build a useful and sustainable project together.

---

## Maintainer Review

Submitting a Pull Request does not guarantee that it will be accepted.

Maintainers may request:

* Changes to implementation
* Additional tests
* Documentation
* Different architectural approaches
* Smaller or more focused changes
* Compatibility considerations
* Additional hardware testing

The project maintainers have final responsibility for deciding what is merged into the main project.

---

## Questions?

If you are unsure where something belongs:

**Have a question or idea?**

Start a GitHub Discussion.

**Have a confirmed bug or concrete task?**

Open a GitHub Issue.

**Have an implementation ready?**

Open a Pull Request.

**Have a security concern?**

Use the project's security reporting process.

Thank you for helping improve Creator Yard.
