package game.data.ui.card 
{
	import game.data.ConditionalData;
	import game.data.ParamList;
	import game.util.DataUtils;

	public class CardAction 
	{

		public function CardAction(xml:XML = null):void
		{
			if(xml != null)
			{
				parse(xml);
			}
		}
		
		public function parse( xml:XML ):void
		{
			this.type = DataUtils.getString( xml.attribute("type") );
			this.tracking = DataUtils.getString( xml.attribute("tracking") );
			this.blockInventoryClose = DataUtils.getBoolean(xml.attribute("blockClose"));
			
			if( xml.hasOwnProperty("parameters"))
			{
				params = new ParamList( XML(xml.parameters) );
			}
			if( xml.hasOwnProperty("conditional") )
			{
				conditional = new ConditionalData(XML(xml.conditional));
			}
		}
		
		public var type:String; 		// type of action, these are constants (see below) picked up by the ItemCard UIView group   
		public var params:ParamList;	// parameters of action
		public var conditional:ConditionalData;
		public var tracking:String;		// for campaign tracking
		public var blockInventoryClose:Boolean = false;
			
		public const TRACK:String 				= "track";
		public const TRIGGER_EVENT:String 		= "triggerEvent";
		public const REMOVE_EVENT:String		= "removeEvent";
		public const SET_USER_FIELD:String 		= "setUserField";
		public const REMOVE_ITEM:String			= "removeItem";
		public const SHOW_ITEM:String			= "showItem";
		public const GET_ITEM:String			= "getItem";
		public const GO_TO_URL:String 			= "gotoUrl";
		public const COSTUMIZE:String 			= "costumize";
		public const OPEN_POPUP:String 			= "openPopup";
		public const OPEN_VIDEO_POPUP:String 	= "openVideoPopup";
		public const LOAD_SCENE:String 			= "loadScene";
		public const APPLY_LOOK:String 			= "applyLook";
		public const APPLY_LOOK_NPC:String		= "applyLookNPC";
		public const REMOVE_LOOK:String 		= "removeLook";
		public const ACTIVATE_POWER:String 		= "activatePower";
		public const DEACTIVATE_POWER:String 	= "deactivatePower";
		public const ADD_GROUP:String 			= "addGroup";
		public const PRINT_POSTER:String 		= "printPoster";
		public const PLAY_SOUND:String			= "playSound";
		public const SHRINK_PLAYER:String		= "shrinkPlayer";
		public const SHRINK_NPCS:String			= "shrinkNPCs";
		public const UNSHRINK_PLAYER:String		= "unshrinkPlayer";
		public const UNSHRINK_NPCS:String		= "unshrinkNPCs";
	}
}