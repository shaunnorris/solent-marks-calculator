import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_calculate_button_positioned_right_of_course_list(client):
    """Test that the Calculate button is positioned to the right of the course list display"""
    response = client.get('/')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Look for the course list and Calculate button
    assert 'id="courseList"' in html
    assert 'Calculate Course Legs' in html
    
    # The Calculate button should be positioned after the course list in the same section
    course_list_index = html.find('id="courseList"')
    calculate_index = html.find('Calculate Course Legs')
    assert course_list_index < calculate_index, "Calculate button should come after course list"

def test_clear_button_at_bottom_of_page(client):
    """Test that the Clear Course button is positioned at the bottom of the page"""
    response = client.get('/')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Look for the Clear Course button
    assert 'Clear Course' in html
    
    # The Clear Course button should be after the calculation results
    clear_index = html.find('Clear Course')
    results_index = html.find('id="courseResult"')
    
    # If results section exists, Clear button should be after it
    if results_index != -1:
        assert clear_index > results_index, "Clear Course button should be after results section" 