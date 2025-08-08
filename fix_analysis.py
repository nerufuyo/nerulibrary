#!/usr/bin/env python3
import os
import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Fix deprecated surfaceVariant
    content = content.replace('surfaceVariant', 'surfaceContainerHighest')
    
    # Fix deprecated withOpacity
    content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
    
    # Fix deprecated background
    content = content.replace('.background', '.surface')
    content = content.replace('.onBackground', '.onSurface')
    
    # Fix curly braces in simple if statements - skip for now
    # This requires more complex parsing
    
    # Fix unnecessary braces in string interpolation
    content = re.sub(r'\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}', r'$\1', content)
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed: {filepath}")

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                fix_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
