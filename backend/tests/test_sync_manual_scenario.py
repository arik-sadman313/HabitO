from datetime import datetime
import uuid

def test_two_devices_and_user_isolation(client):
    # Register User A
    client.post("/api/v1/auth/register", json={
        "email": "userA@example.com",
        "password": "password123",
        "display_name": "User A"
    })
    
    # Register User B
    client.post("/api/v1/auth/register", json={
        "email": "userB@example.com",
        "password": "password123",
        "display_name": "User B"
    })

    # Login User A Device A
    login_A = client.post("/api/v1/auth/login", json={
        "email": "userA@example.com",
        "password": "password123"
    })
    token_A = login_A.json()["access_token"]
    headers_A = {"Authorization": f"Bearer {token_A}"}
    user_A_id = client.get("/api/v1/auth/me", headers=headers_A).json()["id"]

    # Login User B
    login_B = client.post("/api/v1/auth/login", json={
        "email": "userB@example.com",
        "password": "password123"
    })
    token_B = login_B.json()["access_token"]
    headers_B = {"Authorization": f"Bearer {token_B}"}
    user_B_id = client.get("/api/v1/auth/me", headers=headers_B).json()["id"]

    habit_id = str(uuid.uuid4())
    tracker_id = str(uuid.uuid4())

    # --- DEVICE A ---
    # Create Habit A and Sync (Device A)
    device_A_id = "device_A"
    push_A_resp = client.post("/api/v1/sync/push", headers=headers_A, json={
        "device_id": device_A_id,
        "operations": [{
            "entity_type": "tracker",
            "entity_id": tracker_id,
            "scope_type": "user",
            "scope_id": user_A_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": tracker_id,
                "user_id": user_A_id,
                "name": "Tracker A",
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
            "scope_id": user_A_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": habit_id,
                "user_id": user_A_id,
                "tracker_id": tracker_id,
                "title": "Habit A",
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
    assert push_A_resp.status_code == 200

    # --- DEVICE B ---
    # Pull Habit A (Device B)
    device_B_id = "device_B"
    pull_B_resp = client.get("/api/v1/sync/pull?cursor=0", headers=headers_A)
    assert pull_B_resp.status_code == 200
    data_B = pull_B_resp.json()
    
    assert len(data_B["changes"]) == 2
    # Verify the habit title is Habit A
    habit_change = next(c for c in data_B["changes"] if c["entity_type"] == "habit")
    assert habit_change["payload"]["title"] == "Habit A"
    cursor_B = data_B["cursor"]

    # Edit Habit A and Sync (Device B)
    push_B_resp = client.post("/api/v1/sync/push", headers=headers_A, json={
        "device_id": device_B_id,
        "operations": [{
            "entity_type": "habit",
            "entity_id": habit_id,
            "scope_type": "user",
            "scope_id": user_A_id,
            "operation": "upsert",
            "changed_at": datetime.utcnow().isoformat(),
            "payload": {
                "id": habit_id,
                "user_id": user_A_id,
                "tracker_id": tracker_id,
                "title": "Habit A Updated",
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
    assert push_B_resp.status_code == 200

    # --- DEVICE A ---
    # Pull updated Habit A (Device A)
    # Cursor should be from the first pull
    pull_A_resp = client.get(f"/api/v1/sync/pull?cursor={cursor_B}", headers=headers_A)
    assert pull_A_resp.status_code == 200
    data_A = pull_A_resp.json()
    assert len(data_A["changes"]) == 1
    assert data_A["changes"][0]["payload"]["title"] == "Habit A Updated"

    # --- USER B ---
    # User B cannot see Habit A
    pull_User_B = client.get("/api/v1/sync/pull?cursor=0", headers=headers_B)
    assert pull_User_B.status_code == 200
    assert len(pull_User_B.json()["changes"]) == 0
