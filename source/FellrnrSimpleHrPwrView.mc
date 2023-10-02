using Toybox.WatchUi;

class FellrnrSimpleHrPwrView extends WatchUi.SimpleDataField {


	var weight;
	var ZeroPowerHR;
	var HrPwrSmoothing;
	var HrPwrDelay;

	var pwrField;
	var spwrField;
	var shrField;
	var shrpwrField;
	var cardiacCostField;


    var pwrdelay;
    var smoothhr=0;
    var smoothpwr=0;
    var smoothcount=0;
    var SmoothHrPwrCounter=0;


    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "HrPwr";

        var profile = UserProfile.getProfile();
        weight = profile.weight / 1000.0; //grams to Kg
        
//var mApp = Application.getApp();
//        ZeroPowerHR = mApp.getProperty("ZeroPowerHR");
//		HrPwrSmoothing = mApp.getProperty("HrPwrSmoothing").toFloat();
//		HrPwrDelay = mApp.getProperty("HrPwrDelay");
        ZeroPowerHR = Application.Properties.getValue("ZeroPowerHR");
		HrPwrSmoothing = Application.Properties.getValue("HrPwrSmoothing").toFloat();
		HrPwrDelay = Application.Properties.getValue("HrPwrDelay");

/*
createField, since 1.3.0
*/

        pwrField = createField("Fellrnr_SHP_power", 0, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD } );
		spwrField  = createField("Fellrnr_SHP_smooth_power", 1, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD } );
		shrField = createField("Fellrnr_SHP_smooth_hr", 2, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD } );
		shrpwrField = createField("Fellrnr_SHP_hrpwr", 3, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD } );
		cardiacCostField = createField("Fellrnr_SHP_cardic_cost", 4, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD } );
        
        pwrField.setData(0.0);
		spwrField.setData(0.0);
		shrField.setData(0.0);
		shrpwrField.setData(0.0);
		cardiacCostField.setData(0.0);

    }

	var running=false;
    function onTimerStart() {
    	running=true;
	    pwrdelay = null;
    }

    function onTimerPause () {
	    pwrdelay = null;
	}	

    function onTimerResume() {
	    pwrdelay = null;
	}	

    function onTimerStop() {
	    pwrdelay = null;
	}	


    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
		//info.timerState is connect iq 2.1.0+
		if(!running) {
			return ZeroPowerHR + "/bpm " + weight.format("%.1f") + "/Kg";
		}


/*
 * https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity/Info.html#currentPower-var 
 *
 * info.currentPower

Supported Devices:

D2™ Bravo
D2™ Bravo Titanium
D2™ Charlie
D2™ Delta
D2™ Delta PX
D2™ Delta S
D2™ Mach 1
Descent™ Mk1
Descent™ Mk2 / Descent™ Mk2i
Descent™ Mk2 S
Edge® 1000 / Explore
Edge® 1030
Edge® 1030 / Bontrager
Edge® 1030 Plus
Edge® 1040 / 1040 Solar
Edge® 130
Edge® 130 Plus
Edge® 520
Edge® 520 Plus
Edge® 530
Edge® 820 / Explore
Edge® 830
Edge® Explore 2
Enduro™
epix™
epix™ (Gen 2) / quatix® 7 Sapphire
Forerunner® 255
Forerunner® 255 Music
Forerunner® 255s
Forerunner® 255s Music
Forerunner® 265
Forerunner® 265s
Forerunner® 735xt
Forerunner® 745
Forerunner® 920XT
Forerunner® 935
Forerunner® 945
Forerunner® 945 LTE
Forerunner® 955 / Solar
Forerunner® 965
fēnix® 3 / tactix® Bravo / quatix® 3
fēnix® 3 HR
fēnix® 5 / quatix® 5
fēnix® 5 Plus
fēnix® 5S
fēnix® 5S Plus
fēnix® 5X / tactix® Charlie
fēnix® 5X Plus
fēnix® 6 / 6 Solar / 6 Dual Power
fēnix® 6 Pro / 6 Sapphire / 6 Pro Solar / 6 Pro Dual Power / quatix® 6
fēnix® 6S / 6S Solar / 6S Dual Power
fēnix® 6S Pro / 6S Sapphire / 6S Pro Solar / 6S Pro Dual Power
fēnix® 6X Pro / 6X Sapphire / 6X Pro Solar / tactix® Delta Sapphire / Delta Solar / Delta Solar - Ballistics Edition / quatix® 6X / 6X Solar / 6X Dual Power
fēnix® 7 / quatix® 7
fēnix® 7S
fēnix® 7X / tactix® 7 / quatix® 7X Solar / Enduro™ 2
fēnix® Chronos
MARQ® (Gen 2) Athlete / Adventurer / Captain / Golfer
MARQ® (Gen 2) Aviator
MARQ® Adventurer
MARQ® Athlete
MARQ® Aviator
MARQ® Captain / MARQ® Captain: American Magic Edition
MARQ® Commander
MARQ® Driver
MARQ® Expedition
MARQ® Golfer
*/



		//cardiac cost
		var cc=0;
		if(info.currentSpeed != null && info.currentSpeed != 0 && info.currentHeartRate != 0 && info.currentHeartRate != null) {
			var speedInKmMin = info.currentSpeed * 0.06; // *60 for min, /1000 for Km. 
			cc = (info.currentHeartRate / speedInKmMin) / 6000.0; //from Pacing Strategy Affects the Sub-Elite Marathoner�s Cardiac Drift and Performance|doi=10.3389/fpsyg.2019.03026

			cardiacCostField.setData(cc.toFloat());
		}

		var retval = "default";

		//we increase the count even if there's no data, which isn't ideal, but simplifies things greatly. 
		if(SmoothHrPwrCounter < HrPwrSmoothing) {
			SmoothHrPwrCounter++;
		}


		if(info.currentHeartRate != 0 && info.currentHeartRate != null) {
			var hr = info.currentHeartRate;
			smoothhr = (smoothhr*(SmoothHrPwrCounter-1.0)/SmoothHrPwrCounter) + hr.toFloat()/SmoothHrPwrCounter;
			shrField.setData(smoothhr.toFloat());
		} else {
			retval = "No HR";
		} 

		
		
		if(info.currentPower != 0 && info.currentPower != null) {
			var pwr = info.currentPower;
			pwrField.setData(pwr.toFloat());
		} else {
			retval =  "No Pwr";
		} 
			
		if(info.currentHeartRate != 0 && info.currentHeartRate != null && info.currentPower != 0 && info.currentPower != null) {

			var hr = info.currentHeartRate;
			var pwr = info.currentPower;
			
			if(pwrdelay == null) {
				pwrdelay = new [0];
				smoothhr = hr.toFloat();
				smoothpwr = pwr.toFloat();
				SmoothHrPwrCounter=0;
			}
			
			pwrdelay.add(pwr);
			if(info.currentHeartRate <= ZeroPowerHR) {
				retval = "HR < 0pHR";
			} else if(pwrdelay.size() > HrPwrDelay) {
		
				//var delayedpwr = pwrdelay[0].toFloat();
				var delayedpwrraw = pwrdelay[0];
				var delayedpwr = delayedpwrraw.toFloat();
				pwrdelay = pwrdelay.slice(1, null);
				
				smoothpwr = (smoothpwr*(SmoothHrPwrCounter-1.0)/SmoothHrPwrCounter) + delayedpwr/SmoothHrPwrCounter;
		
				var pwrMw = smoothpwr * 1000.0;
		        var pwkg = (pwrMw / weight);
		        var deltahr = (smoothhr - ZeroPowerHR);
		        var hrpw = pwkg / deltahr;
		        var hrpw1dp = Math.round(hrpw*10)/10.0;
			    var hrpwr = hrpw1dp;
	
				spwrField.setData(smoothpwr.toFloat());
				shrpwrField.setData(hrpwr.toFloat());
	
				//System.println("HR " + hr + ", pwr " + info.currentPower + ", delay pwr " + delayedpwr + ", smoothhr " + smoothhr + ", hrpwr " + hrpwr + ", pwrMw: " + pwrMw + ", pwkg: " + pwkg + ", deltahr: " + deltahr + ", hrpw: " + hrpw);
		
				retval = hrpwr;
			} else {
				retval = "Pending data";
			}

		}
		return retval;		

    }

}