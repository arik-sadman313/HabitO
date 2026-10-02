"""Phase 17 backend sync tests — Personal Goals."""
from datetime import datetime
import uuid


def test_personal_goal_push_and_pull(client):
    """User A can create/push and pull their own personal goal."""
    client.post("/api/v1/auth/register", json={
        "email": "goala@example.com",
        "password": "password123",
        "display_name": "Goal User A"
    })
    login_resp = client.post("/api/v1/auth/login", json={
        "email": "goala@example.com",
        "password": "password123"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    goal_id = str(uuid.uuid4())

    push_resp = client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "device_goal_a",
        "operations": [{
            "entity_type": "personal_goal",
            "entity_id": goal_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": goal_id,
                "user_id": user_id,
                "title": "Study 50 Hours",
                "description": "Monthly study goal",
                "goal_type": "studyDuration",
                "target_value": 50.0,
                "current_value": 0.0,
                "unit": "hours",
                "start_date": datetime.utcnow().isoformat(),
                "target_date": datetime.utcnow().isoformat(),
                "status": 0,
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
    goal_changes = [c for c in changes if c["entity_type"] == "personal_goal"]
    assert len(goal_changes) >= 1
    assert goal_changes[0]["entity_id"] == goal_id
    assert goal_changes[0]["payload"]["title"] == "Study 50 Hours"


def test_personal_goal_security_and_isolation(client):
    """User B cannot pull, modify, or delete User A's personal goals, and payload userId mismatch is rejected."""
    # Register User A
    client.post("/api/v1/auth/register", json={
        "email": "goalisol_a@example.com",
        "password": "password123",
        "display_name": "Goal User A"
    })
    token_a = client.post("/api/v1/auth/login", json={"email": "goalisol_a@example.com", "password": "password123"}).json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}
    user_a_id = client.get("/api/v1/auth/me", headers=headers_a).json()["id"]

    # Register User B
    client.post("/api/v1/auth/register", json={
        "email": "goalisol_b@example.com",
        "password": "password123",
        "display_name": "Goal User B"
    })
    token_b = client.post("/api/v1/auth/login", json={"email": "goalisol_b@example.com", "password": "password123"}).json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}
    user_b_id = client.get("/api/v1/auth/me", headers=headers_b).json()["id"]

    goal_id = str(uuid.uuid4())

    # User A creates goal
    push_a = client.post("/api/v1/sync/push", headers=headers_a, json={
        "device_id": "device_a",
        "operations": [{
            "entity_type": "personal_goal",
            "entity_id": goal_id,
            "scope_type": "user",
            "scope_id": user_a_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": goal_id,
                "user_id": user_a_id,
                "title": "User A Goal",
                "description": "Secret goal",
                "goal_type": "custom",
                "target_value": 10.0,
                "current_value": 2.0,
                "unit": "steps",
                "start_date": datetime.utcnow().isoformat(),
                "status": 0,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert push_a.status_code == 200

    # User B cannot pull User A's goal
    pull_b = client.get("/api/v1/sync/pull?cursor=0", headers=headers_b)
    assert pull_b.status_code == 200
    b_changes = [c for c in pull_b.json()["changes"] if c["entity_id"] == goal_id]
    assert len(b_changes) == 0

    # User B cannot modify User A's goal by passing scope_id = user_a_id
    mod_b_forbidden = client.post("/api/v1/sync/push", headers=headers_b, json={
        "device_id": "device_b",
        "operations": [{
            "entity_type": "personal_goal",
            "entity_id": goal_id,
            "scope_type": "user",
            "scope_id": user_a_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": goal_id,
                "user_id": user_a_id,
                "title": "Hacked Goal",
                "goal_type": "custom",
                "target_value": 1.0,
                "start_date": datetime.utcnow().isoformat(),
                "status": 0,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert mod_b_forbidden.status_code == 403

    # User B cannot overwrite payload with user_a_id under user_b_id scope
    mod_b_mismatch = client.post("/api/v1/sync/push", headers=headers_b, json={
        "device_id": "device_b",
        "operations": [{
            "entity_type": "personal_goal",
            "entity_id": goal_id,
            "scope_type": "user",
            "scope_id": user_b_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": goal_id,
                "user_id": user_a_id,
                "title": "Hacked Goal Mismatch",
                "goal_type": "custom",
                "target_value": 1.0,
                "start_date": datetime.utcnow().isoformat(),
                "status": 0,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert mod_b_mismatch.status_code == 403

    # User B cannot delete User A's goal
    del_b_forbidden = client.post("/api/v1/sync/push", headers=headers_b, json={
        "device_id": "device_b",
        "operations": [{
            "entity_type": "personal_goal",
            "entity_id": goal_id,
            "scope_type": "user",
            "scope_id": user_a_id,
            "operation": "delete",
            "changed_at": datetime.utcnow().isoformat(),
            "is_deleted": True
        }]
    })
    assert del_b_forbidden.status_code == 403


def test_personal_goal_soft_delete_and_cursor(client):
    """Soft deletion propagates and cursor progression advances correctly for personal goals."""
    client.post("/api/v1/auth/register", json={
        "email": "goalcursor@example.com",
        "password": "password123",
        "display_name": "Goal Cursor User"
    })
    token = client.post("/api/v1/auth/login", json={"email": "goalcursor@example.com", "password": "password123"}).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    goal_id = str(uuid.uuid4())

    # 1. Upsert
    client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "dev1",
        "operations": [{
            "entity_type": "personal_goal",
            "entity_id": goal_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": goal_id,
                "user_id": user_id,
                "title": "Goal to delete",
                "goal_type": "custom",
                "target_value": 5.0,
                "start_date": datetime.utcnow().isoformat(),
                "status": 0,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })

    pull1 = client.get("/api/v1/sync/pull?cursor=0", headers=headers).json()
    c1 = pull1["cursor"]
    assert c1 > 0

    # 2. Delete
    client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "dev1",
        "operations": [{
            "entity_type": "personal_goal",
            "entity_id": goal_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "delete",
            "changed_at": datetime.utcnow().isoformat(),
            "is_deleted": True
        }]
    })

    pull2 = client.get(f"/api/v1/sync/pull?cursor={c1}", headers=headers).json()
    assert pull2["cursor"] > c1
    del_changes = [c for c in pull2["changes"] if c["entity_id"] == goal_id]
    assert len(del_changes) == 1
    assert del_changes[0]["is_deleted"] is True
    assert del_changes[0]["operation"] == "delete"
