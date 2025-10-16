"""
Test map overlay functionality to ensure bearing and distance are displayed correctly.
"""

import pytest
from app import app


@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


class TestMapOverlay:
    """Test map overlay displays bearing and distance correctly."""
    
    def test_lookup_page_has_map_overlay_elements(self, client):
        """Test that the lookup page includes map overlay functionality."""
        response = client.get('/lookup')
        assert response.status_code == 200
        
        # Check for map overlay JavaScript functionality
        content = response.get_data(as_text=True)
        
        # Should have drawRoute function that accepts distance parameter
        assert 'function drawRoute(fromMarkData, toMarkData, bearing, distance)' in content
        
        # Should have overlay creation with distance variable
        assert 'overlayIcon' in content
        assert '${distance}nm' in content
        
        # Should call drawRoute with distance parameter
        assert 'drawRoute(fromMarkData, toMarkData, data.bearing, data.distance)' in content
    
    def test_calculate_endpoint_returns_distance(self, client):
        """Test that the calculate endpoint returns distance in response."""
        # Test with valid marks
        response = client.post('/lookup/calculate',
                             json={'from_mark': '2A', 'to_mark': '2B'},
                             content_type='application/json')
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Should have both bearing and distance
        assert 'bearing' in data
        assert 'distance' in data
        assert isinstance(data['bearing'], (int, float))
        assert isinstance(data['distance'], (int, float))
        assert data['distance'] > 0  # Distance should be positive
    
    def test_map_overlay_error_handling(self, client):
        """Test that map overlay handles missing distance gracefully."""
        response = client.get('/lookup')
        content = response.get_data(as_text=True)
        
        # Should have error handling in JavaScript
        assert 'console.error' in content
        assert 'console.log' in content
        
        # Should have proper parameter validation
        assert 'if (fromMarkData && toMarkData)' in content
