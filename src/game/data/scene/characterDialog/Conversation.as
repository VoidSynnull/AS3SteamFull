package game.data.scene.characterDialog
{
	public class Conversation
	{
		public var questions:Vector.<Exchange>;
		public var forceSpeaker:Boolean = false;
		public var id:String;
		public var entityId:String;
		public var event:String;
		public var triggeredByEvent:String;          // an event which causes this conversation to be spoken in scene WITHOUT interaction (optional).
	}
}
