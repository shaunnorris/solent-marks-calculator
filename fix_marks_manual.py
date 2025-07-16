#!/usr/bin/env python3
"""
Manual fix script for Lym Inshore Marks.txt
Directly fixes the specific coordinate format issues
"""

import shutil
from datetime import datetime

def fix_coordinates_manual():
    """
    Manually fix the coordinate formats based on the specific issues found
    """
    # Read the original file
    with open("Lym Inshore Marks.txt", 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    fixed_lines = []
    
    # Manual fixes for specific lines
    fixes = {
        3: "1H Bridge 50.39.63 01.36.88 YBY Pillar",
        8: "2A Hurst 50.42.767 01.32.425 Yellow sphere",
        10: "2C Oxey 50.43.83 01.30.86 Yellow cylinder",
        11: "2D Royal Lymington 50.44.17 01.30.10 Yellow cylinder",
        12: "2E Pylewell 50.44.488 01.29.321 Yellow cylinder",
        13: "2F Berthon 50.44.20 01.29.22 Yellow sphere",
        14: "2G Tanners 50.44.79 01.28.47 Yellow cylinder",
        15: "2H H 50.44.30 01.28.16 Yellow cylinder",
        16: "2J Sowley 50.45.11 01.27.33 Yellow sphere",
        17: "2K Cowes Radio 50.44.83 01.26.09 Yellow sphere",
        18: "2L RLymYC 50.43.143 01.31.945 Yellow sphere",
        19: "2R Durns 50.45.43 01.25.89 Yellow sphere",
        20: "2T Lymington Bank 50.43.10 01.30.85 Red Can",
        21: "2U RLymYC Mark U 50.43.665 01.29.502 Yellow sphere",
        22: "2X Solent Bank 50.44.23 01.27.37 Red Can",
        24: "21 Black Rock 50.42.57 01.30.59 Green SHM conical",
        25: "22 Charles Stanley Wealth Managers 50.42.86 01.29.40 Yellow sphere",
        27: "24 Now 50.42.86 01.28.42 Yellow sphere",
        28: "25 Royal Solent 50.43.15 01.27.49 Yellow cylinder",
        29: "26 Hamstead Ledge 50.43.86 01.26.18 Green SHM conical",
        30: "27 Adam Harding-Domeney 50.42.97 01.28.16 Yellow sphere",
        32: "29 R Sol YC ODM 50.42.72 01.29.70 Yellow cylinder",
        33: "2HE East Fairway Bouy 50.42.64 01.29.88 Red can",
        35: "2♠ Spade 50.43.99 01.30.99 Yellow sphere",
        36: "2🌰 Acorn/Oakhaven 50.44.280 01.30.660 Yellow cylinder",
        37: "2S East Mark 50.44.51 01.30.00 Yellow sphere",
        39: "2Z Black & White 50.44.51 01.30.56 Black/white cone",
        40: "2π Pylewell Inner 50.44.92 01.29.70 Yellow cone",
        41: "2+ Plus Mark 50.43.78 01.31.53 Yellow sphere",
        42: "2@ West Reach 50.44.59 01.30.92 Yellow cone",
        43: "2V1 Inshore of Mark L 50.43.32 01.32.13 Inflatable as announced",
        44: "2V2 between Marks C & T 50.43.33 01.30.75 Inflatable as announced",
        45: "2V3 South of Jack in Basket 50.44.06 01.30.40 Inflatable as announced",
        46: "2V4 North of Mark E 50.44.87 01.29.26 Inflatable as announced",
        47: "2V5 Between Marks E & G 50.44.69 01.28.95 Inflatable as announced",
        48: "2V6 Between Marks F & G 50.44.41 01.28.65 Inflatable as announced",
        49: "2V7 Between Marks G & J 50.44.98 01.27.93 Inflatable as announced"
    }
    
    for i, line in enumerate(lines, 1):
        line = line.strip()
        if not line:
            continue
            
        if i in fixes:
            fixed_lines.append(fixes[i])
            print(f"Fixed line {i}: {line} -> {fixes[i]}")
        else:
            fixed_lines.append(line)
            print(f"Line {i}: {line} (no changes needed)")
    
    return fixed_lines

def create_backup(original_file):
    """Create a backup of the original file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f"{original_file}.backup_{timestamp}"
    
    try:
        shutil.copy2(original_file, backup_file)
        print(f"📋 Backup created: {backup_file}")
        return backup_file
    except Exception as e:
        print(f"Warning: Could not create backup: {e}")
        return None

def main():
    """Main function"""
    input_file = "Lym Inshore Marks.txt"
    output_file = "Lym Inshore Marks_fixed.txt"
    
    print("🔧 Manual Lym Inshore Marks Data Fixer")
    print("=" * 40)
    
    # Create backup
    backup_file = create_backup(input_file)
    
    # Fix the data
    print("\nFixing coordinate formats...")
    fixed_lines = fix_coordinates_manual()
    
    # Write fixed data to output file
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            for line in fixed_lines:
                f.write(line + '\n')
        
        print(f"\n✅ Successfully fixed {len(fixed_lines)} marks")
        print(f"📁 Fixed data written to: {output_file}")
        
        print("\n🎉 Data fixing completed successfully!")
        print(f"📊 Original file: {input_file}")
        print(f"📊 Fixed file: {output_file}")
        if backup_file:
            print(f"📊 Backup file: {backup_file}")
        
        print("\nWould you like to replace the original file with the fixed version?")
        print("Run: mv 'Lym Inshore Marks_fixed.txt' 'Lym Inshore Marks.txt'")
        
    except Exception as e:
        print(f"Error writing file: {e}")

if __name__ == "__main__":
    main() 