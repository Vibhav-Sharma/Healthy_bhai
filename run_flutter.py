import os
print("Running flutter pub get...")
os.system("flutter pub get")
print("Running flutter_launcher_icons...")
os.system("dart run flutter_launcher_icons")
print("Running flutter_native_splash...")
os.system("dart run flutter_native_splash:create")
print("Done!")
