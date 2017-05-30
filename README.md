## Xiaomi SafetyNet Fix
[More details in support thread](https://forum.xda-developers.com/apps/magisk/xiaomi-safetynet-fix-t3600431)  
Fix SafetyNet on Xiaomi devices with MIUI Developer/Beta ROM & Custom ROM like LOS, RR, etc.

## Changelog
#### v1.9.1
- Fixed logging code: ignore output of wait for unmount loop
#### v1.9
- Added new supported devices: Redmi Pro, Mi 4S, Redmi 4X
- Changed Redmi Note 3 MTK prop
- Changed wait for Magisk SafetyNet check to a function and run in a subshell
#### v1.8.2
- Fixed Redmi Note 3 MTK device name typo
#### v1.8.1
- Fixed forgotten set_prop function calls
#### v1.8
- Added new supported devices: Mi Note Pro, Redmi 1, Redmi 1S
- Fixed Mi 5 prop
- Removed run enable script
- Code improved
#### v1.7
- Added new supported devices: Mi 6
- Added "ro.bootimage.build.fingerprint" prop
- Removed reinitiate Magisk Hide
- Added run Magisk Hide when boot & service steps are completed
- Improved log code: waiting to SafetyNet test and Magisk Hide folder unmount, silence some shell output
#### v1.6
- Added new supported devices: Mi Pad, Mi Note, Mi 3/Mi 4, Mi 2/2S, Mi Pad 2, Mi Pad 3
- Added code to reinitiate Magisk Hide
#### v1.5
- Added new supported devices: Redmi 4, Redmi 4 Prime, Redmi 4A
#### v1.4
- Added new supported devices: Redmi 3/Prime, Mi 4i
- Added code to generate useful logs and enable Magisk Hide if not enabled
- Changed to use resetprop directly from script
- Removed build description because is useless
#### v1.3
- Added new supported devices: Redmi 2/4G, Redmi 2 Prime
#### v1.2
- Added new supported devices: Mi 4c, Mi 5c, Redmi Note 3 Special Edition, Mi Note 2, Redmi Note 4X
#### v1.1
- Added new suported devices: Mi Max, Mi Max Prime, Redmi 3S/Prime/3X
#### v1
- Initial release
- Suported devices: Redmi Note 2, Redmi Note 3 MTK, Redmi Note 3 Qualcomm, Redmi Note 4 MTK, Mi 5, Mi 5s, Mi 5s Plus, Mi MIX
