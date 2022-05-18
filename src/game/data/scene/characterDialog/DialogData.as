package game.data.scene.characterDialog 
{
	import game.data.text.TextStyleData;

	public class DialogData 
	{
		public function DialogData(dialog:String = null, type:String = null)
		{
			this.dialog = dialog;
			this.type = type;
		}
		
		/** dialog content */
		public var dialog:String;
		
		/** dialog type : statement, question, or answer */
		public var type:String;
		
		/** the event associated with this dialog which makes it spoken on npc interaction */
		public var event:String;
		
		/** unique string to identify this dialog (optional if question or answer) */
		public var id:String;  
		
		/** a dialog id (or event if the linked dialog has no id) this is linked to (optional).  
		 * Will cause that dialog to be spoken when this one finishes. */
		public var link:String;   
		
		/** the entity who should say the linked dialog */
		public var linkEntityId:String; 
		
		/** if we need to override the default length of time this dialog is visible for. */
		public var timeOverride:Number; 
		
		/** the event triggered by this dialog (optional) */
		public var triggerEvent:DialogTriggerEvent; 
		
		/** an event which causes this dialog to be spoken in scene WITHOUT interaction (optional). */
		public var triggeredByEvent:String;    
		
		/** the entity this dialog belongs to. */
		public var entityID:String;       
		
		/** string id for the styles */
		public var style:String; 
		
		/** style of text to be used with dialog, if not specified uses a default */
		public var textStyleData:TextStyleData;
		/** */
		public var showDialog:Boolean;
		
		/** flag to force dialog to remain on screen, used in special scene cases */
		public var forceOnScreen:Boolean = false;
		
		/** URL of audio to accompany dialog */
		public var audioUrl:String;
		
		/** if this DialogData is actually a set of DialogData */
		public var dialogSet:Vector.<DialogData>;  
		
		/** if dialog is waiting to start, (ex. may need reward an item first) */
		public var waitingToStart:Boolean = false;
	}
}