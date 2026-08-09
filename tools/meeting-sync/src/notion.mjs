// Minimal Notion API client for meeting-sync (zero dependencies, native fetch).
//
// The meeting-notes endpoint is beta and version-pinned; the Notion-Version
// header is supplied per-call from config so it is easy to bump.

const API = "https://api.notion.com/v1";

/** Low-level request helper with Notion auth + version headers. */
async function request(path, { token, version, method = "GET", body } = {}) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Notion-Version": version,
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }
  if (!res.ok) {
    const msg = json?.message || json?.raw || res.statusText;
    const err = new Error(`Notion ${method} ${path} -> ${res.status}: ${msg}`);
    err.status = res.status;
    err.body = json;
    throw err;
  }
  return json;
}

/**
 * Query meeting notes where the integration's user is an attendee.
 * See https://developers.notion.com/reference/query-meeting-notes
 *
 * @param {object} opts
 * @param {string} opts.token
 * @param {string} opts.version  Notion-Version header value
 * @param {object} [opts.filter] property filter or and/or combinator
 * @param {object[]} [opts.sort] array of { property, direction }
 * @param {number} [opts.limit]  1..50
 */
export function queryMeetingNotes({ token, version, filter, sort, limit }) {
  const body = {};
  if (filter) body.filter = filter;
  if (sort) body.sort = sort;
  if (limit != null) body.limit = limit;
  return request("/meeting_notes/query", { token, version, method: "POST", body });
}

/** Fetch the children blocks of a block (e.g. a summary/notes/transcript tab). */
export function getBlockChildren({ token, version, blockId, pageSize = 100, startCursor }) {
  const params = new URLSearchParams({ page_size: String(pageSize) });
  if (startCursor) params.set("start_cursor", startCursor);
  return request(`/blocks/${blockId}/children?${params}`, { token, version });
}

/** Fetch all children of a block, following pagination. */
export async function getAllBlockChildren({ token, version, blockId }) {
  const blocks = [];
  let cursor;
  do {
    const page = await getBlockChildren({ token, version, blockId, startCursor: cursor });
    blocks.push(...(page.results ?? []));
    cursor = page.has_more ? page.next_cursor : undefined;
  } while (cursor);
  return blocks;
}
