import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timedelta
from app.models.couple import Couple, CoupleMember
from app.models.user import User

import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timedelta
from app.models.couple import Couple, CoupleMember
from app.models.user import User

def register_and_login(client, email, display_name):
    client.post("/api/v1/auth/register", json={"email": email, "password": "password123", "display_name": display_name})
    token = client.post("/api/v1/auth/login", json={"email": email, "password": "password123"}).json()["access_token"]
    user_id = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"}).json()["id"]
    return token, user_id

def test_create_couple(client, db):
    token, user_id = register_and_login(client, "test1@example.com", "Test User 1")
    headers = {"Authorization": f"Bearer {token}"}
    
    response = client.post("/api/v1/couples/", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "active"
    
    couple_id = data["id"]
    
    member = db.query(CoupleMember).filter_by(user_id=user_id).first()
    assert member is not None
    assert str(member.couple_id) == couple_id
    assert member.role == "admin"
    
    response = client.post("/api/v1/couples/", headers=headers)
    assert response.status_code == 400

def test_generate_invite(client, db):
    token, user_id = register_and_login(client, "test2@example.com", "Test User 2")
    headers = {"Authorization": f"Bearer {token}"}
    client.post("/api/v1/couples/", headers=headers)
    
    response = client.post("/api/v1/couples/invite", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "invite_code" in data
    assert len(data["invite_code"]) == 6
    assert "expires_at" in data

def test_join_couple(client, db):
    token1, user_id1 = register_and_login(client, "test3@example.com", "Test User 3")
    headers1 = {"Authorization": f"Bearer {token1}"}
    
    client.post("/api/v1/couples/", headers=headers1)
    res_invite = client.post("/api/v1/couples/invite", headers=headers1)
    invite_code = res_invite.json()["invite_code"]
    
    token2, user_id2 = register_and_login(client, "test4@example.com", "Test User 4")
    headers2 = {"Authorization": f"Bearer {token2}"}
    
    res_join = client.post("/api/v1/couples/join", json={"invite_code": invite_code}, headers=headers2)
    assert res_join.status_code == 200
    
    members = db.query(CoupleMember).filter_by(user_id=user_id2).all()
    assert len(members) == 1
    
    token3, user_id3 = register_and_login(client, "test5@example.com", "Test User 5")
    headers3 = {"Authorization": f"Bearer {token3}"}
    
    res_join3 = client.post("/api/v1/couples/join", json={"invite_code": invite_code}, headers=headers3)
    assert res_join3.status_code == 404

def test_leave_couple(client, db):
    token, user_id = register_and_login(client, "test6@example.com", "Test User 6")
    headers = {"Authorization": f"Bearer {token}"}
    client.post("/api/v1/couples/", headers=headers)
    
    res_me = client.get("/api/v1/couples/me", headers=headers)
    assert res_me.json()["couple"] is not None
    
    res_leave = client.delete("/api/v1/couples/leave", headers=headers)
    assert res_leave.status_code == 200
    
    res_me2 = client.get("/api/v1/couples/me", headers=headers)
    assert res_me2.json()["couple"] is None
