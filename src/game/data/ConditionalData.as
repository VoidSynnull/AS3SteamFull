package game.data
{
	import game.util.DataUtils;

	/**
	 * Conditional Data used with cards. 
	 * @author umckiba
	 * 
	 */
	public class ConditionalData
	{
		
		public function ConditionalData( xml:XML = null )
		{
			if( xml != null )
			{
				parse( xml );
			}
		}

		public function parse( xml:XML ):void
		{
			this.id = DataUtils.getString( xml.attribute("id") );
			this.isTrue = DataUtils.getBoolean( xml.attribute("isTrue") );
			this.type = DataUtils.getString( xml.attribute("type") );
			
			// if id wasn't specified & type was, than have id equal type (this situation allows for less redeundacy in xml)
			if( !DataUtils.validString(id) && DataUtils.validString(type) )
			{
				id = type;
			}
			
			if( xml.hasOwnProperty("parameters") )
			{
				paramList = new ParamList( XML(xml.parameters) );
			}
		}
		
		public function duplicate():ConditionalData
		{
			var data:ConditionalData = new ConditionalData();
			data.id = id;
			data.type = type;
			data.isTrue = isTrue;
			data.value = value;
			data.paramList = paramList.duplicate();
			return data;
		}
		
		public var id:String;				// id of this particular conditional
		public var type:String;				// type of conditional check
		public var isTrue:Boolean = false;	// flag determining if conditional has been met or not
		public var paramList:ParamList;		// holds parameters for use when testing conditional
		public var value:*;					// value determined by conditional statement
		
		
		// Type of conditonals
		public static const IN_ISLAND:String 		= "inIsland";
		public static const IN_SCENE:String 		= "inScene";
		public static const CHECK_EVENTS:String 	= "checkEvents";
		public static const HAS_ABILITY:String 		= "hasAbility";
		public static const HAS_PART:String 		= "hasPart";
		public static const HAS_LOOK:String 		= "hasLook";
		public static const HAS_PET_LOOK:String 	= "hasPetLook";
		public static const IS_SCALED:String 		= "playerIsScaled";
		public static const ALL_SCALED:String 		= "npcsAreScaled";
		public static const USED_ITEM:String 		= "usedItem";
		public static const CHECK_TRIBE:String 		= "checkTribe";
		public static const CHECK_USER_FIELD:String = "checkUserField";
		public static const CHECK_IF_MOBILE:String  = "checkIfMobile";
		public static const CHECK_GENDER:String  	= "checkGender";
		public static const CHECK_LANGUAGE:String	= "checkLanguage";
	}
}