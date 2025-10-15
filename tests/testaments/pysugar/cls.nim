
import pylib

class E:
  pass

template chk(x) =
  assert not x.isNil
 
chk newE()


class I:
  a: int
  def init(self, a: int):
    self.a = a


def f_i():
  i = I(3)
  chk(i)
  assert i.a == 3

f_i()

class NI:
  a: int
  def init(self, a: int):
    self.a = a
  def new(cls, a: int):
    return super().new(cls)


def f_ni():
  ni = NI(3)
  chk(ni)
  assert ni.a == 3

f_ni()
echo 1
echo dir(NI)
echo 2