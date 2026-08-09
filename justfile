set shell := ["bash", "-euo", "pipefail", "-c"]

upstream_url := "https://github.com/jarnedemeulemeester/findroid.git"

# Build, install, and launch Findroid on the connected debugging device.
run:
    @adb get-state 2>/dev/null | grep -qx device || { echo "No debugging device connected. Check 'adb devices'." >&2; exit 1; }
    ./gradlew :app:phone:installLibreDebug
    adb shell am force-stop dev.jdtech.jellyfin.debug
    adb shell am start -W -n dev.jdtech.jellyfin.debug/dev.jdtech.jellyfin.MainActivity

# Update main from upstream, then rebase and push the personal branch.
sync-personal:
    #!/usr/bin/env bash
    set -euo pipefail
    test -z "$(git status --porcelain)" || { echo "Working tree is not clean." >&2; exit 1; }
    if ! git remote get-url upstream >/dev/null 2>&1; then
        git remote add upstream "{{ upstream_url }}"
    fi
    git fetch upstream
    git switch main
    git merge --ff-only upstream/main
    git push origin main
    git switch personal
    git rebase main
    git push --force-with-lease origin personal

# Start a development branch with personal changes available: just feature <name>
feature name:
    #!/usr/bin/env bash
    set -euo pipefail
    dev_branch="dev/{{ name }}"
    test -z "$(git status --porcelain)" || { echo "Working tree is not clean." >&2; exit 1; }
    git check-ref-format --branch "$dev_branch" >/dev/null
    git show-ref --verify --quiet "refs/heads/$dev_branch" && {
        echo "Branch $dev_branch already exists." >&2
        exit 1
    }
    git switch personal
    git switch -c "$dev_branch"
    git config "branch.${dev_branch}.personalBase" "$(git rev-parse personal)"
    echo "Develop and commit on $dev_branch. Run 'just prepare-pr {{ name }}' when ready."

# Regenerate a clean upstreamable feature branch while keeping the personal dev branch checked out.
prepare-pr name:
    #!/usr/bin/env bash
    set -euo pipefail
    dev_branch="dev/{{ name }}"
    pr_branch="feature/{{ name }}"
    test -z "$(git status --porcelain)" || { echo "Working tree is not clean." >&2; exit 1; }
    git show-ref --verify --quiet "refs/heads/$dev_branch" || {
        echo "Branch $dev_branch does not exist." >&2
        exit 1
    }
    personal_base="$(git config --get "branch.${dev_branch}.personalBase" || true)"
    test -n "$personal_base" || {
        echo "The personal base for $dev_branch is not recorded. Recreate it with 'just feature {{ name }}'." >&2
        exit 1
    }
    git merge-base --is-ancestor "$personal_base" "$dev_branch" || {
        echo "The recorded personal base is not an ancestor of $dev_branch." >&2
        exit 1
    }
    git branch -f "$pr_branch" "$dev_branch"
    git rebase --onto main "$personal_base" "$pr_branch"
    git switch "$dev_branch"
    echo "Prepared $pr_branch without personal commits."
    echo "Review with 'just review-pr {{ name }}', then push with 'just push-pr {{ name }}'."

# Show the commits and diff that would be submitted upstream.
review-pr name:
    @git show-ref --verify --quiet "refs/heads/feature/{{ name }}" || { echo "Branch feature/{{ name }} does not exist." >&2; exit 1; }
    git log --oneline main..feature/{{ name }}
    git diff --stat main...feature/{{ name }}
    git diff --check main...feature/{{ name }}

# Push the clean feature branch to the fork for a pull request.
push-pr name:
    @git show-ref --verify --quiet "refs/heads/feature/{{ name }}" || { echo "Branch feature/{{ name }} does not exist." >&2; exit 1; }
    git push --force-with-lease -u origin feature/{{ name }}
