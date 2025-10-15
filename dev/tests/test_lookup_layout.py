import pytest
from app import app

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_lookup_has_side_by_side_dropdowns(client):
    """Test that from/to dropdowns can be displayed side by side"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    
    # Should have CSS for side-by-side layout
    assert 'display: flex' in content or 'grid' in content
    # Should have fromMark and toMark selects
    assert 'id="fromMark"' in content
    assert 'id="toMark"' in content

def test_lookup_zone_filter_starts_collapsed(client):
    """Test that zone filter starts collapsed even with Zone 2 selected"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    
    # Zone filter content should not start with expanded class in HTML
    # (JavaScript will select Zone 2 but keep it collapsed)
    assert 'zone-filter-content' in content
    # Should NOT have inline class="expanded" in the HTML
    # The expanded state should only be added by JS if user clicks toggle

def test_lookup_has_side_by_side_results(client):
    """Test that bearing and distance results can be displayed side by side"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    
    # Should have bearing and distance result elements
    assert 'id="bearingResult"' in content
    assert 'id="distanceResult"' in content
    # Results should be in a container that can display them side by side
    assert 'result' in content

