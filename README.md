# bats
Battery Automated Testing System

## Purpose

BATS provides a way to automate battery capacity testing, especially performing back to
back charge/discharge cycles with battery terminal temperature monitoring.  It utilizes
a Victron Multiplus inverter to charge and discharge the battery, and a Smartshunt to
precisely measure the amps and total Ah discharged.  A Cerbo (or Ekrano) controls the
automation through a NodeRed program that adjusts the Grid Set to push the maximum
allowed amps in or out of the battery.  Temperature monitoring allows detection of
certain failure conditions to reduce charge current or completly shut the test down.

## Components Required

* Victron Multiplus Inverter (used 12vdc 3kva 120vac, others should work)
* Victron Smartshunt (used IP65 Smartshunt, any version or BMV-712 should work)
* Victron Cerbo (or Ekrano) - Touch70 optional
* DIHOOL 200 Amp DC Breaker on DC Positive to battery or other disconnect
* 1/0 Wiring between inverter, shunt, and battery
* Two battery terminal probes (ASS000001000), connected to Temp Input 1 & 2

## Design Specifications

* Supports LFP and AGM battery testing (shuts off at 12.0v during discharge)
* Note: the shutoff voltage could be controlled by nodered in the future to allow change
* Victron 3000 Inverter is configured for ESS mode to allow charge/discharge of battery
* Both ESS mode and Smartshunt are configured with 1000ah battery
* ACIN (only) is connected to mains with a standard outlet plug (NEMA-15P)
* It can handle just over 200 amps discharge, although only 120 charge
* Temperature probes 1 & 2 are bolted to the battery terminals along with DC connectons
* Capacity test results will vary based on max discharge amps
* Charging is assumed complete when average charge amps drops below 1.5A and consumed Ah returns to 0

## Wiring Diagram

```
 ##############
 #  MULTIPLUS #
 #            #
 #       DC- ---- SMARTSHUNT ----- BATTERY NEGATIVE
 #            #     |
 #       DC+ -------+-- DIHOOL 200A ---- BATTERY POSITIVE
 #            #
 #     ACOUT  #
 #      ACIN --------> 15A plug to MAINS
 #            #
 ##############
```

Not shown:
* CAT5 cable from Multiplus to Cerbo VEBUS
* VEDIRECT cable from Smartshunt to Cerbo VEDIRECT
* Cerbo Power cable to Multiplus +/- terminals (powered even with DIHOOL off)

## Device Configuration

* Victron 3000 12/3000 configuration in multiplus.vsc (VEConfig.exe)
* Victron Smarthshunt configuration in smartshunt.vcsf (VictronConnect)

### Settings for Cerbo

* Firmware update with Large model
* Integrations/Tank and Temperature Sensors: turn Temp input 1 & 2 ON
* Integrations/Node-RED: Enabled
* System Setup/ESS: Mode: Optimized without BatteryLife
* Charge/Discharge of the battery can be tested by setting Grid setpoint positive or negative

## Nodered program

* Stored in file flows.json
* Uses Virtual Switch to provide status readout and settings on Cerbo Display
* A Mode dropdown selects the test state; the Grid setpoint is engine-controlled only
* Max current settings for charge/discharge cause auto adjust of Grid setpoint Watts (constant current)
* Nearly all logic is in TestEngine function
* Email of status is sent on every mode change; results included on charge/discharge completion
* Note: the program currently has some math assumptions for 12v

### Test Modes

* IDLE - holds Grid setpoint at 200W for a trickle charge
* CHARGE - regulates to +Charge Amps; when full, emails the result and switches to DISCHARGE
* DISCHARGE - regulates to -Discharge Amps; when empty (11.8V floor), emails the capacity result and switches to CHARGE
* STOP - charges to full like CHARGE, then emails the result and switches to IDLE
* FAIL - entered automatically when a terminal temperature exceeds 50C; can also be selected manually as an abort. Holds a 100W trickle to keep the battery topped off (0W while a terminal is over the temperature limit)

CHARGE and DISCHARGE alternate until 10 discharge cycles have completed, then the
test proceeds to STOP (recharge to full, then IDLE). The cycle count is included in
each discharge result email and resets when a test ends (entering IDLE or FAIL).
A discharge yielding less than 5 Ah is treated as a FAIL and stops the test.
STOP, IDLE, or FAIL can also be selected at any time to end the test early.
Every mode transition (automatic or user-selected) sends an email with the status to that point.

After a Node-RED restart or redeploy, the mode is presumed from the persisted Grid
setpoint so a test in progress resumes: negative = DISCHARGE, positive = CHARGE,
exactly 200W = IDLE, exactly 100W (or 0W) = FAIL. A STOP in progress resumes as
CHARGE. The presumed
mode is pushed back to the display dropdown, and for 30 seconds after resume any
stale dropdown value is overridden rather than obeyed.
 
