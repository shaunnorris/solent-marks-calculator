#!/usr/bin/env python3
"""
Script to parse Lym Inshore Marks.txt and add missing marks to 2025scra.gpx
"""

import re
import xml.etree.ElementTree as ET
from typing import List, Dict, Tuple

def parse_coordinates(coord_str: str) -> float | None:
    """Convert degrees.minutes format to decimal degrees"""
    # Remove any extra spaces and split
    parts = coord_str.strip().split()
    if len(parts) == 1:
        # Format like "50.41.50" or "50 41.50"
        coord = parts[0].replace(' ', '')
        if '.' in coord:
            parts = coord.split('.')
            if len(parts) == 3:
                degrees = float(parts[0])
                minutes = float(parts[1] + '.' + parts[2])
                return degrees + (minutes / 60.0)
            elif len(parts) == 2:
                # Handle cases like "50.41" (degrees.minutes)
                degrees = float(parts[0])
                minutes = float(parts[1])
                return degrees + (minutes / 60.0)
    return None

def parse_text_marks(filename: str) -> List[Dict]:
    """Parse the text file and extract mark information"""
    marks = []
    
    with open(filename, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
                
            # Skip header lines or empty lines
            if line.startswith('#') or not line:
                continue
                
            # Parse line format: "1E Christchurch Ledge 50.41.50 01.41.60 Yellow sphere"
            # or "2HE East Fairway Bouy 50 42.64 01 29.88 Red can"
            
            # Try to match the pattern
            # Mark name can be alphanumeric + special characters
            pattern = r'^([A-Z0-9#♠🌰π+@V]+)\s+(.+?)\s+([0-9\s\.]+)\s+([0-9\s\.]+)\s+(.+)$'
            match = re.match(pattern, line)
            
            if match:
                mark_id = match.group(1).strip()
                description = match.group(2).strip()
                lat_str = match.group(3).strip()
                lon_str = match.group(4).strip()
                symbol_desc = match.group(5).strip()
                
                # Parse coordinates
                lat = parse_coordinates(lat_str)
                lon = parse_coordinates(lon_str)
                
                if lat is not None and lon is not None:
                    # Convert longitude to negative (Western hemisphere)
                    if lon > 0:
                        lon = -lon
                    
                    marks.append({
                        'id': mark_id,
                        'description': description,
                        'lat': lat,
                        'lon': lon,
                        'symbol_desc': symbol_desc,
                        'line_num': line_num
                    })
                else:
                    print(f"Warning: Could not parse coordinates on line {line_num}: {line}")
            else:
                print(f"Warning: Could not parse line {line_num}: {line}")
    
    return marks

def get_existing_marks(gpx_filename: str) -> set:
    """Get set of existing mark IDs from GPX file"""
    existing_marks = set()
    
    try:
        tree = ET.parse(gpx_filename)
        root = tree.getroot()
        
        # Define namespace
        ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}
        
        for wpt in root.findall('.//gpx:wpt', ns):
            name_elem = wpt.find('gpx:name', ns)
            if name_elem is not None and name_elem.text is not None:
                mark_id = name_elem.text.strip()
                existing_marks.add(mark_id)
                
    except Exception as e:
        print(f"Error reading GPX file: {e}")
        
    return existing_marks

def add_marks_to_gpx(text_marks: List[Dict], gpx_filename: str):
    """Add missing marks to the GPX file"""
    
    # Get existing marks
    existing_marks = get_existing_marks(gpx_filename)
    
    # Find marks to add
    marks_to_add = []
    for mark in text_marks:
        if mark['id'] not in existing_marks:
            marks_to_add.append(mark)
            print(f"Adding mark: {mark['id']} - {mark['description']}")
        else:
            print(f"Mark {mark['id']} already exists in GPX file")
    
    if not marks_to_add:
        print("No new marks to add!")
        return
    
    # Read and parse GPX file
    tree = ET.parse(gpx_filename)
    root = tree.getroot()
    
    # Define namespace
    ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}
    
    # Add new marks
    for mark in marks_to_add:
        wpt = ET.SubElement(root, '{http://www.topografix.com/GPX/1/1}wpt')
        wpt.set('lat', f"{mark['lat']:.6f}")
        wpt.set('lon', f"{mark['lon']:.6f}")
        
        # Add name
        name_elem = ET.SubElement(wpt, 'name')
        name_elem.text = mark['id']
        
        # Add symbol (simplified)
        sym_elem = ET.SubElement(wpt, 'sym')
        if 'red' in mark['symbol_desc'].lower():
            sym_elem.text = 'R'
        elif 'green' in mark['symbol_desc'].lower():
            sym_elem.text = 'G'
        elif 'yellow' in mark['symbol_desc'].lower():
            sym_elem.text = 'Y'
        elif 'black' in mark['symbol_desc'].lower():
            sym_elem.text = 'B'
        else:
            sym_elem.text = 'Y'  # Default to yellow
        
        # Add description
        desc_elem = ET.SubElement(wpt, 'desc')
        desc_elem.text = mark['description']
    
    # Write back to file
    tree.write(gpx_filename, encoding='utf-8', xml_declaration=True)
    print(f"\nAdded {len(marks_to_add)} new marks to {gpx_filename}")

def main():
    """Main function"""
    text_filename = "Lym Inshore Marks.txt"
    gpx_filename = "2025scra.gpx"
    
    print("Parsing text file...")
    text_marks = parse_text_marks(text_filename)
    print(f"Found {len(text_marks)} marks in text file")
    
    print("\nChecking existing marks in GPX file...")
    existing_marks = get_existing_marks(gpx_filename)
    print(f"Found {len(existing_marks)} existing marks in GPX file")
    
    print("\nAdding missing marks...")
    add_marks_to_gpx(text_marks, gpx_filename)
    
    print("\nDone!")

if __name__ == "__main__":
    main() 