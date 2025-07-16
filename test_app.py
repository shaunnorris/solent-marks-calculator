import pytest
import math
from app import app, load_gpx_marks, calculate_bearing, calculate_distance

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_load_gpx_marks():
    """Test that GPX marks are loaded correctly"""
    marks = load_gpx_marks()
    
    # Should have loaded marks
    assert len(marks) > 0
    
    # Each mark should have required fields
    for mark in marks:
        assert 'name' in mark
        assert 'description' in mark
        assert 'lat' in mark
        assert 'lon' in mark
        assert isinstance(mark['lat'], float)
        assert isinstance(mark['lon'], float)
        assert isinstance(mark['name'], str)
        assert isinstance(mark['description'], str)

def test_calculate_bearing():
    """Test bearing calculation between two points"""
    # Test case: North to South (should be 180 degrees)
    mark1 = {'lat': 50.0, 'lon': -1.0}
    mark2 = {'lat': 49.0, 'lon': -1.0}  # South of mark1
    
    bearing = calculate_bearing(mark1, mark2)
    assert abs(bearing - 180.0) < 1.0  # Allow small tolerance
    
    # Test case: East to West (should be 270 degrees)
    mark1 = {'lat': 50.0, 'lon': -1.0}
    mark2 = {'lat': 50.0, 'lon': -2.0}  # West of mark1
    
    bearing = calculate_bearing(mark1, mark2)
    assert abs(bearing - 270.0) < 1.0  # Allow small tolerance

def test_calculate_distance():
    """Test distance calculation between two points"""
    # Test case: Same point should have zero distance
    mark1 = {'lat': 50.0, 'lon': -1.0}
    mark2 = {'lat': 50.0, 'lon': -1.0}
    
    distance = calculate_distance(mark1, mark2)
    assert distance == 0.0
    
    # Test case: Known distance (approximately)
    # 1 degree of latitude ≈ 60 nautical miles
    mark1 = {'lat': 50.0, 'lon': -1.0}
    mark2 = {'lat': 51.0, 'lon': -1.0}  # 1 degree north
    
    distance = calculate_distance(mark1, mark2)
    assert 55.0 < distance < 65.0  # Should be approximately 60 nautical miles

def test_index_route(client):
    """Test the main page loads correctly"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'GPX Mark Calculator' in response.data

def test_calculate_route_success(client):
    """Test successful calculation request"""
    # First get the page to load marks
    response = client.get('/')
    assert response.status_code == 200
    
    # Get some marks to test with
    marks = load_gpx_marks()
    if len(marks) >= 2:
        mark1_name = marks[0]['name']
        mark2_name = marks[1]['name']
        
        response = client.post('/calculate', 
                             json={'mark1': mark1_name, 'mark2': mark2_name})
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert 'bearing' in data
        assert 'distance' in data
        assert 'mark1' in data
        assert 'mark2' in data
        assert isinstance(data['bearing'], (int, float))
        assert isinstance(data['distance'], (int, float))

def test_calculate_route_invalid_marks(client):
    """Test calculation with invalid mark names"""
    response = client.post('/calculate', 
                         json={'mark1': 'InvalidMark1', 'mark2': 'InvalidMark2'})
    
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data

def test_calculate_route_missing_data(client):
    """Test calculation with missing data"""
    response = client.post('/calculate', json={})
    
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data 