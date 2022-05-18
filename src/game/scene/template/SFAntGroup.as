package game.scene.template
{
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.utils.getTimer;
	
	import engine.group.Group;
	
	import game.components.smartFox.SFAnt;
	import game.managers.SmartFoxManager;
	import game.systems.SystemPriorities;
	import game.systems.smartFox.SFAntSystem;
	
	/**
	 * Group added to scenes for 'Ant Farm' testing of multiplayer.
	 * @author Bart Henderson
	 */
	public class SFAntGroup extends Group
	{
		// scene types
		public static const SCENE_ANT:String    						= "S_ANT"; // a dynamically created scene for ant farm testing
		public static const SCENE_OBSERVED:String   					= "S_OBV"; // a dynamically created scene visible only to selected clients (useful for devs)
		
		public static const TIMESTAMP_PLAYERUPDATE_SENT:String    		= "t"; // time at which a player has sent an update per the client's scene clock
		public static const TIMESTAMP_SCENE_CLOCK:String       			= "T"; // server's scene clock since the start of it's creation
		public static const TIMESTAMP_PLAYERUPDATE_RECIEVED:String    	= "R"; // time at which a player update was recieved by the server per the server's scene clock
		
		public static const UPDATE_FREQUENCY:String						= "F"; // update frequency from a scene
		
		public static const CMD_ACTIVATE_ANT:String     				= "A_AA";
		public static const CMD_DEACTIVATE_ANT:String					= "A_DA";
		public static const CMD_DLT_ANT:String				            = "A_DLA";
		public static const CMD_VIEW_PORT:String						= "A_VP";
		public static const CMD_JOIN_SCENE:String       				= "joinScene";
		public static const CMD_PLAYERUPDATE:String     				= "U";
		public static const CMD_KICKED:String							= "K"; // kicked from room
		
		public static const KEY_VIEW_PORT_ON:String	            		= "A_VPO";
		
		public static var active:Boolean = true; // if set to true, the antGroup will be activated when added to a new scene
		public static var viewportOn:Boolean = false; // if set to true, the angroup will activate a viweport to the scene
		
		public function SFAntGroup()
		{
			super();
		}
		
		override public function destroy():void{
			shellApi.smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onSFSRoomJoin);
			shellApi.smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse);
			shellApi.smartFox.removeEventListener(SFSEvent.USER_EXIT_ROOM, onSFSRoomUserExit);
			
			shellApi.smartFoxManager.disconnected.remove(deactivate);
			
			super.destroy();
		}
		
		override public function added():void
		{
			if(AppConfig.debug){
				trace("   ---------------------------------");
				trace("   [ ... SFAntFarm Group Ready ... ]");
				trace("   ---------------------------------");
			}
			
			// listen for ant farm activation
			shellApi.smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse);
			
			if(active && !viewportOn)
				activate();
			
			if(viewportOn){
				viewPortOn();
			} else {
				// sense when we have moved into an observed room or joined an ant room upon activation
				shellApi.smartFox.addEventListener(SFSEvent.ROOM_JOIN, onSFSRoomJoin);
				
				// sense when a user leaves an observed room
				shellApi.smartFox.addEventListener(SFSEvent.USER_EXIT_ROOM, onSFSRoomUserExit);
				
				// get ant system ready (activated when we add the SFAnt component to the player)
				_antSystem = new SFAntSystem(shellApi.smartFox, this);
				this.addSystem(_antSystem, SystemPriorities.postUpdate);
			}
		}
		
		protected function onExtensionResponse(event:SFSEvent):void
		{
			var isfso:ISFSObject = event.params.params;
			
			switch(event.params.cmd){
				case CMD_ACTIVATE_ANT:
					active = true;
					activate();
					break;
				case CMD_DEACTIVATE_ANT:
					active = false;
					deactivate();
					break;
				case CMD_VIEW_PORT:
					viewportOn = isfso.getBool(KEY_VIEW_PORT_ON);
					if(viewportOn){
						viewPortOn();
					} else {
						
					}
					break;
				case TIMESTAMP_SCENE_CLOCK: // recieved time stamp from join event
					
					//trace("   ANTFARM ---- RECIEVED TIME STAMP");
					//trace(ISFSObject(event.params.params).getDump());
					_startTime = getTimer();
					_joinTime = ISFSObject(event.params.params).getLong(TIMESTAMP_SCENE_CLOCK);
					updateFrequency = ISFSObject(event.params.params).getInt(UPDATE_FREQUENCY);
					break;
				
			}
		}
		
		private function activate():void
		{
			if(AppConfig.debug){
				trace("   ---------------------------------");
				trace("   [ ...    SFAnt Activated    ... ]");
				trace("   ---------------------------------");
			}
			
			shellApi.smartFoxManager.disconnected.addOnce(deactivate);
			
			// check if user character data has been submitted - 
			var myUser:User = shellApi.smartFox.mySelf;
			if(myUser.getVariable(SmartFoxManager.USER_CHAR_LOOK) == null){
				// if not, send it and wait for a response
				shellApi.smartFoxManager.charUpdated.addOnce(joinSFScene);
				shellApi.smartFoxManager.updateCharData();
			} else {
				// if so, join the scene
				joinSFScene();
			}		
		}
		
		private function viewPortOn():void{
			if(AppConfig.debug){
				trace("   ---------------------------------");
				trace("   [ ...  ViewPort Activated   ... ]");
				trace("   ---------------------------------");
			}
			
			// remove ant farm listeners
			shellApi.smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onSFSRoomJoin);
			shellApi.smartFox.removeEventListener(SFSEvent.USER_EXIT_ROOM, onSFSRoomUserExit);
			
			// remove ant system
			
			if(shellApi.player.get(SFAnt) != null){
				// remove component
				shellApi.player.remove(SFAnt);
				// remove system
				this.removeSystem(_antSystem);
				// if already in the ant room - no need to join, just add the viewPortGroup and pass in the _startTime and _joinTime
				_SFViewportGroup = this.parent.addChildGroup(new SFViewportGroup(false, _startTime, _joinTime, updateFrequency)) as SFViewportGroup;
			} else {
				joinObservedScene();
			}
		}
		
		private function joinObservedScene():void{
			trace("    - SFAntGroup:joinObservedScene()");
			shellApi.smartFox.addEventListener(SFSEvent.ROOM_JOIN, onSFSObsRoomJoin);
			
			// connect to a observed scene
			var params:ISFSObject = new SFSObject();
			params.putUtfString("type", SCENE_OBSERVED);
			params.putUtfString("island", shellApi.island);
			params.putUtfString("scene", shellApi.sceneName);
			
			shellApi.smartFox.send(new ExtensionRequest(CMD_JOIN_SCENE, params));
		}
		
		protected function onSFSObsRoomJoin(event:SFSEvent):void{
			// trash join room listener
			shellApi.smartFox.removeEventListener(SFSEvent.ROOM_JOIN, onSFSObsRoomJoin);
			
			// turn on Viewport Group
			_SFViewportGroup = this.parent.addChildGroup(new SFViewportGroup()) as SFViewportGroup;
			
			
		}
		
		private function joinSFScene():void
		{
			//trace("    - SFAntGroup:joinSFScene()");
			
			// connect to a public scene
			var params:ISFSObject = new SFSObject();
			params.putUtfString("type", SCENE_ANT);
			params.putUtfString("island", shellApi.island);
			params.putUtfString("scene", shellApi.sceneName);
			
			shellApi.smartFox.send(new ExtensionRequest(CMD_JOIN_SCENE, params));
		}

		protected function onSFSRoomJoin(event:SFSEvent):void
		{
			if(shellApi.sceneName != "Starcade"){
				if(!viewportOn){
					// if you have joined a scene, start transmitting (if not in a view port)
					shellApi.player.add(new SFAnt());
					if(AppConfig.debug){
						trace("  SFScene joined - transmitting antfarm data...");
					}
				} else {
					// if you are view porting, when you join the new scene (from moving over) - turn on the view port
					viewPortOn();
				}
			}
		}
		
		
		protected function onSFSRoomUserExit(event:SFSEvent):void
		{
			if(!viewportOn && !active){
				if(User(event.params.user).isItMe){
					deactivate();
				}
			}
		}
		
		private function deactivate():void
		{
			if(AppConfig.debug){
				trace("   ---------------------------------");
				trace("   [ ...   SFAnt Deactivated   ... ]");
				trace("   ---------------------------------");
			}
			
			// remove SFAnt component from player
			shellApi.player.remove(SFAnt);
		}
		
		/*********************************************
		 * Utility Methods
		 */
		
		public function stampObj(sfsObject:ISFSObject):ISFSObject{
			// attaches a timestamp per the client clock
			sfsObject.putLong(TIMESTAMP_PLAYERUPDATE_SENT, getTimer() - _startTime + _joinTime);
			return sfsObject;
		}
		
		public var updateFrequency:int;
		
		private var _startTime:Number; // when we joined the scene - per client clock
		private var _joinTime:Number; // when we joined the scene - per server clock
		private var _SFViewportGroup:SFViewportGroup;
		
		private var _antSystem:SFAntSystem;
	}
}