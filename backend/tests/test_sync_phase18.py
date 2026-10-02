"""Phase 18 backend sync tests — Screen Time Daily Snapshots."""
from datetime import datetime
import uuid


def test_screen_time_push_and_pull(client):
    """User A can push and pull their Screen Time daily snapshot."""
    client.post("/api/v1/auth/register", json={
        "email": "sta@example.com",
        "password": "password123",
        "display_name": "ST User A"
    })
    token = client.post("/api/v1/auth/login", json={"email": "sta@example.com", "password": "password123"}).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    snapshot_id = str(uuid.uuid4())

    push_resp = client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "device_st_a",
        "operations": [{
            "entity_type": "screen_time_daily_snapshot",
            "entity_id": snapshot_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": snapshot_id,
                "user_id": user_id,
                "date": datetime.utcnow().isoformat(),
                "total_duration_seconds": 14400, # 4 hours
                "app_count": 12,
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
    st_changes = [c for c in changes if c["entity_type"] == "screen_time_daily_snapshot"]
    assert len(st_changes) >= 1
    assert st_changes[0]["entity_id"] == snapshot_id
    assert st_changes[0]["payload"]["total_duration_seconds"] == 14400
    assert st_changes[0]["payload"]["app_count"] == 12


def test_screen_time_security_and_isolation(client):
    """User B cannot pull, modify, or delete User A's Screen Time snapshots."""
    # Register User A
    client.post("/api/v1/auth/register", json={"email": "stisol_a@example.com", "password": "password123", "display_name": "ST User A"})
    token_a = client.post("/api/v1/auth/login", json={"email": "stisol_a@example.com", "password": "password123"}).json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}
    user_a_id = client.get("/api/v1/auth/me", headers=headers_a).json()["id"]

    # Register User B
    client.post("/api/v1/auth/register", json={"email": "stisol_b@example.com", "password": "password123", "display_name": "ST User B"})
    token_b = client.post("/api/v1/auth/login", json={"email": "stisol_b@example.com", "password": "password123"}).json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}
    user_b_id = client.get("/api/v1/auth/me", headers=headers_b).json()["id"]

    snapshot_id = str(uuid.uuid4())

    # User A creates snapshot
    push_a = client.post("/api/v1/sync/push", headers=headers_a, json={
        "device_id": "dev_a",
        "operations": [{
            "entity_type": "screen_time_daily_snapshot",
            "entity_id": snapshot_id,
            "scope_type": "user",
            "scope_id": user_a_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": snapshot_id,
                "user_id": user_a_id,
                "date": datetime.utcnow().isoformat(),
                "total_duration_seconds": 7200,
                "app_count": 5,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert push_a.status_code == 200

    # User B cannot pull User A's snapshot
    pull_b = client.get("/api/v1/sync/pull?cursor=0", headers=headers_b).json()
    b_st = [c for c in pull_b["changes"] if c["entity_id"] == snapshot_id]
    assert len(b_st) == 0

    # User B cannot modify User A's snapshot under User A's scope
    mod_b_forbidden = client.post("/api/v1/sync/push", headers=headers_b, json={
        "device_id": "dev_b",
        "operations": [{
            "entity_type": "screen_time_daily_snapshot",
            "entity_id": snapshot_id,
            "scope_type": "user",
            "scope_id": user_a_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": snapshot_id,
                "user_id": user_a_id,
                "date": datetime.utcnow().isoformat(),
                "total_duration_seconds": 0,
                "app_count": 0,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert mod_b_forbidden.status_code == 403

    # User B cannot overwrite payload with user_a_id under user_b_id scope
    mod_b_mismatch = client.post("/api/v1/sync/push", headers=headers_b, json={
        "device_id": "dev_b",
        "operations": [{
            "entity_type": "screen_time_daily_snapshot",
            "entity_id": snapshot_id,
            "scope_type": "user",
            "scope_id": user_b_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": snapshot_id,
                "user_id": user_a_id,
                "date": datetime.utcnow().isoformat(),
                "total_duration_seconds": 0,
                "app_count": 0,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert mod_b_mismatch.status_code == 403

    # User B cannot delete User A's snapshot
    del_b_forbidden = client.post("/api/v1/sync/push", headers=headers_b, json={
        "device_id": "dev_b",
        "operations": [{
            "entity_type": "screen_time_daily_snapshot",
            "entity_id": snapshot_id,
            "scope_type": "user",
            "scope_id": user_a_id,
            "operation": "delete",
            "changed_at": datetime.utcnow().isoformat(),
            "is_deleted": True
        }]
    })
    assert del_b_forbidden.status_code == 403


def test_screen_time_upsert_update_in_place_and_cursor(client):
    """Updating today's snapshot overwrites the record in place and advances cursor."""
    client.post("/api/v1/auth/register", json={"email": "stcursor@example.com", "password": "password123", "display_name": "ST Cursor User"})
    token = client.post("/api/v1/auth/login", json={"email": "stcursor@example.com", "password": "password123"}).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    snapshot_id = str(uuid.uuid4())

    # 1. First snapshot push (e.g. at mid-day: 2 hours)
    client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "dev1",
        "operations": [{
            "entity_type": "screen_time_daily_snapshot",
            "entity_id": snapshot_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": snapshot_id,
                "user_id": user_id,
                "date": datetime.utcnow().isoformat(),
                "total_duration_seconds": 7200,
                "app_count": 5,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })

    pull1 = client.get("/api/v1/sync/pull?cursor=0", headers=headers).json()
    c1 = pull1["cursor"]
    assert c1 > 0

    # 2. Refresh snapshot push (e.g. at end of day: 5 hours, 10 apps)
    client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "dev1",
        "operations": [{
            "entity_type": "screen_time_daily_snapshot",
            "entity_id": snapshot_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": snapshot_id,
                "user_id": user_id,
                "date": datetime.utcnow().isoformat(),
                "total_duration_seconds": 18000,
                "app_count": 10,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })

    pull2 = client.get(f"/api/v1/sync/pull?cursor={c1}", headers=headers).json()
    assert pull2["cursor"] > c1
    updated_changes = [c for c in pull2["changes"] if c["entity_id"] == snapshot_id]
    assert len(updated_changes) == 1
    assert updated_changes[0]["payload"]["total_duration_seconds"] == 18000
    assert updated_changes[0]["payload"]["app_count"] == 10
