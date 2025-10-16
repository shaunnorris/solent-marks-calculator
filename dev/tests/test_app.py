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
    """Test the main page redirects to /lookup"""
    response = client.get('/', follow_redirects=False)
    assert response.status_code == 302
    assert response.location.endswith('/lookup')

def test_calculate_route_success(client):
    """Test successful calculation request"""
    # First get the course page to load marks
    response = client.get('/course')
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

def test_course_route_success(client):
    """Test course calculation for a sequence of marks"""
    marks = load_gpx_marks()
    if len(marks) >= 3:
        mark_names = [marks[0]['name'], marks[1]['name'], marks[2]['name']]
        response = client.post('/course', json={'course': mark_names})
        assert response.status_code == 200
        data = response.get_json()
        assert 'legs' in data
        assert len(data['legs']) == 2  # n marks = n-1 legs
        for leg in data['legs']:
            assert 'from' in leg
            assert 'to' in leg
            assert 'bearing' in leg
            assert 'distance' in leg
            assert isinstance(leg['bearing'], (int, float))
            assert isinstance(leg['distance'], (int, float))

def test_course_route_invalid_marks(client):
    """Test course calculation with invalid mark names"""
    response = client.post('/course', json={'marks': ['Invalid1', 'Invalid2']})
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data

def test_course_route_too_few_marks(client):
    """Test course calculation with less than two marks"""
    marks = load_gpx_marks()
    if marks:
        response = client.post('/course', json={'marks': [marks[0]['name']]})
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data 

def test_get_marks_by_zone():
    """Test filtering marks by zone (first character of mark name)"""
    from app import get_marks_by_zone, load_gpx_marks
    
    all_marks = load_gpx_marks()
    
    # Test zone 1
    zone1_marks = get_marks_by_zone(all_marks, ['1'])
    assert len(zone1_marks) > 0
    for mark in zone1_marks:
        assert mark['name'].startswith('1')
    
    # Test multiple zones
    zone_1_2_marks = get_marks_by_zone(all_marks, ['1', '2'])
    assert len(zone_1_2_marks) > 0
    for mark in zone_1_2_marks:
        assert mark['name'].startswith('1') or mark['name'].startswith('2')
    
    # Test empty zones
    empty_marks = get_marks_by_zone(all_marks, [])
    assert len(empty_marks) == 0
    
    # Test invalid zones
    invalid_marks = get_marks_by_zone(all_marks, ['X'])
    assert len(invalid_marks) == 0

def test_get_available_zones():
    """Test getting list of available zones from marks"""
    from app import get_available_zones, load_gpx_marks
    
    all_marks = load_gpx_marks()
    zones = get_available_zones(all_marks)
    
    assert len(zones) > 0
    assert all(isinstance(zone, str) for zone in zones)
    assert all(len(zone) == 1 for zone in zones)  # Single character zones

def test_marks_endpoint(client):
    """Test the /marks endpoint that returns marks filtered by zones"""
    response = client.get('/marks?zones=1,2')
    assert response.status_code == 200
    data = response.get_json()
    
    assert 'marks' in data
    assert 'zones' in data
    assert isinstance(data['marks'], list)
    assert isinstance(data['zones'], list)
    
    # All returned marks should be from zones 1 or 2
    for mark in data['marks']:
        assert mark['name'].startswith('1') or mark['name'].startswith('2')

def test_marks_endpoint_no_zones(client):
    """Test the /marks endpoint with no zones specified"""
    response = client.get('/marks')
    assert response.status_code == 200
    data = response.get_json()
    
    assert 'marks' in data
    assert 'zones' in data
    # Now expect marks to be present when no zones are specified
    assert len(data['marks']) > 0 