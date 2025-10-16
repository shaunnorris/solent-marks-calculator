"""
Tests for mark color mapping from GPX symbol field
"""
import pytest
from app import app, load_gpx_marks


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_marks_have_symbol_field():
    """Test that marks loaded from GPX have symbol field"""
    marks = load_gpx_marks()
    assert len(marks) > 0
    
    # Check that marks have symbol field
    for mark in marks:
        assert 'symbol' in mark


def test_lookup_page_includes_color_mapping_function(client):
    """Test that lookup page includes JavaScript color mapping function"""
    response = client.get('/lookup')
    assert response.status_code == 200
    
    # Check for color mapping function
    assert b'getMarkerColor' in response.data or b'symbolToColor' in response.data


def test_lookup_page_color_maps_single_colors(client):
    """Test that lookup page maps single color codes"""
    response = client.get('/lookup')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Check for basic color mappings
    assert "'R'" in html or '"R"' in html  # Red mapping
    assert "'G'" in html or '"G"' in html  # Green mapping
    assert "'Y'" in html or '"Y"' in html  # Yellow mapping


def test_lookup_page_color_maps_striped_colors(client):
    """Test that lookup page handles striped/multicolor codes"""
    response = client.get('/lookup')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Check for striped color patterns
    assert 'YBY' in html or 'striped' in html.lower()
    assert 'BYB' in html or 'gradient' in html.lower()


def test_marks_api_includes_symbol(client):
    """Test that /marks API endpoint includes symbol field"""
    response = client.get('/marks')
    assert response.status_code == 200
    
    data = response.get_json()
    marks = data['marks']
    
    assert len(marks) > 0
    for mark in marks:
        assert 'symbol' in mark
        assert mark['symbol'] is not None or mark['symbol'] == ''

