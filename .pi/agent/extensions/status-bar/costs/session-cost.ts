import type { ExtensionContext } from "@earendil-works/pi-coding-agent";

export function formatCost(amount: number): string {
	return `$${Math.max(0, amount).toFixed(2)}`;
}

function assistantMessageCost(message: unknown): number {
	if (!message || typeof message !== "object") return 0;
	const record = message as Record<string, unknown>;
	if (record.role !== "assistant") return 0;
	const usage = record.usage;
	if (!usage || typeof usage !== "object") return 0;
	const cost = (usage as Record<string, unknown>).cost;
	if (!cost || typeof cost !== "object") return 0;
	const total = (cost as Record<string, unknown>).total;
	return typeof total === "number" && Number.isFinite(total) ? total : 0;
}

function sessionCostFromEntries(ctx: ExtensionContext): number {
	// Recompute on session/reload so the cost segment survives /reload and /resume
	// without writing extension-owned state into the session file.
	return ctx.sessionManager.getEntries().reduce((total, entry) => {
		if (!entry || typeof entry !== "object") return total;
		const message = (entry as unknown as Record<string, unknown>).message;
		return total + assistantMessageCost(message);
	}, 0);
}

export class CostTracker {
	private total = 0;

	resetFromSession(ctx: ExtensionContext): void {
		this.total = sessionCostFromEntries(ctx);
	}

	recordMessage(message: unknown): number {
		const amount = assistantMessageCost(message);
		this.total += amount;
		return amount;
	}

	amount(): number {
		return this.total;
	}

	text(): string {
		return formatCost(this.total);
	}
}
