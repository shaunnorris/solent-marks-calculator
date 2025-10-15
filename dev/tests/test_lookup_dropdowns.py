import pytest
from app import app, load_gpx_marks

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_lookup_dropdowns_show_all_marks_when_no_zones_selected(client):
    """Test that dropdowns show all marks when no zones are selected"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    
    # Get all marks
    marks = load_gpx_marks()
    
    # Check that at least some marks from different zones appear in the page
    # (They should be loaded by JavaScript, but the marks endpoint should work)
    marks_response = client.get('/marks')
    assert marks_response.status_code == 200
    marks_data = marks_response.json
    
    # When no zones specified, should return all marks
    assert len(marks_data['marks']) > 0
    assert len(marks_data['marks']) == len(marks)

def test_marks_endpoint_returns_all_marks_with_no_zones(client):
    """Test /marks endpoint returns all marks when zones parameter is empty"""
    response = client.get('/marks?zones=')
    assert response.status_code == 200
    data = response.json
    
    all_marks = load_gpx_marks()
    
    assert 'marks' in data
    assert len(data['marks']) == len(all_marks)

def test_marks_endpoint_returns_all_marks_with_no_parameter(client):
    """Test /marks endpoint returns all marks when no zones parameter provided"""
    response = client.get('/marks')
    assert response.status_code == 200
    data = response.json
    
    all_marks = load_gpx_marks()
    
    assert 'marks' in data
    assert len(data['marks']) == len(all_marks)

def test_lookup_page_has_marks_loading_script(client):
    """Test that lookup page includes JavaScript to load marks on page load"""
    response = client.get('/lookup')
    assert response.status_code == 200
    content = response.data.decode('utf-8')
    
    # Should have loadAllMarks function
    assert 'loadAllMarks' in content
    # Should call loadAllMarks on page load
    assert 'DOMContentLoaded' in content

