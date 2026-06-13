from __future__ import annotations
import json, uuid
from pathlib import Path
from datetime import datetime
from typing import Any

DB_FILE = Path(__file__).resolve().parents[2] / 'mock_mongo.json'
DEFAULT = {
    'users': [], 'exercises': [], 'nutrition': [], 'goals': [],
    'wearable_logs': [], 'notifications': []
}

def _load() -> dict[str, list[dict[str, Any]]]:
    if not DB_FILE.exists():
        DB_FILE.write_text(json.dumps(DEFAULT, ensure_ascii=False, indent=2), encoding='utf-8')
    data = json.loads(DB_FILE.read_text(encoding='utf-8'))
    for key in DEFAULT:
        data.setdefault(key, [])
    return data

def _save(data: dict[str, list[dict[str, Any]]]) -> None:
    DB_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')

def now() -> str:
    return datetime.now().isoformat(timespec='seconds')

def insert(collection: str, doc: dict[str, Any]) -> dict[str, Any]:
    data = _load()
    item = {'id': str(uuid.uuid4()), **doc}
    data[collection].append(item)
    _save(data)
    return item

def find(collection: str, **query) -> list[dict[str, Any]]:
    rows = _load()[collection]
    def ok(row):
        return all(row.get(k) == v for k, v in query.items())
    return [r for r in rows if ok(r)]

def one(collection: str, **query) -> dict[str, Any] | None:
    rows = find(collection, **query)
    return rows[0] if rows else None

def update(collection: str, item_id: str, user_id: str | None, patch: dict[str, Any]) -> dict[str, Any] | None:
    data = _load()
    for row in data[collection]:
        if row.get('id') == item_id and (user_id is None or row.get('user_id') == user_id):
            row.update({k: v for k, v in patch.items() if v is not None})
            _save(data)
            return row
    return None

def delete(collection: str, item_id: str, user_id: str | None = None) -> bool:
    data = _load()
    before = len(data[collection])
    data[collection] = [r for r in data[collection] if not (r.get('id') == item_id and (user_id is None or r.get('user_id') == user_id))]
    _save(data)
    return len(data[collection]) < before

def delete_by_user(collection: str, user_id: str) -> int:
    data = _load()
    before = len(data[collection])
    data[collection] = [r for r in data[collection] if r.get('user_id') != user_id]
    _save(data)
    return before - len(data[collection])
