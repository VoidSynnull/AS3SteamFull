package game.proxy {

/**
 * 
 * @author Rich Martin
 * 
 */
public class GatewayConstants {

	public static const INVALID_CALL_ID:int			= -1;
	
	// PopError/PopSuccess codes
	public static const AMFPHP_DBERROR:int			= 3;
	public static const AMFPHP_CHANGED:int			= 4;
	public static const AMFPHP_UNCHANGED:int		= 5;
	public static const AMFPHP_NOUSER:int			= 6;
	public static const AMFPHP_SUCCESS:int			= 7;	// lucky seven, the one we like to see
	public static const AMFPHP_NOITEM:int			= 8;
	public static const AMFPHP_NOCREDIT:int			= 9;
	public static const AMFPHP_NOREASON:int			= 10;
	public static const AMFPHP_NOTNUM:int			= 11;
	public static const AMFPHP_NODATA:int			= 12;
	public static const AMFPHP_NOFIELD:int			= 13;
	public static const AMFPHP_ALREADY_THERE:int	= 14;
	public static const AMFPHP_RETURNED:int			= 15;
	public static const AMFPHP_NOTDATE:int			= 16;
	public static const AMFPHP_NOT_MEMBER:int		= 17;
	public static const AMFPHP_EXPIRED_MEMBER:int	= 18;
	public static const AMFPHP_EMAIL_ERROR:int		= 19;
	public static const AMFPHP_NOISLAND:int			= 20;
	public static const AMFPHP_UNDEFINED:int		= 21;
	public static const AMFPHP_PROBLEM:int			= 22;
	public static const AMFPHP_MISSING:int			= 23;
	public static const AMFPHP_PROMO_INVALID:int	= 24;
	public static const AMFPHP_PCODE_INVALID:int	= 25;
	public static const AMFPHP_PCODE_VENDOR:int		= 26;
	public static const AMFPHP_PCODE_EXPIRED:int	= 27;
	public static const AMFPHP_PCODE_FUTURE:int		= 28;
	public static const AMFPHP_PCODE_NONMEMBERS_ONLY:int	= 29;
	public static const AMFPHP_PCODE_MEMBERS_ONLY:int	= 30;
	public static const AMFPHP_PCODE_USED:int		= 31;
	public static const AMFPHP_PCODE_USED_BY_USER:int	= 32;
	public static const AMFPHP_CANNOT_CHANGE:int	= 33;
	public static const AMFPHP_NOT_FOUND:int		= 34;
	public static const AMFPHP_WRONG_TYPE:int		= 35;
	public static const AMFPHP_NO_AVAILABLE_ITEM:int	= 36;
	public static const AMFPHP_NO_FRIEND:int		= 37;
	public static const AMFPHP_NOT_FRIEND:int		= 38;
	public static const AMFPHP_INVALID_PARAM:int	= 39;
	public static const AMFPHP_CANNOT_FRIEND_SELF:int	= 40;
	public static const AMFPHP_UNVALIDATED_USER:int	= 41;
	public static const AMFPHP_NOT_PARTIAL_USER:int	= 42;

	public static const LOOKUP_FAILED:String = 'lookup-failed';		// the error response for GatewayConstants.resultNameForCode()
	
	// Inventory Item codes
	public static const AMFPHP_ITEM_GONE:int		= 0;	// item has been given to NPC
	public static const AMFPHP_ITEM_NORMAL:int		= 1;	// item has been obtained in game or with credits
	public static const AMFPHP_ITEM_RENTED:int		= 2;	// item can only be used during active membership
	
	public static function resultNameForCode(theCode:int):String {
		var theNames:Array = [
			'',							// 0
			'',							// 1
			'',							// 2
			'database-error',			// 3
			'changed',					// 4
			'unchanged',				// 5
			'no-such-user',				// 6
			'success',					// 7
			'no-such-item',				// 8
			'insufficient-credit',		// 9
			'no-such-reason-code',		// 10
			'not-a-number',				// 11
			'no-data',					// 12
			'no-such-field',			// 13
			'item-already-there',		// 14
			'item-returned',			// 15
			'not-a-date',				// 16
			'notmember',				// 17
			'expired',					// 18
			'email-error',				// 19
			'no-such-island',			// 20
			'undefined-value-sent',		// 21
			'problem',					// 22
			'missing-param',			// 23
			'no-such-promo',			// 24
			'no-such-promo-code',		// 25
			'wrong-vendor',				// 26
			'code-expired',				// 27
			'code-not-yet',				// 28
			'code-for-nonmember',		// 29
			'code-for-member',			// 30
			'code-already-used',		// 31
			'you-already-used-code',	// 32
			'cannot-change-that',		// 33
			'not-found',				// 34
			'wrong-type',				// 35
			'no-available-item',		// 36
			'no-such-friend-login',		// 37
			'not-friend',				// 38
			'invalid-param',			// 39
			'cannot-friend-yourself',	// 40
			'user-not-validated',		// 41
			'not-a-partial-user',		// 42
		];
		var name:String = theNames[theCode];
		return (name ? name : LOOKUP_FAILED);
	}

	public function GatewayConstants() {}
	
}

}
