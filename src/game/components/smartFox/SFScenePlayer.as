package game.components.smartFox
{
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.smartFox.CubicSplineData;
	
	/**
	 * Component for any player controlled character in a smartfox managed scene.
	 */
	
	public class SFScenePlayer extends Component
	{
		public function SFScenePlayer($user:User):void{
			user = $user;
		}
		
		public var state_obj:ISFSObject;
		public var action_objs:Vector.<ISFSObject> = new Vector.<ISFSObject>();
		
		public var user:User;
		
		//Last position and velocity received from the the server
		public var last_server_spatial:Spatial;
		public var last_server_motion:Motion;
		
		public var moveTime_RECIEVE:Number;
		
		public var previousTimeSinceLastPacket:Number = 0;
		public var currentTimeSinceLastPacket:Number = 0;
		
		//Last position and velocity sent in a packet to the server
		public var last_sent_spatial:Spatial;
		public var last_sent_motion:Motion;
		
		public var cubicSplineData:CubicSplineData = new CubicSplineData();
		
		public var last_msg_obj:ISFSObject; // last chat message SFS object
		
		public var do_not_disturb:Boolean;
		
		public var spatial_debug:Entity;
		
		public var player_carrot:Entity;
		
		public var icon:Entity;
	}
}
