import pytest
from app import app

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_lookup_has_collapsible_zone_section(client):
    """Test that lookup page has a collapsible zone filter section"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    # Should have a toggle button or link for zones
    assert 'toggleZones' in content or 'toggle-zones' in content

def test_lookup_zone_section_closed_by_default(client):
    """Test that zone section has CSS to be hidden by default"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    # Zone filter should have a class or ID that starts hidden
    assert 'zone-filter-collapsed' in content or 'zones-collapsed' in content or 'max-height: 0' in content

def test_lookup_has_compact_mobile_layout(client):
    """Test that lookup page has mobile-optimized CSS"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    # Should have mobile media query
    assert '@media' in content
    # Should have viewport meta tag for mobile
    assert 'viewport' in content.lower()

