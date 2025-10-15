import pytest
from app import app

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_lookup_initializes_with_zone2_selected(client):
    """Test that lookup page JavaScript initializes with Zone 2 selected"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    
    # Should have JavaScript that selects zone 2 by default
    # Look for code that checks zone 2 checkbox
    assert 'value === \'2\'' in content or 'cb.value === \'2\'' in content

def test_lookup_has_compact_header(client):
    """Test that lookup page has a compact header without back link"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    
    # Should NOT have "Back to Course Builder" link
    assert 'Back to' not in content and 'back to' not in content.lower()

