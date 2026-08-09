import { mkdirSync, readdirSync, readFileSync, renameSync, statSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

const STATE_PATH =
	process.env.STATUS_BAR_STATE ??
	join(process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state"), "pi", "status-bar-state.json");
const STATE_DIR = STATE_PATH.endsWith(".json") ? STATE_PATH.slice(0, -".json".length) : STATE_PATH;
const SESSION_FILE_RE = /^[A-Za-z0-9._-]+\.json$/;

export function formatWholeCost(amount: number): string {
	return `$${Math.round(Math.max(0, amount))}`;
}

function dateKey(date: Date): string {
	const year = date.getFullYear();
	const month = String(date.getMonth() + 1).padStart(2, "0");
	const day = String(date.getDate()).padStart(2, "0");
	return `${year}-${month}-${day}`;
}

function todayKey(): string {
	return dateKey(new Date());
}

function parseDateKey(value: string): Date | undefined {
	const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
	if (!match) return undefined;
	const date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
	return dateKey(date) === value ? date : undefined;
}

function safeSessionFileName(sessionId: string | undefined): string {
	const id = sessionId?.trim() || `pid-${process.pid}`;
	return `${id.replace(/[^A-Za-z0-9._-]/g, "_")}.json`;
}

function readAmount(path: string): number {
	try {
		const data = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
		const total = data.total;
		return typeof total === "number" && Number.isFinite(total) && total >= 0 ? total : 0;
	} catch {
		return 0;
	}
}

function writeAmount(path: string, total: number): void {
	mkdirSync(dirname(path), { recursive: true });
	const data = JSON.stringify({ total: Math.max(0, total) }, null, 2);
	const tmpPath = `${path}.${process.pid}.tmp`;
	writeFileSync(tmpPath, `${data}\n`, "utf8");
	renameSync(tmpPath, path);
}

function dayDir(date: string): string {
	return join(STATE_DIR, date);
}

function sumDay(date: string): number {
	const dir = dayDir(date);
	try {
		return readdirSync(dir)
			.filter((name) => SESSION_FILE_RE.test(name))
			.reduce((total, name) => total + readAmount(join(dir, name)), 0);
	} catch {
		return 0;
	}
}

function pruneOldDayDirs(today = new Date()): void {
	try {
		const cutoff = new Date(today);
		cutoff.setDate(cutoff.getDate() - 89);
		for (const name of readdirSync(STATE_DIR)) {
			const date = parseDateKey(name);
			if (!date || date >= cutoff || date > today) continue;
			const path = join(STATE_DIR, name);
			if (statSync(path).isDirectory()) renameSync(path, join(STATE_DIR, `${name}.old`));
		}
	} catch {
		// Best effort cleanup only.
	}
}

export class DailyCostTracker {
	private sessionFileName = safeSessionFileName(undefined);

	setSession(sessionId: string | undefined): void {
		this.sessionFileName = safeSessionFileName(sessionId);
	}

	load(): void {
		pruneOldDayDirs();
	}

	record(amount: number): void {
		if (amount <= 0) return;
		const today = todayKey();
		const path = join(dayDir(today), this.sessionFileName);
		writeAmount(path, readAmount(path) + amount);
	}

	dayAmount(): number {
		return sumDay(todayKey());
	}

	weekAmount(): number {
		const today = new Date();
		let total = 0;
		for (let offset = 0; offset < 7; offset++) {
			const date = new Date(today);
			date.setDate(today.getDate() - offset);
			total += sumDay(dateKey(date));
		}
		return total;
	}
}
