package game.scene.template
{
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.requests.ExtensionRequest;

	public class SFViewportGroup extends SFSceneGroup
	{
		public function SFViewportGroup(debug:Boolean=false, $startTime:Number = 0, $joinTime:Number = 0, $updateFrequency:int = 0)
		{
			super(debug, $startTime, $joinTime, $updateFrequency);
		}
		
		protected override function joinSFScene():void{
			//trace("    - SFViewportGroup:joinSFScene()");
			
			// listeners
			shellApi.smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onSFSExtension);
			shellApi.smartFox.addEventListener(SFSEvent.USER_ENTER_ROOM, onSFSUserEnter);
			shellApi.smartFox.addEventListener(SFSEvent.USER_EXIT_ROOM, onSFSUserExit);
			
			setupSFScene();
			
			// get flash state from server room
			shellApi.smartFox.send(new ExtensionRequest(CMD_FLASH_STATE, null, shellApi.smartFox.lastJoinedRoom));
		}
		
		protected override function onSFSUserExit(event:SFSEvent):void
		{
			trace("User exited: "+event.params.user);
			// remove player
			if(!User(event.params.user).isItMe){
				removePlayer(event.params.user);
			}
		}
	}
}