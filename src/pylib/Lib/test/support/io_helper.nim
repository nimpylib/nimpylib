
import pkg/jscompat/syncio
proc create_writable_file*(filename: string) =
  try:
    writeFileCompat(filename, "")
  except IOError: discard


  
  
