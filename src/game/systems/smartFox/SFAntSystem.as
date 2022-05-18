package game.systems.smartFox
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.smartFox.SFAnt;
	import game.nodes.smartFox.SFAntNode;
	import game.scene.template.SFAntGroup;
	
	/**
	 * System to accompany SFAntGroup, used for 'Ant Farm' testing of multiplayer.
	 * @author Bart Henderson
	 */
	public class SFAntSystem extends ListIteratingSystem
	{
		public static var TRANSMIT_RATE:Number = 0.1; // in seconds
		
		public function SFAntSystem($smartFox:SmartFox, $group:SFAntGroup)
		{
			_smartFox = $smartFox;
			_group = $group;
			super(SFAntNode, updateNode);
		}
		
		private function updateNode($node:SFAntNode, $time:Number):void{
			var sfSpatial:ISFSObject;
			var sfMotion:ISFSObject;
			var sfTarget:ISFSObject;
			
			var spatial:Spatial;
			var motion:Motion;
			var target:MotionTarget;
			var motionControl:MotionControl = $node.entity.get(MotionControl);
			
			// record how long we are holding mouse down on motionControl
			if(motionControl.moveToTarget){
				_moveTime_SEND += $time;
			}
			
			_currentTimeBlock += $time;
			if(_currentTimeBlock >= TRANSMIT_RATE){
				_currentTimeBlock = 0.0;
				
				_lastMoveToTarget = $node.motionControl.moveToTarget;
				
				// my player's state
				var sfPlayerState:ISFSObject = new SFSObject();
				
				if(newUpdate($node.entity)){
					// my player's spatial
					var mySpatial:Spatial = $node.entity.get(Spatial);
					sfSpatial = new SFSObject();
					sfSpatial.putFloat("x", mySpatial.x);
					sfSpatial.putFloat("y", mySpatial.y);
					
					// save spatial
					var savedSpatial:Spatial = new Spatial(mySpatial.x, mySpatial.y);
					SFAnt($node.entity.get(SFAnt)).last_sent_spatial = savedSpatial;
					
					// my player's motion
					var myMotion:Motion = $node.entity.get(Motion);
					sfMotion = new SFSObject();
					sfMotion.putFloat(SFScenePlayerSystem.KEY_VELOCITY_X, myMotion.velocity.x);
					sfMotion.putFloat(SFScenePlayerSystem.KEY_VELOCITY_Y, myMotion.velocity.y);
					sfMotion.putFloat(SFScenePlayerSystem.KEY_ACCEL_X, myMotion.acceleration.x);
					sfMotion.putFloat(SFScenePlayerSystem.KEY_ACCEL_Y, myMotion.acceleration.y);
					
					// save motion
					var savedMotion:Motion = new Motion();
					savedMotion.velocity.x = myMotion.velocity.x;
					savedMotion.velocity.y = myMotion.velocity.y;
					savedMotion.acceleration.x = myMotion.acceleration.x;
					savedMotion.acceleration.y = myMotion.acceleration.y;
					SFAnt($node.entity.get(SFAnt)).last_sent_motion = savedMotion;
					
					// my player's motionTarget
					target = $node.entity.get(MotionTarget);
					sfTarget = new SFSObject();
					sfTarget.putFloat("x", target.targetX);
					sfTarget.putFloat("y", target.targetY);
					sfTarget.putBool("m", motionControl.moveToTarget);
					sfTarget.putFloat("t", _moveTime_SEND);
					
					sfPlayerState.putSFSObject(SFScenePlayerSystem.KEY_SPATIAL, sfSpatial);
					sfPlayerState.putSFSObject(SFScenePlayerSystem.KEY_MOTION, sfMotion);
					
					if(sfTarget){
						sfPlayerState.putSFSObject(SFScenePlayerSystem.KEY_TARGET, sfTarget);
					}
				}
				
				// send data to server
				_smartFox.send(new ExtensionRequest(SFAntGroup.CMD_PLAYERUPDATE, _group.stampObj(sfPlayerState), _smartFox.lastJoinedRoom));
				
				// reset _moveTime_SEND to 0 (now that it's sent)
				_moveTime_SEND = 0;
			}
		}
		
		private function newUpdate($entity:Entity):Boolean{
			var sendNewUpdate:Boolean = false;
			
			var new_spatial:Spatial = $entity.get(Spatial);
			var new_motion:Motion = $entity.get(Motion);
			var last_spatial:Spatial = SFAnt($entity.get(SFAnt)).last_sent_spatial;
			var last_motion:Motion = SFAnt($entity.get(SFAnt)).last_sent_motion;
			
			
			
			// confirm spatial change
			if(last_spatial && last_motion){
				if(new_spatial.x != last_spatial.x || new_spatial.y != last_spatial.y){
					sendNewUpdate = true;
				}
				
				// confirm velocity change
				if(new_motion.velocity.x != last_motion.velocity.x || new_motion.velocity.y != last_motion.velocity.y){
					sendNewUpdate = true;
				}
				
				// confirm accel change
				if(new_motion.acceleration.x != last_motion.acceleration.x || new_motion.acceleration.y != last_motion.acceleration.y){
					sendNewUpdate = true;
				}
			} else {
				sendNewUpdate = true;
			}
			
			return sendNewUpdate;
			
		}
		
		
		private var _smartFox:SmartFox;
		private var _group:SFAntGroup;
		
		private var _currentTimeBlock:Number = 0.0;
		private var _moveTime_SEND:Number = 0.0;
		private var _lastMoveToTarget:Boolean = false;
		
	}
}