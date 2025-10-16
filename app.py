from flask import Flask, render_template, request, jsonify
import xml.etree.ElementTree as ET
import math

app = Flask(__name__)

def load_gpx_marks():
    """Load marks from the GPX file"""
    tree = ET.parse('2025scra.gpx')
    root = tree.getroot()
    
    # Define the namespace
    ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}
    
    marks = []
    for wpt in root.findall('.//gpx:wpt', ns):
        lat_str = wpt.get('lat')
        lon_str = wpt.get('lon')
        
        if lat_str is None or lon_str is None:
            continue
            
        lat = float(lat_str)
        lon = float(lon_str)
        
        name_elem = wpt.find('gpx:name', ns)
        desc_elem = wpt.find('gpx:desc', ns)
        sym_elem = wpt.find('gpx:sym', ns)
        
        name = name_elem.text.strip() if name_elem is not None and name_elem.text is not None else ''
        desc = desc_elem.text.strip() if desc_elem is not None and desc_elem.text is not None else ''
        symbol = sym_elem.text.strip() if sym_elem is not None and sym_elem.text is not None else ''
        
        marks.append({
            'name': name,
            'description': desc,
            'symbol': symbol,
            'lat': lat,
            'lon': lon
        })
    
    return marks

def get_available_zones(marks):
    """Get list of available zones (first character of mark names)"""
    zones = set()
    for mark in marks:
        if mark['name']:
            zones.add(mark['name'][0])
    return sorted(list(zones))

def get_marks_by_zone(marks, zones):
    """Filter marks by zone (first character of mark name)"""
    if not zones:
        return []
    
    filtered_marks = []
    for mark in marks:
        if mark['name'] and mark['name'][0] in zones:
            filtered_marks.append(mark)
    return filtered_marks

@app.route('/marks')
def get_marks():
    """Get marks filtered by zones"""
    zones_param = request.args.get('zones', '')
    zones = [z.strip() for z in zones_param.split(',') if z.strip()]
    
    all_marks = load_gpx_marks()
    available_zones = get_available_zones(all_marks)
    
    if zones:
        filtered_marks = get_marks_by_zone(all_marks, zones)
    else:
        filtered_marks = all_marks  # Return all marks when no zones specified
    
    return jsonify({
        'marks': filtered_marks,
        'zones': available_zones
    })

@app.route('/')
def index():
    """Redirect to lookup page (new homepage)"""
    from flask import redirect, url_for
    return redirect(url_for('lookup'))

@app.route('/course')
def course_page():
    """Course calculator page (old homepage)"""
    marks = load_gpx_marks()
    zones = get_available_zones(marks)
    return render_template('index.html', marks=marks, zones=zones)

@app.route('/lookup')
def lookup():
    """Lookup page - simple bearing and distance calculator"""
    marks = load_gpx_marks()
    zones = get_available_zones(marks)
    return render_template('lookup.html', marks=marks, zones=zones)



@app.route('/lookup/calculate', methods=['POST'])
def lookup_calculate():
    """Calculate bearing and distance for lookup page"""
    data = request.get_json()
    from_mark_name = data.get('from_mark')
    to_mark_name = data.get('to_mark')
    
    if not from_mark_name or not to_mark_name:
        return jsonify({'error': 'Both from_mark and to_mark are required'}), 400
    
    marks = load_gpx_marks()
    
    # Find the selected marks
    from_mark = next((m for m in marks if m['name'] == from_mark_name), None)
    to_mark = next((m for m in marks if m['name'] == to_mark_name), None)
    
    if not from_mark or not to_mark:
        return jsonify({'error': 'One or both marks not found'}), 400
    
    # Calculate bearing and distance
    bearing = calculate_bearing(from_mark, to_mark)
    distance = calculate_distance(from_mark, to_mark)
    
    return jsonify({
        'bearing': bearing,
        'distance': distance
    })

@app.route('/calculate', methods=['POST'])
def calculate():
    """Calculate bearing and distance between two marks"""
    data = request.get_json()
    mark1_name = data.get('mark1')
    mark2_name = data.get('mark2')
    
    marks = load_gpx_marks()
    
    # Find the selected marks
    mark1 = next((m for m in marks if m['name'] == mark1_name), None)
    mark2 = next((m for m in marks if m['name'] == mark2_name), None)
    
    if not mark1 or not mark2:
        return jsonify({'error': 'One or both marks not found'}), 400
    
    # Calculate bearing and distance
    bearing = calculate_bearing(mark1, mark2)
    distance = calculate_distance(mark1, mark2)
    
    return jsonify({
        'bearing': bearing,
        'distance': distance,
        'mark1': mark1,
        'mark2': mark2
    })

@app.route('/course', methods=['POST'])
def course():
    """Calculate bearings and distances for a sequence of marks (race course)"""
    data = request.get_json()
    course_data = data.get('course', [])  # Changed from 'marks' to 'course' to include rounding info
    if not course_data or not isinstance(course_data, list) or len(course_data) < 2:
        return jsonify({'error': 'At least two marks must be provided'}), 400

    marks = load_gpx_marks()
    name_to_mark = {m['name']: m for m in marks}
    
    try:
        # Extract mark names and rounding directions
        course_marks = []
        for item in course_data:
            if isinstance(item, dict):
                mark_name = item.get('name')
                rounding = item.get('rounding', 'S')  # Default to Starboard if not specified
            else:
                # Backward compatibility: if item is just a string, treat as mark name with default rounding
                mark_name = item
                rounding = 'S'
            
            if mark_name not in name_to_mark:
                return jsonify({'error': f'Mark {mark_name} not found'}), 400
            
            mark = name_to_mark[mark_name].copy()
            mark['rounding'] = rounding
            course_marks.append(mark)
    except Exception as e:
        return jsonify({'error': f'Invalid course data: {str(e)}'}), 400

    legs = []
    for i in range(len(course_marks) - 1):
        m1 = course_marks[i]
        m2 = course_marks[i+1]
        
        # Determine tags for marks
        from_tag = 'Start' if i == 0 else None
        to_tag = 'Finish' if i == len(course_marks) - 2 else None
        
        legs.append({
            'leg_number': i + 1,
            'from': {
                'name': m1['name'], 
                'description': m1['description'],
                'symbol': m1['symbol'],
                'rounding': m1['rounding'],
                'tag': from_tag
            },
            'to': {
                'name': m2['name'], 
                'description': m2['description'],
                'symbol': m2['symbol'],
                'rounding': m2['rounding'],
                'tag': to_tag
            },
            'bearing': calculate_bearing(m1, m2),
            'distance': calculate_distance(m1, m2)
        })
    return jsonify({'legs': legs})

def calculate_bearing(mark1, mark2):
    """Calculate compass bearing from mark1 to mark2 in degrees"""
    lat1 = math.radians(mark1['lat'])
    lon1 = math.radians(mark1['lon'])
    lat2 = math.radians(mark2['lat'])
    lon2 = math.radians(mark2['lon'])
    
    d_lon = lon2 - lon1
    
    y = math.sin(d_lon) * math.cos(lat2)
    x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(d_lon)
    
    bearing = math.degrees(math.atan2(y, x))
    
    # Convert to compass bearing (0-360 degrees)
    bearing = (bearing + 360) % 360
    
    return round(bearing)

def calculate_distance(mark1, mark2):
    """Calculate distance between two marks in nautical miles"""
    lat1 = math.radians(mark1['lat'])
    lon1 = math.radians(mark1['lon'])
    lat2 = math.radians(mark2['lat'])
    lon2 = math.radians(mark2['lon'])
    
    # Haversine formula
    d_lat = lat2 - lat1
    d_lon = lon2 - lon1
    
    a = math.sin(d_lat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(d_lon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    # Earth's radius in nautical miles
    r = 3440.065  # nautical miles
    
    distance = r * c
    
    return round(distance, 2)

if __name__ == '__main__':
    app.run(debug=True) 