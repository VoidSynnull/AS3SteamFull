package game.data.comm {

/**
 * BrainTrackingData formalizes the payload sent to
 * the AMFPHP BrainService.
 * @author Rich Martin
 * 
 */
public final class BrainTrackingData {
	import game.util.Utils;

	public static function instanceFromInitializer(spec:Object):BrainTrackingData {
		return Utils.overlayObjectProperties(spec, new BrainTrackingData()) as BrainTrackingData;
	}

	//// Event data ////

	/**
	 * The event name is pretty free-form, but <strong>NOTA BENE</strong>: this is the <strong>only</strong> required value for a valid BrainTrackingData.
	 */	
	public var eventName:String;

	//// Location data ////

	/**
	 * The brain name, which is 'most always <code>Track.AS3_BRAIN_NAME</code> ('Poptropica2').
	 */	
	public var brain:String;
	/**
	 * This value is not used in AS3?
	 */	
	public var game:String;
	/**
	 * The simple AS3 class name of the current scene, e.g. <code>MainStreet</code>.
	 */	
	public var scene:String;
	/**
	 * The domain name of the web site, usually either <code>www.funbrain.com</code> or <code>www.poptropica.com</code>.
	 */	
	public var site:String;
	/**
	 * This island's AS3 package name, e.g. <code>virusHunter</code>.
	 */	
	public var cluster:String;

	//// Grouping data ////

	/**
	 * The name of an ad campaign or other event group, such as <code>uiEvent</code>.
	 */	
	public var campaign:String;

	//// Parameter data ////
	/**
	 * The answer to a question or an event descriptor, e.g. <code>inventoryOpened</code> for a <code>uiEvent</code>.
	 */	
	public var choice:String;
	/**
	 * When <code>choice</code> is not sufficient, <code>subchoice</code> can provide more detail.
	 */	
	public var subchoice:String;
	/**
	 * A specially formatted string containing lists of numeric values to be averaged on the server
	 * <p>The generalized format is '&lt;listName&gt;:&lt;value1&gt;,&lt;value2&gt;,...,&lt;listName&gt;:&lt;valueA&gt;,&lt;valueB&gt;,...'</p>
	 * 
<listing version="3.0">
Example:
'TimeSpent:30,IdleTime:10,ReactionTimes:5,5,7,4,8,9,6,6,5'
</listing>
	 */	
	public var numvals:String;

	//// Demographic data ////

	/**
	 * Two-character country code.
	 */	
	public var country:String;

	/**
	 * There are only two legal values: <code>M</code> or <code>F</code>.
	 */	
	public var gender:String;

	/**
	 * 1–12 are the regular grades, 0 is kindergarten. Negative values -1 through -5 are ages 4 through 0.
	 * Since Poptropica accounts are established by age, the rule is to subtract 5 to obtain a grade value;
	 */	
	public var grade:String;

	/**
	 * A simplified POSIX locale string. e.g. <code>fr_ca</code> for Canadian French
	 */	
	public var lang:String;

	/**
	 * One of the following values:
	 <listing version="3.0">
mobile
tablet
desktop	(the default value if omitted)
	 </listing>
	 * <p>The AS3 codebase reports its platform thusly:
	 * <code>desktop_as3</code> if running in browser,
	 * <code>tablet</code> if screen width is greater than 4 inches,
	 * otherwise <code>compact</code></p>
	 */	
	public var platform:String;

	/**
	 * There are only two legal values: <code>Y</code> or <code>N</code>.
	 */	
	public var member:String;

	/**
	 * The player's login name.
	 */	
	public var login:String;

	//// Housekeeping data ////

	/**
	 * A positive value is taken as the number of seconds since midnight GMT 1/1/1970.
	 * A negative value is taken as that many seconds in the past.
	 */	
	public var time:String;

	/**
	 * If non-null, used as a cache-buster.
	 */	
	public var randomNumber:String;

	//// CONSTRUCTOR ////

	public function BrainTrackingData() {}

	//// ACCESSORS ////

	/**
	 * The name of this object's event. Provided as a convenience for backward-compatibility.
	 */	
	public function get event():String {	return eventName; }
	/**
	 * @private
	 */	
	public function set event(newEventName:String):void {
		eventName = newEventName;
	}

	//// PUBLIC METHODS ////

	// TODO: include non-null instance variables in result
	public function toString():String {
		return '[BrainTrackingData event:' + event + ']';
	}

}

}
