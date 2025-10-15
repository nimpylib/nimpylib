
import pylib
var g = 0

class O:
  def f2(self) -> None:
    self.f1()
  def f1(self) -> None:
    global g
    g += 1


O().f2()
assert g == 1
