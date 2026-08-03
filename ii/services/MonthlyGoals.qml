pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common

Singleton {
    id: root

    property string filePath: Directories.monthlyGoalsPath
    property string archivePath: Directories.monthlyGoalsArchiveDir

    // Top-level metadata. Persisted so we can evolve the format
    // without breaking older files.
    property string currentMonth: ""
    property string createdAt: ""   // ISO timestamp when this month was first opened
    property string completedAt: "" // ISO timestamp when the last goal was checked off
    property int version: 1
    property var goals: []

    // UI-facing "this is the first time the user has reached 100%" pulse trigger.
    // Set true on the transition 0 → 1, then the widget reads + resets it.
    property bool justCompleted: false

    readonly property int totalCount: goals.length

    readonly property int completedCount: {
        var c = 0
        for (var i = 0; i < goals.length; i++) {
            if (goals[i].done)
                c++
        }
        return c
    }

    readonly property real progress:
        totalCount === 0 ? 0 : completedCount / totalCount

    // ---------- helpers ----------

    function monthString(date) {
        const d = date || new Date();
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, "0");
        return `${y}-${m}`;
    }

    function archiveFilename(monthStr) {
        const m = monthStr || root.currentMonth;
        return `${root.archivePath}/${m}.json`;
    }

    function newId() {
        return Date.now().toString() + Math.floor(Math.random() * 10000);
    }

    // Build the on-disk document. Centralized so save() and archiveIfNeeded() stay in sync.
    function buildSnapshot() {
        return {
            month: root.currentMonth,
            createdAt: root.createdAt,
            completedAt: root.completedAt,
            version: root.version,
            goals: root.goals,
        };
    }

    // ---------- core ----------

    function refresh() {
        const fileContents = fileView.text();
        if (!fileContents || fileContents.length === 0) {
            // First-run: create a fresh document for the current month.
            root.currentMonth = monthString();
            root.createdAt = new Date().toISOString();
            root.completedAt = "";
            root.version = 1;
            root.goals = [];
            save();
            return;
        }

        let parsed;
        try {
            parsed = JSON.parse(fileContents);
        } catch (e) {
            console.warn("[MonthlyGoals] Failed to parse current.json, resetting:", e);
            parsed = { month: monthString(), goals: [] };
        }

        root.currentMonth = parsed.month || monthString();
        root.createdAt = parsed.createdAt || new Date().toISOString();
        root.completedAt = parsed.completedAt || "";
        root.version = parsed.version || 1;
        root.goals = Array.isArray(parsed.goals) ? parsed.goals : [];

        archiveIfNeeded();
    }

    function save() {
        fileView.setText(JSON.stringify(buildSnapshot(), null, 4));
    }

    function addGoal(text) {
        if (typeof text !== "string") return;
        const trimmed = text.trim();
        if (trimmed.length === 0) return;

        const goal = {
            id: newId(),
            text: trimmed,
            done: false,
            createdAt: new Date().toISOString(),
        };

        // Reassign to trigger onGoalsChanged bindings
        root.goals = root.goals.concat([goal]);
        save();
    }

    function toggleGoal(id) {
        const next = root.goals.slice();
        let wasComplete = false;
        let becomesComplete = false;
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                wasComplete = next[i].done;
                next[i] = Object.assign({}, next[i], { done: !next[i].done });
                becomesComplete = next[i].done;
                break;
            }
        }

        // Detect the 100% transition: was incomplete AND now all done.
        if (!wasComplete && becomesComplete && next.length > 0) {
            const allDone = next.every(function (g) { return g.done; });
            if (allDone) {
                root.completedAt = new Date().toISOString();
                root.justCompleted = true;
            }
        }
        // Detect the 100% → not-100% transition (user unchecked a goal after completion).
        if (root.completedAt !== "" && next.some(function (g) { return !g.done; })) {
            root.completedAt = "";
        }

        root.goals = next;
        save();
    }

    function editGoal(id, text) {
        if (typeof text !== "string") return;
        const trimmed = text.trim();
        if (trimmed.length === 0) return;

        const next = root.goals.slice();
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                next[i] = Object.assign({}, next[i], { text: trimmed });
                break;
            }
        }
        root.goals = next;
        save();
    }

    function removeGoal(id) {
        const next = root.goals.filter(function (g) { return g.id !== id; });
        // If the removal drops us below 100%, clear completedAt.
        if (root.completedAt !== "" && next.some(function (g) { return !g.done; })) {
            root.completedAt = "";
        }
        root.goals = next;
        save();
    }

    function acknowledgeCompletion() {
        // Called by the UI after it shows the celebration once, so the
        // pulse only fires once per completion event.
        root.justCompleted = false;
    }

    function archiveIfNeeded() {
        const current = monthString();
        if (root.currentMonth === current) return;

        // Move the current (stale) document into the archive before resetting.
        const archiveUrl = Qt.resolvedUrl(archiveFilename(root.currentMonth));
        const archiveView = fileViewFactory.createObject(null, { path: archiveUrl });
        if (archiveView) {
            archiveView.setText(JSON.stringify(buildSnapshot(), null, 4));
            archiveView.destroy();
        } else {
            console.warn("[MonthlyGoals] Could not create archive FileView for",
                archiveFilename(root.currentMonth));
        }

        // Start the new month fresh.
        root.currentMonth = current;
        root.createdAt = new Date().toISOString();
        root.completedAt = "";
        root.version = 1;
        root.goals = [];
        save();
    }

    // A reusable FileView factory for writing one-off files (e.g. archive snapshots).
    // Quickshell singletons cannot use `Component { id }` inline, so we instantiate one dynamically.
    Component {
        id: fileViewFactory
        FileView {}
    }

    Component.onCompleted: refresh()

    FileView {
        id: fileView
        path: Qt.resolvedUrl(root.filePath)
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                console.log("[MonthlyGoals] current.json missing, will be created on first save.");
            } else {
                console.warn("[MonthlyGoals] Failed to load current.json:", error);
            }
        }
    }
}