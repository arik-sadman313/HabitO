import uuid
from datetime import datetime, timezone
import pytest
from app.models.couple import Couple, CoupleMember

def create_couple_in_db(db, user_a_id: str, user_b_id: str) -> str:
    couple_id = str(uuid.uuid4())
    couple = Couple(id=uuid.UUID(couple_id))
    member_a = CoupleMember(couple_id=uuid.UUID(couple_id), user_id=uuid.UUID(user_a_id))
    member_b = CoupleMember(couple_id=uuid.UUID(couple_id), user_id=uuid.UUID(user_b_id))
    db.add(couple)
    db.add(member_a)
    db.add(member_b)
    db.commit()
    return couple_id

def test_shared_goal_push_and_pull(client, db):
    # Register two users in a couple
    client.post("/api/v1/auth/register", json={"email": "usera@example.com", "password": "password123", "display_name": "User A"})
    token_a = client.post("/api/v1/auth/login", json={"email": "usera@example.com", "password": "password123"}).json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}
    user_a_id = client.get("/api/v1/auth/me", headers=headers_a).json()["id"]

    client.post("/api/v1/auth/register", json={"email": "userb@example.com", "password": "password123", "display_name": "User B"})
    token_b = client.post("/api/v1/auth/login", json={"email": "userb@example.com", "password": "password123"}).json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}
    user_b_id = client.get("/api/v1/auth/me", headers=headers_b).json()["id"]

    couple_id = create_couple_in_db(db, user_a_id, user_b_id)
    goal_id = str(uuid.uuid4())
    now_iso = datetime.now(timezone.utc).isoformat()

    # User A pushes a SharedGoal for the couple
    push_payload = {
        "device_id": "device_usera",
        "operations": [
            {
                "entity_type": "shared_goal",
                "entity_id": goal_id,
                "scope_type": "couple",
                "scope_id": couple_id,
                "operation": "upsert",
                "changed_at": now_iso,
                "payload": {
                    "id": goal_id,
                    "couple_id": couple_id,
                    "title": "Buy a House",
                    "description": "Savings target for 2027",
                    "target": 50000.0,
                    "current_progress": 10000.0,
                    "unit": "USD",
                    "deadline": None,
                    "is_completed": False,
                    "created_at": now_iso,
                    "updated_at": now_iso,
                    "is_deleted": False
                },
                "is_deleted": False
            }
        ]
    }

    push_res = client.post("/api/v1/sync/push", json=push_payload, headers=headers_a)
    assert push_res.status_code == 200, f"Push failed: {push_res.status_code} {push_res.json()}"
    assert push_res.json()["changes_processed"] == 1

    # User B pulls changes and receives the SharedGoal
    pull_res = client.get("/api/v1/sync/pull?cursor=0", headers=headers_b)
    assert pull_res.status_code == 200
    data = pull_res.json()
    assert len(data["changes"]) == 1, f"Expected 1 change, got {len(data['changes'])}: {data}"

    change = data["changes"][0]
    assert change["entity_type"] == "shared_goal"
    assert change["entity_id"] == goal_id
    assert change["scope_type"] == "couple"
    assert change["scope_id"] == couple_id
    assert change["payload"]["title"] == "Buy a House"

def test_shared_data_security_and_non_member_rejection(client, db):
    # User A and B in Couple 1, User C in no couple
    client.post("/api/v1/auth/register", json={"email": "usera2@example.com", "password": "password123", "display_name": "User A2"})
    token_a = client.post("/api/v1/auth/login", json={"email": "usera2@example.com", "password": "password123"}).json()["access_token"]
    user_a_id = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token_a}"}).json()["id"]

    client.post("/api/v1/auth/register", json={"email": "userb2@example.com", "password": "password123", "display_name": "User B2"})
    token_b = client.post("/api/v1/auth/login", json={"email": "userb2@example.com", "password": "password123"}).json()["access_token"]
    user_b_id = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token_b}"}).json()["id"]

    client.post("/api/v1/auth/register", json={"email": "userc2@example.com", "password": "password123", "display_name": "User C2"})
    token_c = client.post("/api/v1/auth/login", json={"email": "userc2@example.com", "password": "password123"}).json()["access_token"]
    headers_c = {"Authorization": f"Bearer {token_c}"}

    couple_id = create_couple_in_db(db, user_a_id, user_b_id)
    goal_id = str(uuid.uuid4())
    now_iso = datetime.now(timezone.utc).isoformat()

    # User C (not in couple) attempts to push a SharedGoal for Couple 1 -> Expect HTTP 403
    forged_push = {
        "device_id": "device_userc",
        "operations": [
            {
                "entity_type": "shared_goal",
                "entity_id": goal_id,
                "scope_type": "couple",
                "scope_id": couple_id,
                "operation": "upsert",
                "changed_at": now_iso,
                "payload": {
                    "id": goal_id,
                    "couple_id": couple_id,
                    "title": "Forged Goal",
                    "target": 100.0,
                    "created_at": now_iso,
                    "updated_at": now_iso,
                    "is_deleted": False
                },
                "is_deleted": False
            }
        ]
    }

    res = client.post("/api/v1/sync/push", json=forged_push, headers=headers_c)
    assert res.status_code == 403

    # User C attempts to pull Couple 1 changes -> Returns 0 changes
    pull_c = client.get("/api/v1/sync/pull?cursor=0", headers=headers_c)
    assert pull_c.status_code == 200
    assert len(pull_c.json()["changes"]) == 0

def test_memory_and_shared_activity_sync(client, db):
    client.post("/api/v1/auth/register", json={"email": "usera3@example.com", "password": "password123", "display_name": "User A3"})
    token_a = client.post("/api/v1/auth/login", json={"email": "usera3@example.com", "password": "password123"}).json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}
    user_a_id = client.get("/api/v1/auth/me", headers=headers_a).json()["id"]

    client.post("/api/v1/auth/register", json={"email": "userb3@example.com", "password": "password123", "display_name": "User B3"})
    token_b = client.post("/api/v1/auth/login", json={"email": "userb3@example.com", "password": "password123"}).json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}
    user_b_id = client.get("/api/v1/auth/me", headers=headers_b).json()["id"]

    couple_id = create_couple_in_db(db, user_a_id, user_b_id)
    mem_id = str(uuid.uuid4())
    act_id = str(uuid.uuid4())
    now_iso = datetime.now(timezone.utc).isoformat()

    # User A pushes a Memory and a SharedActivity
    push_payload = {
        "device_id": "device_usera3",
        "operations": [
            {
                "entity_type": "memory",
                "entity_id": mem_id,
                "scope_type": "couple",
                "scope_id": couple_id,
                "operation": "upsert",
                "changed_at": now_iso,
                "payload": {
                    "id": mem_id,
                    "couple_id": couple_id,
                    "title": "First Beach Trip",
                    "description": "Sunset at Cox's Bazar",
                    "date": now_iso,
                    "media_url": None,
                    "tags": "vacation,beach",
                    "created_at": now_iso,
                    "updated_at": now_iso,
                    "is_deleted": False
                },
                "is_deleted": False
            },
            {
                "entity_type": "shared_activity",
                "entity_id": act_id,
                "scope_type": "couple",
                "scope_id": couple_id,
                "operation": "upsert",
                "changed_at": now_iso,
                "payload": {
                    "id": act_id,
                    "couple_id": couple_id,
                    "title": "Evening Walk",
                    "notes": "Park loop",
                    "start_time": now_iso,
                    "end_time": None,
                    "is_completed": True,
                    "created_at": now_iso,
                    "updated_at": now_iso,
                    "is_deleted": False
                },
                "is_deleted": False
            }
        ]
    }

    push_res = client.post("/api/v1/sync/push", json=push_payload, headers=headers_a)
    assert push_res.status_code == 200
    assert push_res.json()["changes_processed"] == 2

    # User B pulls both shared items
    pull_res = client.get("/api/v1/sync/pull?cursor=0", headers=headers_b)
    assert pull_res.status_code == 200
    changes = pull_res.json()["changes"]
    assert len(changes) == 2
    types = [c["entity_type"] for c in changes]
    assert "memory" in types
    assert "shared_activity" in types


