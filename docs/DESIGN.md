# OBP Driver Hub - Mobile App Design Document
## 1. Overview
The OBP Driver Hub is a native mobile application built for Ong Brothers Petroleum lorry drivers. Its primary function is to capture physical proof of fuel delivery (Odometer OCR, GPS Location, and Receipt Photos) to protect the company's SKDS diesel quota. 
## 2. UI/UX Guidelines
- **Theme:** Dark mode to match the manager's web dashboard and reduce glare during night driving.
- **Background:** Deep Slate (`#0F172A`).
- **Cards/Containers:** Dark Blue-Gray (`#1E293B`) with subtle borders (`#334155`).
- **Primary Accents:** Shell Red (`#E31837`) for main actions, Shell Yellow (`#FBCE07`) for warnings or highlights, and Emerald Green (`#10B981`) for success states.
- **Typography:** Clean, sans-serif (Inter or Roboto). Large, readable fonts for drivers.
- **Navigation:** Persistent Bottom Navigation Bar for quick switching between Home, Scan, and History.
## 3. Core Screens & Flow
1. **Login Screen:** Simple corporate email and password login.
2. **Home (Dashboard):** Displays assigned lorry plate (e.g., JDT 1111), current SKDS quota balance, and quick action to refuel.
3. **Submit Fuel Claim (Scanner):** The core module. Features three mandatory steps:
   - Tap to scan Odometer (Triggers camera/OCR).
   - Verify Location (Triggers GPS check against Shell station).
   - Upload Receipt (Triggers camera).
4. **Claim History:** A list showing pending, approved, and rejected fuel claims.
## 4. Hardware Integrations (Placeholders for UI)
- **Google ML Kit:** UI must show a "Scan" button with a camera icon.
- **Native GPS:** UI must show a "Verify Location" button with a map pin icon and a status indicator (Red = Unverified, Green = Verified).