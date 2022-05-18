package game.components.smartFox
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import ash.core.Component;
	
	/**
	 * Component to hold the scene's states recieved from smartfox.
	 */
	
	public class SFSceneState extends Component
	{
		public var state_queue:Vector.<ISFSObject> = new Vector.<ISFSObject>();  // queued scene state sfsObjects received from server
		public var action_queue:Vector.<ISFSObject> = new Vector.<ISFSObject>(); // queued scene action sfsObjects received from server
		//public var join_queue:Vector.<ISFSObject> = new Vector.<ISFSObject>(); // queued join events for players entering the scene
		//public var leave_queue:Vector.<ISFSObject> = new Vector.<ISFSObject>(); // queued leave events for players leaving the scene
	}
}