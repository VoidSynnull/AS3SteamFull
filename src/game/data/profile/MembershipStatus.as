package game.data.profile
{
	import flash.net.URLVariables;
	
	/**
	 * MembershipStatus is a value object comprising a
	 * Poptropican's membership status and a related date.
	 * @author Rich Martin
	 */
	public class MembershipStatus
	{
		public static const MEMBERSHIP_UNKNOWN:uint		= 1;
		public static const MEMBERSHIP_INVALID:uint		= 2;
		public static const MEMBERSHIP_NONMEMBER:uint	= 3;
		public static const MEMBERSHIP_ACTIVE:uint		= 4;	// endDate indicates date of expiration (future)
		public static const MEMBERSHIP_EXTENDED:uint	= 5;	// endDate indicates date of next renewal
		public static const MEMBERSHIP_EXPIRED:uint		= 6;	// endDate indicates date of expiration (past)
		
		private static const statusCodes:Object = {
			 "nologin":			MEMBERSHIP_INVALID,
			 "dberror":			MEMBERSHIP_UNKNOWN,
			 "notmember":		MEMBERSHIP_NONMEMBER,
			 "active-renew":	MEMBERSHIP_EXTENDED,
			 "active-norenew":	MEMBERSHIP_ACTIVE,
			 "expired":			MEMBERSHIP_EXPIRED
		};
		
		public static function getAS2Status(code:uint):String
		{
			if (code > 3)
			{
				for (var as2value:String in statusCodes)
				{
					if (statusCodes[as2value] == code)
					{
						return as2value;
					}
				}
			}
			return "notmember";
		}
	
		public static function instanceFromURLVariables(vars:URLVariables):MembershipStatus {
			function niceDate(ts:String):String {
				var parts:Array = ts.split(' ');
				if (parts.length != 2) {
					throw new Error("funky timestamp format");
				}
				var timePart:String = parts[1];
				parts = parts[0].split('-');
				if (parts.length != 3) {
					throw new Error("funky date format");
				}
				var year:String = parts[0];
				var monthNum:String = parts[1];
				var dayNum:String = parts[2];
				return monthNum + '/' + dayNum + '/' + year + ' ' + timePart;
			}
	
			var newInstance:MembershipStatus = new MembershipStatus();
			var code:uint = 0;
			if (vars && vars.hasOwnProperty('memstatus')) {
				code = statusCodes[String(vars.memstatus)];
			}
			if (0 == code) {	// vars.memstatus had an unknown, invalid value
				code = MEMBERSHIP_UNKNOWN;
			} else {
				if (code > MEMBERSHIP_NONMEMBER) {
					newInstance.endDate = new Date(niceDate(vars.memdate));
				}
			}
			newInstance.statusCode = code;
			return newInstance;
		}
		
		public var statusCode:uint = MEMBERSHIP_UNKNOWN;
		public var endDate:Date;
	
		public function MembershipStatus()
		{
		}
	}
}
