
# Why there is ./manifest.xml

ref <https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getversionexw>

> With the release of Windows 8.1, the behavior of the GetVersionEx API has changed in the value it will return for the operating system version. The value returned by the GetVersionEx function now depends on how the application is manifested.

Without manifest embeded, for example, GetVersionEx on  Windows10 will returns dwMajorVersion == 6, as if it's Windows8.1

## How

```
mt -manifest .\manifest.xml -outputresource:
```
