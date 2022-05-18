package game.data.scene.characterDialog 
{
	public class DialogTriggerEvent
	{
		public var event:String;
		/** Fag to determine if events associated with dialog trigger before or after the dialog has completed */
		public var triggerFirst:Boolean;
		public var args:Array;
		public static const GIVE_ITEM:String = "giveItem";
		public static const TAKE_ITEM:String = "takeItem";
		public static const EXCHANGE_ITEMS:String = "exchangeItems";
		public static const COMPLETE_EVENT:String = "completeEvent";
		public static const TRIGGER_EVENT:String = "triggerEvent";
		public static const OPEN_POPUP:String = "openPopup";
		public static const APPLY_PART:String = "applyPart";
		public static const LOAD_SCENE:String = "loadScene";
	}
}