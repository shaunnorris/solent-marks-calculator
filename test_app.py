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

def test_course_marks_tagged_with_start_and_finish(client):
    """Test that the first mark is tagged as 'Start' and last mark as 'Finish' in course results"""
    # Create a course with 3 marks
    course_data = {
        'course': [
            {'name': '1A', 'rounding': 'S'},
            {'name': '2A', 'rounding': 'P'},
            {'name': '3A', 'rounding': 'S'}
        ]
    }
    
    response = client.post('/course', json=course_data)
    assert response.status_code == 200
    
    data = response.get_json()
    assert 'legs' in data
    legs = data['legs']
    
    # Should have 2 legs for 3 marks
    assert len(legs) == 2
    
    # First leg should have leg_number 1 and 'Start' tag on the 'from' mark
    assert legs[0]['leg_number'] == 1
    assert legs[0]['from']['name'] == '1A'
    assert legs[0]['from']['tag'] == 'Start'
    
    # Second leg should have leg_number 2 and 'Finish' tag on the 'to' mark
    assert legs[1]['leg_number'] == 2
    assert legs[1]['to']['name'] == '3A'
    assert legs[1]['to']['tag'] == 'Finish'
    
    # Middle marks should not have tags
    assert legs[0]['to']['tag'] is None
    assert legs[1]['from']['tag'] is None

def test_course_with_two_marks_both_tagged(client):
    """Test that with only 2 marks, first is 'Start' and second is 'Finish'"""
    course_data = {
        'course': [
            {'name': '1A', 'rounding': 'S'},
            {'name': '2A', 'rounding': 'P'}
        ]
    }
    
    response = client.post('/course', json=course_data)
    assert response.status_code == 200
    
    data = response.get_json()
    legs = data['legs']
    
    # Should have 1 leg for 2 marks
    assert len(legs) == 1
    
    # First leg should have leg_number 1
    assert legs[0]['leg_number'] == 1
    
    # First mark should be 'Start'
    assert legs[0]['from']['name'] == '1A'
    assert legs[0]['from']['tag'] == 'Start'
    
    # Second mark should be 'Finish'
    assert legs[0]['to']['name'] == '2A'
    assert legs[0]['to']['tag'] == 'Finish'

def test_frontend_includes_mark_tag_styling(client):
    """Test that the frontend HTML includes the mark tag styling"""
    response = client.get('/')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Check that the CSS classes for mark tags are present
    assert '.mark-tag' in html
    assert '.start-tag' in html
    assert '.finish-tag' in html
    
    # Check that the JavaScript includes tag handling
    assert 'leg.from.tag' in html
    assert 'leg.to.tag' in html
    assert 'start-tag' in html
    assert 'finish-tag' in html

def test_frontend_includes_comprehensive_tag_display(client):
    """Test that the frontend includes all necessary code for displaying tags in all locations"""
    response = client.get('/')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Check for course lozenge tag display
    assert 'index === 0' in html  # First mark logic
    assert 'courseMarks.length - 1' in html  # Last mark logic
    assert 'mark-tag start-tag' in html
    assert 'mark-tag finish-tag' in html
    
    # Check for table tag display
    assert 'leg.from.tag' in html
    assert 'leg.to.tag' in html
    
    # Check for map tag display
    assert 'mark.tag' in html
    assert 'tagColor' in html
    assert 'mark.tag === \'Start\'' in html
    assert 'mark-tag-icon' in html
    assert 'interactive: false' in html  # Tag markers are non-interactive
    assert 'connectingLine' in html  # Connecting lines between marks and tags
    
    # Check for blue color scheme
    assert '#3498db' in html  # Light blue for Start
    assert '#2980b9' in html  # Dark blue for Finish
    
    # Check for CSS styling
    assert '.course-lozenge .mark-tag' in html
    assert 'font-size: 0.6em' in html
    assert 'padding: 1px 4px' in html

def test_course_leg_table_tag_display(client):
    """Test that the course leg table properly displays tags with correct CSS classes"""
    response = client.get('/')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Check that the table rendering includes proper tag logic
    assert 'leg.from.tag === \'Start\'' in html
    assert 'leg.to.tag === \'Start\'' in html
    assert 'start-tag' in html
    assert 'finish-tag' in html
    
    # Check that the table uses the correct CSS classes
    assert 'mark-tag ${leg.from.tag === \'Start\'' in html
    assert 'mark-tag ${leg.to.tag === \'Start\'' in html

def test_map_preserves_port_starboard_colors(client):
    """Test that the map preserves port/starboard colors while adding separate blue tags"""
    response = client.get('/')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Check that port/starboard colors are preserved
    assert 'backgroundColor = mark.rounding === \'P\' ? \'#e74c3c\' : \'#27ae60\'' in html
    assert 'Red for Port, Green for Starboard' in html
    
    # Check that separate blue tag markers are added
    assert 'Add separate blue tag marker' in html
    assert 'mark-tag-icon' in html
    assert 'interactive: false' in html
    
    # Check that tag markers are positioned separately with connecting lines
    assert 'tagLat = mark.lat + 0.003' in html  # Start tags above
    assert 'tagLat = mark.lat - 0.003' in html  # Finish tags below
    assert 'connectingLine' in html
    assert 'dashArray' in html

def test_frontend_includes_leg_number_functionality(client):
    """Test that the frontend includes leg number functionality in table and map"""
    response = client.get('/')
    assert response.status_code == 200
    
    html = response.data.decode('utf-8')
    
    # Check that table includes leg number column
    assert '<th>Leg</th>' in html
    assert 'Leg ${leg.leg_number}' in html
    
    # Check that map includes leg labels with 3-line format
    assert 'leg-label' in html
    assert 'Leg ${leg.leg_number}' in html
    assert '${leg.from.name}→${leg.to.name}' in html
    assert '${leg.bearing}° ${leg.distance}nm' in html
    
    # Check that leg labels are positioned off the line with connecting lines
    assert 'courseBearingRad' in html
    assert 'offsetDistance' in html
    assert 'offsetLat' in html
    assert 'offsetLon' in html
    assert 'connectingLine' in html
    assert 'interactive: false' in html 

def test_frontend_handles_repeated_legs():
    """Test that repeated legs are handled correctly to avoid overlapping labels"""
    with app.test_client() as client:
        response = client.get('/')
        assert response.status_code == 200
        
        html = response.data.decode('utf-8')
        
        # Check that the repeated leg logic is included
        assert 'repeatedLegs' in html
        assert 'legOccurrence' in html
        assert 'isRepeated' in html
        
        # Check that the offset calculation logic is present
        assert 'offsetDistance = 0.0015 + (legOccurrence * 0.001)' in html
        
        # Verify the leg route comparison logic
        assert 'legRoute = `${leg.from.name}→${leg.to.name}`' in html
        assert 'legs.filter((l, i) =>' in html 

def test_frontend_handles_combined_start_finish_tags():
    """Test that Start/Finish tags are combined into a single label when both apply to the same mark"""
    with app.test_client() as client:
        response = client.get('/')
        assert response.status_code == 200
        
        html = response.data.decode('utf-8')
        
        # Check that the combined tag logic is included
        assert 'hasStartTag' in html
        assert 'hasFinishTag' in html
        assert 'Start/Finish' in html
        
        # Check that individual tag logic is still present
        assert 'tag === \'Start\'' in html
        assert 'else' in html  # Finish tags use else condition
        
        # Check that positioning logic is present
        assert 'tagLat = mark.lat + 0.003' in html  # Start tags above
        assert 'tagLat = mark.lat - 0.003' in html  # Finish tags below 

def test_table_shows_combined_start_finish_tags():
    """Test that the table shows combined Start/Finish tags when a mark has both tags"""
    with app.test_client() as client:
        response = client.get('/')
        assert response.status_code == 200
        
        html = response.data.decode('utf-8')
        
        # Check that the combined tag logic is included in table rendering
        assert 'start-finish-tag' in html
        assert 'Start/Finish' in html
        assert 'fromHasStartTag' in html
        assert 'fromHasFinishTag' in html
        assert 'toHasStartTag' in html
        assert 'toHasFinishTag' in html
        
        # Check that the CSS for combined tags is included
        assert '.start-finish-tag' in html 