#!/usr/bin/env python3
import time

print("Python aplikace běží v Dockeru!")
for i in range(5):
    print(f"Iterace {i+1}/5")
    time.sleep(1)
print("Hotovo!")
