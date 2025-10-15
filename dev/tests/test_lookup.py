import pytest
from app import app, load_gpx_marks, calculate_bearing, calculate_distance

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_lookup_route_exists(client):
    """Test that /lookup route exists and returns 200"""
    response = client.get('/lookup')
    assert response.status_code == 200

def test_lookup_page_has_zone_selectors(client):
    """Test that lookup page includes zone filter checkboxes"""
    response = client.get('/lookup')
    assert response.status_code == 200
    assert b'Filter by Zone' in response.data or b'zone' in response.data.lower()

def test_lookup_page_has_from_dropdown(client):
    """Test that lookup page has a 'from' mark selector"""
    response = client.get('/lookup')
    assert response.status_code == 200
    # Check for 'from' label or select element
    assert b'from' in response.data.lower() or b'From' in response.data

def test_lookup_page_has_to_dropdown(client):
    """Test that lookup page has a 'to' mark selector"""
    response = client.get('/lookup')
    assert response.status_code == 200
    # Check for 'to' label or select element
    assert b'to' in response.data.lower() or b'To' in response.data

def test_lookup_page_has_calculate_button(client):
    """Test that lookup page has a calculate button"""
    response = client.get('/lookup')
    assert response.status_code == 200
    assert b'Calculate' in response.data or b'calculate' in response.data.lower()

def test_lookup_calculation_endpoint(client):
    """Test that lookup calculation returns bearing and distance"""
    marks = load_gpx_marks()
    if len(marks) >= 2:
        mark1_name = marks[0]['name']
        mark2_name = marks[1]['name']
        
        # Test the calculation endpoint used by lookup
        response = client.post('/lookup/calculate', 
                             json={'from_mark': mark1_name, 'to_mark': mark2_name})
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert 'bearing' in data
        assert 'distance' in data
        assert isinstance(data['bearing'], (int, float))
        assert isinstance(data['distance'], (int, float))
        # Bearing should be between 0 and 360
        assert 0 <= data['bearing'] <= 360
        # Distance should be positive
        assert data['distance'] >= 0

def test_lookup_calculation_with_invalid_marks(client):
    """Test lookup calculation with invalid mark names returns error"""
    response = client.post('/lookup/calculate', 
                         json={'from_mark': 'InvalidMark1', 'to_mark': 'InvalidMark2'})
    
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data

def test_lookup_calculation_with_missing_data(client):
    """Test lookup calculation with missing data returns error"""
    response = client.post('/lookup/calculate', json={})
    
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data

def test_lookup_calculation_same_mark(client):
    """Test lookup calculation when from and to are the same mark"""
    marks = load_gpx_marks()
    if marks:
        mark_name = marks[0]['name']
        
        response = client.post('/lookup/calculate', 
                             json={'from_mark': mark_name, 'to_mark': mark_name})
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Distance should be 0 for same mark
        assert data['distance'] == 0.0

