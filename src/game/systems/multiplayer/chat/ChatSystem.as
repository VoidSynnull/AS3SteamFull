package game.systems.multiplayer.chat
{
	import ash.tools.ListIteratingSystem;
	
	public class ChatSystem extends ListIteratingSystem
	{
		public function ChatSystem(nodeClass:Class, nodeUpdateFunction:Function, nodeAddedFunction:Function=null, nodeRemovedFunction:Function=null)
		{
			super(nodeClass, nodeUpdateFunction, nodeAddedFunction, nodeRemovedFunction);
		}
	}
}