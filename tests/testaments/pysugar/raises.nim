discard """
  output: '''
1
'''
"""
import pylib

def f():
  try: raise OSError()
  except (ValueError, OSError) as e:
    print(1)

f()
