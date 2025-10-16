"""
Tests for /lookup as homepage functionality
"""
import pytest
from app import app


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_root_redirects_to_lookup(client):
    """Test that / redirects to /lookup"""
    response = client.get('/', follow_redirects=False)
    assert response.status_code == 302
    assert response.location.endswith('/lookup')


def test_root_redirect_works(client):
    """Test that following the redirect works"""
    response = client.get('/', follow_redirects=True)
    assert response.status_code == 200
    assert b'Mark Lookup Calculator' in response.data


def test_lookup_has_map_container(client):
    """Test that /lookup page has a map container"""
    response = client.get('/lookup')
    assert response.status_code == 200
    assert b'id="map"' in response.data


def test_lookup_includes_leaflet_library(client):
    """Test that Leaflet library is included"""
    response = client.get('/lookup')
    assert response.status_code == 200
    assert b'leaflet' in response.data.lower()


def test_lookup_has_map_javascript(client):
    """Test that map initialization JavaScript is present"""
    response = client.get('/lookup')
    assert response.status_code == 200
    # Check for map initialization
    assert b'L.map' in response.data or b'initMap' in response.data


def test_old_index_still_accessible(client):
    """Test that old index is still accessible at /course"""
    response = client.get('/course')
    assert response.status_code == 200
    assert b'Course Calculator' in response.data or b'2025 Solent Racing Marks' in response.data

