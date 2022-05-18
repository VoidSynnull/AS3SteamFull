package game.systems.smartFox
{
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.group.Group;
	
	import game.components.smartFox.SFScenePlayer;
	import game.nodes.smartFox.SFSceneStateNode;
	import game.scene.template.GameScene;
	import game.scene.template.SFSceneGroup;
	import game.systems.SystemPriorities;
	
	public class SFSceneStateSystem extends ListIteratingSystem
	{
		/**
		 * Manages and parses the smartfox scene states received from the server.
		 * Puts sfsObjects into their respective entity components.
		 */
		
		public function SFSceneStateSystem($group:Group)
		{
			super(SFSceneStateNode, updateNode);
			super._defaultPriority = SystemPriorities.update;
			_group = $group as SFSceneGroup;
			_scene = _group.parent as GameScene;
		}
		
		private function updateNode($node:SFSceneStateNode, $time:Number):void{
			if(onTime($node, $time)){
				
				// get next state packet
				var sceneState:ISFSObject = $node.sfSceneState.state_queue.shift();
				parseSFSceneState(sceneState);
				
				var lastExecutedTS:Number = sceneState.getLong(SFSceneGroup.TIMESTAMP_SCENE_CLOCK);
				
				// check for action packets
				for(var p:int = 0; p < $node.sfSceneState.action_queue.length; p++){
					var actionTS:Number = $node.sfSceneState.action_queue[p].getLong(SFSceneGroup.TIMESTAMP_SCENE_CLOCK);
					
					// if action packets are within time of the last update packet, execute them and remove them from queue
					if(actionTS < lastExecutedTS){
						parseSFSceneAction($node.sfSceneState.action_queue[p]);
						$node.sfSceneState.action_queue.splice(p, 1);
						p--;
					}
				}
				
				// reset timers
				_deltaP += (_group.updateFrequency / 1000); // add the debted time to the next cycle (so it doesn't build on itself upon remainders)
				_packetTime = 0.0; // for debug use
				
				// if necessary, shorten _deltaP to gently speed up the packet queue (if congestion has occured)
				if($node.sfSceneState.state_queue.length > 3){
					_deltaP -= 0.05;
				} else if($node.sfSceneState.state_queue.length > 1){
					_deltaP -= 0.005;
				}
			}
			
			if($node.sfSceneState.state_queue.length == 0){
				// if no packets are in queue - stop the clock temporarily
				_clockRunning = false;
			} else if(!_clockRunning){
				// if packets and the clock has stopped, start the clock
				_clockRunning = true; 
			}
		}
		
		/**
		 * This method is to ensure that every packet is processed as close to in sync with the server's update time.
		 */
		private function onTime($node:SFSceneStateNode, $time:Number):Boolean{
			if(_clockRunning){
				// deduct from debted time
				_deltaP -= $time;
				_packetTime += $time;
			}
			
			if($node.sfSceneState.state_queue.length > 0 && group.shellApi.smartFox.isConnected && group.shellApi.smartFox.lastJoinedRoom){
				// get statistics
				var userCount:int = group.shellApi.smartFox.lastJoinedRoom.userCount - 1;
				group.shellApi.log("Currently in scene: '"+group.shellApi.smartFox.lastJoinedRoom.name+"' with "+userCount+" other players. :: Your latency is "+_group.lag+"ms");
				group.shellApi.log("Update packets in queue: "+($node.sfSceneState.state_queue.length - 1)+" :: Action packets in queue: "+$node.sfSceneState.action_queue.length+" :: ("+optimalQueue($node.sfSceneState.state_queue.length - 1)+")", null, false);
				
				_nullPacketReturned;
				
				if(!$node.sfSceneState.state_queue[0].containsKey(SFSceneGroup.PREFIX_USER+group.shellApi.smartFox.mySelf.name)){
					_nullPacketReturned = true;
					group.shellApi.log("WARN: You are not sending out packets.", null, false);
				} else {
					_nullPacketReturned = false;
				}
				
				// if low framerate ($time > updateFreq) slice packets in queue to catch up
				var skip_packet_num:int = Math.floor(($time*1000) / _group.updateFrequency);
				if(skip_packet_num > 0){
					// slice up to the earliest packet in queue
					if(skip_packet_num >= $node.sfSceneState.state_queue.length){
						skip_packet_num = $node.sfSceneState.state_queue.length - 1;
					}
					
					for(var s:int = 0; s < skip_packet_num; s++){
						if(!$node.sfSceneState.state_queue[s].getBool(SFSceneGroup.CMD_FLASH_STATE)){
							// if not a flash state packet - remove packet
							$node.sfSceneState.state_queue.splice(s, 1);
							s--;
							skip_packet_num--;
						} else {
							// retain flash packet
						}
					}
				}
				
				if(_nullPacketTime > 0.0){
					_nullPacketTime -= $time;
					if(_nullPacketTime < 0){
						_nullPacketTime = 0;
					}
					_group.updateSignalHUD((_nullPacketTimeMax - _nullPacketTime)/_nullPacketTimeMax);
				} else {
					_group.updateSignalHUD(1);
				}
				
				if(_deltaP <= 0.0){
					// run packet and reset _deltaP
					//trace("frametime: "+$time*1000+"ms --- since last packet run: "+Math.floor(_packetTime * 1000)+"ms :: time debt: "+_deltaP);
					return true;
				}
				
			} else if($node.sfSceneState.state_queue.length == 0 && group.shellApi.smartFox.isConnected && group.shellApi.smartFox.lastJoinedRoom){
				// lag on received packets
				_nullPacketTime += $time;
				if(_nullPacketTime > _nullPacketTimeMax){
					_nullPacketTime = _nullPacketTimeMax;
				}
				_group.updateSignalHUD((_nullPacketTimeMax - _nullPacketTime)/_nullPacketTimeMax);
			} else {
				// disconnected from room or server
				if(!group.shellApi.smartFox.lastJoinedRoom){
					//group.shellApi.log("Left room!");
				}
				if(!group.shellApi.smartFox.isConnected){
					//group.shellApi.log("Not connected!");
				}
			}
			
			return false;
		}
		
		private function optimalQueue($queueLength:int):String{
			if($queueLength <= 1){
				return "optimal";
			} else if($queueLength <= 3){
				return "congested slightly";
			} else {
				return "congested greatly";
			}
		}
		
		private function parseSFSceneState($sfSceneState:ISFSObject):void{
			// parse the entire scene state sfsObject
			var keys:Array = $sfSceneState.getKeys();
			
			// find SFScenePlayers
			for each(var key:String in keys){
				// any object key with the prefix "u_" is a player
				if(key.substr(0,SFSceneGroup.PREFIX_USER.length) == SFSceneGroup.PREFIX_USER){
					updateSFScenePlayer($sfSceneState.getLong(SFSceneGroup.TIMESTAMP_SCENE_CLOCK), key.substr(SFSceneGroup.PREFIX_USER.length), $sfSceneState.getSFSObject(key));
				}
			}
		}
		
		private function parseSFSceneAction($sfSceneAction:ISFSObject):void{
			try{
				var user:User = group.shellApi.smartFox.userManager.getUserById($sfSceneAction.getInt(SFSceneGroup.KEY_USER_ID));
				if(user){
					var sfPlayerEntity:Entity = _group.getSFPlayerByUsername(user.name);
					
					if(sfPlayerEntity){
						SFScenePlayer(sfPlayerEntity.get(SFScenePlayer)).action_objs.push($sfSceneAction);
					}
				}
			} catch(e:Error) {
				
			}
		}
		
		private function updateSFScenePlayer($timeStamp:Number, $userName:String, $sfPlayerState:ISFSObject):void{
			// get respective entity
			try{
				
				// if packet is not empty
				if($sfPlayerState.size() > 0){
					
					var sfPlayerEntity:Entity = _group.getSFPlayerByUsername($userName);
					
					// if no entity found, create new player entity (used when entering a room with players already in it)
					if(!sfPlayerEntity && $userName != null)
						sfPlayerEntity = _group.createPlayer(group.shellApi.smartFox.userManager.getUserByName($userName), $sfPlayerState);
					
					// place server timestamp 
					if($sfPlayerState){
						$sfPlayerState.putLong(SFSceneGroup.TIMESTAMP_SCENE_CLOCK, $timeStamp);
						//$sfPlayerState.putInt("lag", _lag);
					}
					
					// place the update sfsObject into the respective SFScenePlayer's component (to be processed by the SFScenePlayerSystem)
					if(sfPlayerEntity){
						SFScenePlayer(sfPlayerEntity.get(SFScenePlayer)).state_obj = $sfPlayerState;
					}
					
				}
				
			} catch(e:Error){
				
			}
		}
		
		private function updateSFSceneObject($sfObjectState:ISFSObject):void{
			// place the new sfsObject into the respective SFSceneObject's component (to be processed by the SFSceneObjectSystem)
		}
		
		public override function removeFromEngine(systemManager:Engine):void{
			group.shellApi.log(""); // clear log of data
			super.removeFromEngine(systemManager);
		}
		
		
		private var _group:SFSceneGroup;
		private var _scene:Group;
		private var _lag:int;
		
		private var _deltaP:Number = 0.0; // timer for packet spacing
		private var _packetTime:Number = 0.0; // for debugging
		private var _clockRunning:Boolean = false; // is turned on when packets are in queue
		private var _nullPacketReturned:Boolean; // if no player packets are returned
		private var _nullPacketTime:Number = 0.0;
		private var _nullPacketTimeMax:Number = 5.0;
	}
}