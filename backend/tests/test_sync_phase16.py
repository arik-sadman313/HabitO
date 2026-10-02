"""Phase 16 backend sync tests — Journal and Wellbeing."""
from datetime import datetime
import uuid


def test_mood_log_push_pull(client):
    """Mood logs can be pushed and pulled back via the sync endpoint."""
    # Register and login
    client.post("/api/v1/auth/register", json={
        "email": "moodtest@example.com",
        "password": "password123",
        "display_name": "Mood Test User"
    })
    login_resp = client.post("/api/v1/auth/login", json={
        "email": "moodtest@example.com",
        "password": "password123"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    mood_id = str(uuid.uuid4())

    # Push mood log
    push_resp = client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "device_mood_test",
        "operations": [{
            "entity_type": "mood_log",
            "entity_id": mood_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": mood_id,
                "user_id": user_id,
                "date": datetime.utcnow().isoformat(),
                "mood_rating": 4,
                "energy_rating": 3,
                "stress_rating": 2,
                "note": "Feeling good",
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert push_resp.status_code == 200
    assert push_resp.json()["changes_processed"] == 1

    # Pull and verify
    pull_resp = client.get("/api/v1/sync/pull?cursor=0", headers=headers)
    assert pull_resp.status_code == 200
    changes = pull_resp.json()["changes"]
    mood_changes = [c for c in changes if c["entity_type"] == "mood_log"]
    assert len(mood_changes) >= 1
    assert mood_changes[0]["entity_id"] == mood_id


def test_mood_log_soft_delete(client):
    """Mood log soft-delete propagates through sync."""
    client.post("/api/v1/auth/register", json={
        "email": "mooddelete@example.com",
        "password": "password123",
        "display_name": "Mood Delete"
    })
    login_resp = client.post("/api/v1/auth/login", json={
        "email": "mooddelete@example.com",
        "password": "password123"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    mood_id = str(uuid.uuid4())

    # Create then delete
    client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "device_mood_delete",
        "operations": [{
            "entity_type": "mood_log",
            "entity_id": mood_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": mood_id,
                "user_id": user_id,
                "date": datetime.utcnow().isoformat(),
                "mood_rating": 3,
                "energy_rating": 3,
                "stress_rating": 3,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })

    del_resp = client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "device_mood_delete",
        "operations": [{
            "entity_type": "mood_log",
            "entity_id": mood_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "delete",
            "changed_at": datetime.utcnow().isoformat(),
        }]
    })
    assert del_resp.status_code == 200
    assert del_resp.json()["changes_processed"] == 1


def test_journal_entry_push_pull(client):
    """Journal entries (personal type) can be pushed and pulled."""
    client.post("/api/v1/auth/register", json={
        "email": "journaltest@example.com",
        "password": "password123",
        "display_name": "Journal Test"
    })
    login_resp = client.post("/api/v1/auth/login", json={
        "email": "journaltest@example.com",
        "password": "password123"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    entry_id = str(uuid.uuid4())

    push_resp = client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "device_journal_test",
        "operations": [{
            "entity_type": "journal_entry",
            "entity_id": entry_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": entry_id,
                "user_id": user_id,
                "journal_type": 0,  # personal
                "title": "My Thoughts",
                "body": "Today was a good day.",
                "mood_id": None,
                "date": datetime.utcnow().isoformat(),
                "tags": "reflection,daily",
                "photo_url": None,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert push_resp.status_code == 200
    assert push_resp.json()["changes_processed"] == 1

    pull_resp = client.get("/api/v1/sync/pull?cursor=0", headers=headers)
    assert pull_resp.status_code == 200
    changes = pull_resp.json()["changes"]
    journal_changes = [c for c in changes if c["entity_type"] == "journal_entry"]
    assert len(journal_changes) >= 1
    assert journal_changes[0]["entity_id"] == entry_id


def test_journal_ownership_enforced(client):
    """User A cannot push journal entries scoped to User B."""
    # Register User A
    client.post("/api/v1/auth/register", json={
        "email": "jown_a@example.com",
        "password": "password123",
        "display_name": "Journal Owner A"
    })
    # Register User B
    client.post("/api/v1/auth/register", json={
        "email": "jown_b@example.com",
        "password": "password123",
        "display_name": "Journal Owner B"
    })

    login_a = client.post("/api/v1/auth/login", json={
        "email": "jown_a@example.com",
        "password": "password123"
    })
    token_a = login_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    login_b = client.post("/api/v1/auth/login", json={
        "email": "jown_b@example.com",
        "password": "password123"
    })
    user_b_id = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {login_b.json()['access_token']}"}).json()["id"]

    # User A tries to push into User B's scope — must be rejected
    entry_id = str(uuid.uuid4())
    resp = client.post("/api/v1/sync/push", headers=headers_a, json={
        "device_id": "device_a",
        "operations": [{
            "entity_type": "journal_entry",
            "entity_id": entry_id,
            "scope_type": "user",
            "scope_id": user_b_id,  # Wrong scope — User B's id
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": entry_id,
                "user_id": user_b_id,
                "journal_type": 0,
                "title": "Injected",
                "body": "This should not succeed.",
                "date": datetime.utcnow().isoformat(),
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert resp.status_code == 403


def test_shared_journal_not_visible_to_other_user(client):
    """A shared-type journal entry from User A must NOT appear in User B's pull.

    Phase 16 uses personal-account scoping. Shared-journal couple sync
    is deferred to a later phase. The pull endpoint is scoped to the
    authenticated user's own changes only.
    """
    # Register User A
    client.post("/api/v1/auth/register", json={
        "email": "shared_a@example.com",
        "password": "password123",
        "display_name": "Shared A"
    })
    # Register User B
    client.post("/api/v1/auth/register", json={
        "email": "shared_b@example.com",
        "password": "password123",
        "display_name": "Shared B"
    })

    login_a = client.post("/api/v1/auth/login", json={"email": "shared_a@example.com", "password": "password123"})
    token_a = login_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}
    user_a_id = client.get("/api/v1/auth/me", headers=headers_a).json()["id"]

    login_b = client.post("/api/v1/auth/login", json={"email": "shared_b@example.com", "password": "password123"})
    token_b = login_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    entry_id = str(uuid.uuid4())

    # User A pushes a shared-type journal entry scoped to User A
    client.post("/api/v1/sync/push", headers=headers_a, json={
        "device_id": "device_a_shared",
        "operations": [{
            "entity_type": "journal_entry",
            "entity_id": entry_id,
            "scope_type": "user",
            "scope_id": user_a_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": entry_id,
                "user_id": user_a_id,
                "journal_type": 1,  # shared type — but still User A's account
                "title": "Shared Entry",
                "body": "This is meant to be shared eventually.",
                "date": datetime.utcnow().isoformat(),
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })

    # User B pulls — must NOT receive User A's journal entry
    pull_resp = client.get("/api/v1/sync/pull?cursor=0", headers=headers_b)
    assert pull_resp.status_code == 200
    changes = pull_resp.json()["changes"]
    user_a_entries = [c for c in changes if c.get("entity_id") == entry_id]
    assert len(user_a_entries) == 0, (
        "User B must NOT see User A's journal entry — shared journal sync "
        "requires explicit couple-scoped authorization (Phase 17+)"
    )


def test_journal_cursor_advances(client):
    """Cursor advances correctly after journal sync."""
    client.post("/api/v1/auth/register", json={
        "email": "cursor_journal@example.com",
        "password": "password123",
        "display_name": "Cursor Journal"
    })
    login_resp = client.post("/api/v1/auth/login", json={
        "email": "cursor_journal@example.com",
        "password": "password123"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    entry_id = str(uuid.uuid4())
    client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "cursor_device",
        "operations": [{
            "entity_type": "journal_entry",
            "entity_id": entry_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": entry_id,
                "user_id": user_id,
                "journal_type": 0,
                "body": "Cursor test entry.",
                "date": datetime.utcnow().isoformat(),
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })

    pull1 = client.get("/api/v1/sync/pull?cursor=0", headers=headers).json()
    assert pull1["cursor"] > 0

    # Pull again with advanced cursor — should get no new changes
    pull2 = client.get(f"/api/v1/sync/pull?cursor={pull1['cursor']}", headers=headers).json()
    assert len(pull2["changes"]) == 0
