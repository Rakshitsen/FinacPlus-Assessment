def test_health_ok(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}

def test_root_text(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"Hello from Flask" in resp.data
