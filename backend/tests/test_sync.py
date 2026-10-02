from datetime import datetime
import uuid

def test_sync_push_pull(client):
    client.post("/api/v1/auth/register", json={
        "email": "test@example.com",
        "password": "password123",
        "display_name": "Test User"
    })
    login_resp = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]
    
    habit_id = str(uuid.uuid4())
    tracker_id = str(uuid.uuid4())

    # Push
    push_resp = client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "test_device_1",
        "operations": [{
            "entity_type": "tracker",
            "entity_id": tracker_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": tracker_id,
                "user_id": user_id,
                "name": "Test Tracker",
                "icon": "icon",
                "color": "blue",
                "type": "boolean",
                "is_shared": False,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }, {
            "entity_type": "habit",
            "entity_id": habit_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": habit_id,
                "user_id": user_id,
                "tracker_id": tracker_id,
                "title": "Test Habit",
                "frequency": "daily",
                "target_value": 1.0,
                "start_date": datetime.utcnow().isoformat(),
                "is_shared": False,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    assert push_resp.status_code == 200
    assert push_resp.json()["changes_processed"] == 2
    
    # Pull
    pull_resp = client.get("/api/v1/sync/pull?cursor=0", headers=headers)
    assert pull_resp.status_code == 200
    data = pull_resp.json()
    assert len(data["changes"]) == 2
    assert data["changes"][0]["entity_id"] == tracker_id
    assert data["changes"][1]["entity_id"] == habit_id
    assert data["cursor"] > 0

def test_sync_phase15(client):
    login_resp = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = client.get("/api/v1/auth/me", headers=headers).json()["id"]

    subject_id = str(uuid.uuid4())
    meal_id = str(uuid.uuid4())
    meal_item_id = str(uuid.uuid4())

    push_resp = client.post("/api/v1/sync/push", headers=headers, json={
        "device_id": "test_device_2",
        "operations": [{
            "entity_type": "study_subject",
            "entity_id": subject_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": subject_id,
                "user_id": user_id,
                "name": "Math",
                "icon": "icon",
                "color": "blue",
                "is_active": True,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }, {
            "entity_type": "meal",
            "entity_id": meal_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": meal_id,
                "user_id": user_id,
                "meal_type": "lunch",
                "recorded_at": datetime.utcnow().isoformat(),
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }, {
            "entity_type": "meal_item",
            "entity_id": meal_item_id,
            "scope_type": "user",
            "scope_id": user_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": meal_item_id,
                "meal_id": meal_id,
                "name": "Apple",
                "quantity": 1.0,
                "unit": "piece",
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "is_deleted": False
            }
        }]
    })
    
    assert push_resp.status_code == 200
    assert push_resp.json()["changes_processed"] == 3
