#!/usr/bin/env python3
"""Test the excerpt fix."""
import sys
sys.path.insert(0, 'ai/bin')

# Import the module directly (since confluence is a script, we need to import it as module)
# We'll use importlib to load it
import importlib.util
spec = importlib.util.spec_from_file_location('confluence', 'ai/bin/confluence')
confluence = importlib.util.module_from_spec(spec)
spec.loader.exec_module(confluence)

# Mock data
result_highlight = {
    'title': 'Test',
    '_links': {'webui': '/test'},
    'excerpt': '<b>highlighted</b> text',
    'excerpts': {
        'highlight': '<b>highlighted</b> text',
        'indexed': 'static excerpt'
    },
    'version': {'when': '2025-01-01'}
}

result_indexed = {
    'title': 'Test',
    '_links': {'webui': '/test'},
    'excerpt': '',
    'excerpts': {
        'highlight': '<b>highlighted</b> text',
        'indexed': 'static excerpt'
    },
    'version': {'when': '2025-01-01'}
}

result_no_excerpt = {
    'title': 'Test',
    '_links': {'webui': '/test'},
    'excerpt': '',
    'excerpts': {},
    'version': {'when': '2025-01-01'}
}

def test_excerpt_selection():
    print("Testing excerpt selection...")
    # Test highlight preference when excerpt_type not specified
    out = confluence.format_text_content(result_highlight, snippet_length=200)
    print('Highlight result:', out)
    assert 'highlighted text' in out
    assert '<b>' not in out
    
    # Test with excerpt_type='highlight'
    out = confluence.format_text_content(result_indexed, snippet_length=200, excerpt_type='highlight')
    print('Highlight type:', out)
    assert 'highlighted text' in out
    assert '<b>' not in out
    
    # Test with excerpt_type='indexed'
    out = confluence.format_text_content(result_indexed, snippet_length=200, excerpt_type='indexed')
    print('Indexed type:', out)
    assert 'static excerpt' in out
    
    # Test with excerpt_type='none' (should skip excerpts dict)
    out = confluence.format_text_content(result_indexed, snippet_length=200, excerpt_type='none')
    print('None type:', out)
    # Should have no excerpt (empty)
    assert 'Excerpt: ' in out  # empty excerpt
    
    # Test with excerpt_type='none' and snippet_length=0 (should not fallback)
    out = confluence.format_text_content(result_indexed, snippet_length=0, excerpt_type='none')
    print('None type, snippet 0:', out)
    assert 'Excerpt: ' in out
    
    print("All tests passed!")

if __name__ == '__main__':
    test_excerpt_selection()