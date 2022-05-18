package game.systems.smartFox
{
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.smartFox.SFScenePlayer;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.SitSleepLoop;
	import game.data.animation.entity.character.Think;
	import game.nodes.smartFox.SFScenePlayerNode;
	import game.scene.template.GameScene;
	import game.scene.template.SFSceneGroup;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.ui.multiplayer.chat.Chat;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	
	/**
	 * System used for multiplayer scenes, handles character entities that share state across server.
	 * @author Bart Henderson
	 */
	public class SFScenePlayerSystem extends ListIteratingSystem
	{
		/**
		 * Updates any entity with the SceneObject component in a scene.
		 */
		
		public static var TRANSMIT_RATE:Number = 0.1; // in seconds
		public static var MY_PLAYER_PREDICTION:Boolean = false; // predicts my sfPlayer entity based on my input
		
		//Drew - Was 20, but caused jittery movement
		public static var SPATIAL_ERROR_THRESH:Number = 100.0;
		public static var SPATIAL_MINOR_THRESH:Number = 10.0;
		
		public static var TEST_TIMEOUT:Boolean = false;
		
		public static const KEY_VELOCITY_X:String = "x";
		public static const KEY_VELOCITY_Y:String = "y";
		public static const KEY_ACCEL_X:String = "a";
		public static const KEY_ACCEL_Y:String = "b";
		
		public static const KEY_MOTION:String = "m";
		public static const KEY_SPATIAL:String = "s";
		public static const KEY_TARGET:String = "g";
		
		public function SFScenePlayerSystem($group:Group)
		{
			super(SFScenePlayerNode, updateNode);
			_group = $group as SFSceneGroup;
			_scene = _group.parent as GameScene;
			super._defaultPriority = SystemPriorities.postUpdate;
		}
		
		private function updateNode($node:SFScenePlayerNode, $time:Number):void{
			
			var sfSpatial:ISFSObject;
			var sfMotion:ISFSObject;
			var sfTarget:ISFSObject;
			
			var spatial:Spatial;
			var motion:Motion;
			var target:MotionTarget;
			var motionControl:MotionControl = _scene.player.get(MotionControl);
			
			var talkingEntity:Entity;
			var targetEntity:Entity;
			var sfPlayer:SFScenePlayer;
			var sfCurPlayer:SFScenePlayer = $node.sfScenePlayer;

			var talkingUser:User;
			var targetUser:User;
			
			// record how long we are holding mouse down on motionControl
			if(motionControl){
				if(motionControl.moveToTarget){
					_moveTime_SEND += $time;
				}
			}
			
			// send my player's coord to server per TRANSMIT_RATE (if the entity is me) -------------------->
			if(sfCurPlayer.user.isItMe && !TEST_TIMEOUT)
			{
				_currentTimeBlock += $time;
				if(_currentTimeBlock >= TRANSMIT_RATE)
				{
					
					_currentTimeBlock = 0.0;
					
					if(motionControl){
						_lastMoveToTarget = motionControl.moveToTarget;
					}
					
					// my player's state
					var sfPlayerState:ISFSObject = new SFSObject();
					
					if(newUpdate(_scene.player))
					{
						
						// my player's spatial
						var mySpatial:Spatial = _scene.player.get(Spatial);
						sfSpatial = new SFSObject();
						sfSpatial.putFloat("x", mySpatial.x);
						sfSpatial.putFloat("y", mySpatial.y);
						
						// save spatial
						var savedSpatial:Spatial = new Spatial(mySpatial.x, mySpatial.y);
						SFScenePlayer(_group.mySFPlayer.get(SFScenePlayer)).last_sent_spatial = savedSpatial;
						
						// my player's motion
						var myMotion:Motion = _scene.player.get(Motion);
						sfMotion = new SFSObject();
						sfMotion.putFloat(KEY_VELOCITY_X, myMotion.velocity.x);
						sfMotion.putFloat(KEY_VELOCITY_Y, myMotion.velocity.y);
						sfMotion.putFloat(KEY_ACCEL_X, myMotion.acceleration.x);
						sfMotion.putFloat(KEY_ACCEL_Y, myMotion.acceleration.y);
						
						// save motion
						var savedMotion:Motion = new Motion();
						savedMotion.velocity.x = myMotion.velocity.x;
						savedMotion.velocity.y = myMotion.velocity.y;
						savedMotion.acceleration.x = myMotion.acceleration.x;
						savedMotion.acceleration.y = myMotion.acceleration.y;
						SFScenePlayer(_group.mySFPlayer.get(SFScenePlayer)).last_sent_motion = savedMotion;
						
						// my player's motionTarget
						target = _scene.player.get(MotionTarget);
						sfTarget = new SFSObject();
						sfTarget.putFloat("x", target.targetX);
						sfTarget.putFloat("y", target.targetY);
						sfTarget.putBool("m", motionControl.moveToTarget);
						sfTarget.putFloat("t", _moveTime_SEND);
						
						
						sfPlayerState.putSFSObject(KEY_SPATIAL, sfSpatial);
						sfPlayerState.putSFSObject(KEY_MOTION, sfMotion);
						
						if(sfTarget){
							sfPlayerState.putSFSObject(KEY_TARGET, sfTarget);
						}
					}

					// send data to server
					if(_group.inSFScene)
						_group.shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERUPDATE, _group.stampObj(sfPlayerState), this.group.shellApi.smartFox.lastJoinedRoom, _group.udpEnabled));
					
					// reset _moveTime_SEND to 0 (now that it's sent)
					_moveTime_SEND = 0;
					
					// send cancel if player is moving and has thought icon
					if(sfCurPlayer.icon != null){
						var fsmControl:FSMControl = _group.shellApi.player.get(FSMControl);
						if(fsmControl.state.type != "stand"){
							// remove thought icon
							sfCurPlayer.icon.group.removeEntity(sfCurPlayer.icon);
							sfCurPlayer.icon = null;
							
							// send cancel packet
							var obj:ISFSObject = new SFSObject();
							obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_CANCEL);
							this.group.shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _group.stampObj(obj), this.group.shellApi.smartFox.lastJoinedRoom));
						}
					}
				}
			}
			
			
			// check if special ability of player has been activated -- transmit if it has
			
			var specialAbilityControl:SpecialAbilityControl = _scene.player.get(SpecialAbilityControl);
			if(specialAbilityControl){
				if(specialAbilityControl.trigger && sfCurPlayer.user.isItMe){
					var sobj:ISFSObject = new SFSObject();
					sobj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_ABILITY);
					this.group.shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _group.stampObj(sobj), this.group.shellApi.smartFox.lastJoinedRoom));
				}
			}
			
			// <------------------------ update player's state on client if entity has updated state_obj in component (happens only when an update is populated)
			
			sfPlayerState = sfCurPlayer.state_obj;
			if(sfPlayerState)
			{
				sfCurPlayer.previousTimeSinceLastPacket = sfCurPlayer.currentTimeSinceLastPacket;
				sfCurPlayer.currentTimeSinceLastPacket = 0;
				
				// check to see if this is a first spatial from a scene's flash state (and position entity on scene load)
				var firstSpatial:Boolean;
				if(sfCurPlayer.last_server_spatial == null){
					firstSpatial = true;
				}
				
				// update sfPlayer's state objects
				sfSpatial = sfPlayerState.getSFSObject(KEY_SPATIAL);
				sfMotion = sfPlayerState.getSFSObject(KEY_MOTION);
				sfTarget = sfPlayerState.getSFSObject(KEY_TARGET);
				
				if(sfSpatial && sfMotion)
				{
					sfCurPlayer.last_server_spatial = new Spatial(sfSpatial.getFloat("x"), sfSpatial.getFloat("y"));
					//Drew - Commented out the motion 'cause of jittery movement
					/*
					sfCurPlayer.last_server_motion = new Motion();
					sfCurPlayer.last_server_motion.velocity.x = sfMotion.getFloat("x");
					sfCurPlayer.last_server_motion.velocity.y = sfMotion.getFloat("y");
					*/
					$node.motionControl.moveToTarget = sfTarget.getBool("m");
					
					if($node.motionControl.moveToTarget){
						$node.motionTarget.targetX = sfTarget.getFloat("x");
						$node.motionTarget.targetY = sfTarget.getFloat("y");
					}

					if(firstSpatial && !sfCurPlayer.user.isItMe){
						$node.spatial.x = sfCurPlayer.last_server_spatial.x;
						$node.spatial.y = sfCurPlayer.last_server_spatial.y;
					}
					
					$node.motion.velocity.x = sfMotion.getFloat(KEY_VELOCITY_X);
					$node.motion.velocity.y = sfMotion.getFloat(KEY_VELOCITY_Y);
					$node.motion.acceleration.x = sfMotion.getFloat(KEY_ACCEL_X);
					$node.motion.acceleration.y = sfMotion.getFloat(KEY_ACCEL_Y);
					
					// show debug visual (blue/green dot) of players correct coordinates per server if applicable
					if(sfCurPlayer.spatial_debug){
						var debugMotion:Motion = sfCurPlayer.spatial_debug.get(Motion);
						debugMotion.x = sfCurPlayer.last_server_spatial.x;
						debugMotion.y = sfCurPlayer.last_server_spatial.y;
						debugMotion.velocity.x = sfMotion.getFloat(KEY_VELOCITY_X);
						debugMotion.velocity.y = sfMotion.getFloat(KEY_VELOCITY_Y);
						debugMotion.acceleration.x = sfMotion.getFloat(KEY_ACCEL_X);
						debugMotion.acceleration.y = sfMotion.getFloat(KEY_ACCEL_Y);
					}
					
					
					// if moveToTarget is found in sfsObject -- then get the approximent time it's been "pressed"
					if($node.motionControl.moveToTarget){
						sfCurPlayer.moveTime_RECIEVE = sfTarget.getFloat("t"); // TODO: add lag
					}
				}
				
				// [DISABLED FOR FALCON -- NOT YET READY]
				/*
				if(!sfCurPlayer.user.isItMe)
				{
					if(sfCurPlayer.last_sent_spatial && sfCurPlayer.last_server_spatial &&
						sfCurPlayer.last_sent_motion && sfCurPlayer.last_server_motion)
					{
						sfCurPlayer.cubicSplineData.posOld.x = sfCurPlayer.last_sent_spatial.x;
						sfCurPlayer.cubicSplineData.posOld.y = sfCurPlayer.last_sent_spatial.y;
						sfCurPlayer.cubicSplineData.posNew.x = sfCurPlayer.last_server_spatial.x;
						sfCurPlayer.cubicSplineData.posNew.y = sfCurPlayer.last_server_spatial.y;
						sfCurPlayer.cubicSplineData.velOld.x = sfCurPlayer.last_sent_motion.velocity.x;
						sfCurPlayer.cubicSplineData.velOld.y = sfCurPlayer.last_sent_motion.velocity.y;
						sfCurPlayer.cubicSplineData.velNew.x = sfCurPlayer.last_server_motion.velocity.x;
						sfCurPlayer.cubicSplineData.velNew.y = sfCurPlayer.last_server_motion.velocity.y;
						sfCurPlayer.cubicSplineData.recalculate();
						$node.motion.pause = true;
						$node.motionControl.moveToTarget = false;
					}
				}
				*/
				
				// clear spent player state
				sfCurPlayer.state_obj = null;
				
			}
			else
			{
				sfCurPlayer.currentTimeSinceLastPacket += $time;
				
				// play out the remainder of missing time for moveToTarget (to improve accuracy)
				if(sfCurPlayer.moveTime_RECIEVE > 0)
					sfCurPlayer.moveTime_RECIEVE -= $time;
				
				if(sfCurPlayer.moveTime_RECIEVE > 0){
					// extend moveToTarget
					$node.motionControl.moveToTarget = true;
				} else {
					// terminate moveToTarget
					$node.motionControl.moveToTarget = false;
				}
			}
			
			
			//trace($node.spatial.x+":"+$node.spatial.y);
			
			// --------- ERROR CHECKING ----------
			
			// override motion authoritively - compensates for innacuracy from target update
			if(sfCurPlayer.last_server_spatial && $node.spatial)
			{
				if(!sfCurPlayer.user.isItMe || SFSceneGroup.DEBUG)
				{
					//Drew - Commented out the if block 'cause of jittery movement
					//if(!this.cubicSplineMovement($node, $time))
					//{
						//trace("Not splining Entity", Id($node.entity.get(Id)).id);
						var spatial_distance:Number = spatialDistance(sfCurPlayer.last_server_spatial, $node.spatial);
						//trace($node.spatial.x+":"+$node.spatial.y+" vs "+sfCurPlayer.last_server_spatial.x+":"+sfCurPlayer.last_server_spatial.y+" = "+spatial_distance);
						if(spatial_distance > SPATIAL_ERROR_THRESH )
						{
							//if ( sfCurPlayer.previousTimeSinceLastPacket < 1 ) {
							/*sfCurPlayer.lerpFrames++;
							
							var dist:Number = Math.abs( $node.spatial.x - sfCurPlayer.last_server_spatial.x );
							var lerpSteps:Number = (dist)/SPATIAL_ERROR_THRESH;
							if ( lerpSteps > 10 ) {
								lerpSteps = 10;
							} 
							var rate:Number = sfCurPlayer.lerpFrames/lerpSteps;*/
							
							/*
							var rate:Number = sfCurPlayer.previousTimeSinceLastPacket;
							if ( rate > 0.99 ) {
								rate = 1;
							}
							
							$node.motion.x = (1-rate)*($node.motion.x ) + rate*( sfCurPlayer.last_server_spatial.x + sfCurPlayer.last_server_motion.velocity.x*sfCurPlayer.previousTimeSinceLastPacket);
							$node.motion.y = (1-rate)*($node.motion.y ) + rate*( sfCurPlayer.last_server_spatial.y + sfCurPlayer.last_server_motion.velocity.y*sfCurPlayer.previousTimeSinceLastPacket);	
							*/
							
							//}
							
							//$node.motion.velocity.x = sfCurPlayer.last_server_motion.velocity.x;
							//$node.motion.velocity.y = sfCurPlayer.last_server_motion.velocity.y;
							
							$node.motion.x = sfCurPlayer.last_server_spatial.x;
							$node.motion.y = sfCurPlayer.last_server_spatial.y;

							// force motion.xy


						}
						else if(spatial_distance > SPATIAL_MINOR_THRESH)
						{
							//sfCurPlayer.lerpFrames = 0;
							if( !$node.motionControl.moveToTarget )
							{
								$node.motionControl.moveToTarget = true;
								$node.motionTarget.targetX = sfCurPlayer.last_server_spatial.x;
								$node.motionTarget.targetY = sfCurPlayer.last_server_spatial.y;
							}
						} else {
							//sfCurPlayer.lerpFrames = 0;
						}
					//}
				}
			}
			
			
			// <------------------------ update player's actions on client if entity has any action_objs in component
			
			if(sfCurPlayer.action_objs.length > 0){
				var entity:Entity;
				
				// if the actions are mine, show it on my player entity, not my SFPlayer (as it is hidden)
				if(_group.mySFPlayer == $node.entity){
					entity = _group.shellApi.player;
				} else {
					entity = $node.entity;
				}
				
				for(var a:int = 0; a < sfCurPlayer.action_objs.length; a++){
					switch(sfCurPlayer.action_objs[a].getUtfString(SFSceneGroup.KEY_ACTION_TYPE)){
						case SFSceneGroup.TYPE_PLAYER_STATEMENT:
							Dialog(entity.get(Dialog)).allowOverwrite = true;
							Dialog(entity.get(Dialog)).say(sfCurPlayer.action_objs[a].getUtfString(SFSceneGroup.KEY_MSG));
							break;
						case SFSceneGroup.TYPE_PLAYER_EMOTE:
							try{
								if( _group.emotes.validEmoteStates.indexOf( CharUtils.getStateType(entity) ) != -1 ){
									var animClass:Class = ClassUtils.getClassByName("game.data.animation.entity.character."+sfCurPlayer.action_objs[a].getUtfString(SFSceneGroup.KEY_MSG));
									CharUtils.setAnim(entity, animClass, false, 0, 0, true);
									// allow character to move if a looping animation
									
									if(animClass == SitSleepLoop){
										FSMControl(entity.get(FSMControl)).active = true;
										CharacterMovement(entity.get(CharacterMovement)).active = true;
									}
								}
							} catch(e:Error){
								trace("###### SFS Emote Error: no class defined in received animation string.");
							}
							break;
						case SFSceneGroup.TYPE_PLAYER_ABILITY:
							CharUtils.triggerSpecialAbility($node.entity,sfCurPlayer.user.isItMe);
							break;
						case SFSceneGroup.TYPE_PLAYER_MSG_STRING:
							talkingUser = this.group.shellApi.smartFox.userManager.getUserById(sfCurPlayer.action_objs[a].getInt(SFSceneGroup.KEY_USER_ID));
							targetUser = this.group.shellApi.smartFox.userManager.getUserById(sfCurPlayer.action_objs[a].getInt(SFSceneGroup.KEY_TARGET_USER_ID));
							
							if(talkingUser.isItMe){
								talkingEntity = _group.shellApi.player;
								sfPlayer = _group.mySFPlayer.get(SFScenePlayer);
							} else {
								talkingEntity = _group.getSFPlayerByUsername(talkingUser.name);
								sfPlayer = talkingEntity.get(SFScenePlayer);
							}
							
							if(targetUser.isItMe){
								targetEntity = _group.shellApi.player;
							} else {
								targetEntity = _group.getSFPlayerByUsername(targetUser.name);
							}
							
							CharUtils.faceTargetEntity(talkingEntity, targetEntity);
							
							//sfPlayer.last_msg = sfCurPlayer.action_objs[a].getUtfString(SFSceneGroup.KEY_MSG);
							
							Dialog(entity.get(Dialog)).allowOverwrite = true;
							Dialog(entity.get(Dialog)).say(sfCurPlayer.action_objs[a].getUtfString(SFSceneGroup.KEY_MSG));
							break;
						case SFSceneGroup.TYPE_PLAYER_CHAT:
							//trace(sfCurPlayer.action_objs[a].getDump());
							talkingUser = this.group.shellApi.smartFox.userManager.getUserById(sfCurPlayer.action_objs[a].getInt(SFSceneGroup.KEY_USER_ID));
							targetUser = this.group.shellApi.smartFox.userManager.getUserById(sfCurPlayer.action_objs[a].getInt(SFSceneGroup.KEY_TARGET_USER_ID));
							
							if(talkingUser.isItMe){
								talkingEntity = _group.shellApi.player;
								sfPlayer = _group.mySFPlayer.get(SFScenePlayer);
							} else {
								talkingEntity = _group.getSFPlayerByUsername(talkingUser.name);
								sfPlayer = talkingEntity.get(SFScenePlayer);
							}
							
							if(targetUser.isItMe){
								targetEntity = _group.shellApi.player;
							} else {
								targetEntity = _group.getSFPlayerByUsername(targetUser.name);
							}
							
							// face characters at each other
							CharUtils.faceTargetEntity(targetEntity, talkingEntity);
							CharUtils.faceTargetEntity(talkingEntity, targetEntity);
							
							sfPlayer.do_not_disturb = false;
							sfPlayer.last_msg_obj = sfCurPlayer.action_objs[a].getSFSObject(Chat.KEY_CHAT_MESSAGES);
							var msg:String = sfPlayer.last_msg_obj.getUtfString("chat_message");
							var ani:String = sfPlayer.last_msg_obj.getUtfString("chat_ani");

							FSMControl(entity.get(FSMControl)).active = true;
							CharacterMovement(entity.get(CharacterMovement)).active = true;
							
							// override character state
							CharUtils.setState($node.entity, CharacterState.STAND);
							
							if(msg){
								Dialog(entity.get(Dialog)).allowOverwrite = true;
								Dialog(entity.get(Dialog)).say(msg);
							}
							
							// if animation, play animation
							if(ani && ani != ""){
								var animation:Class = ClassUtils.getClassByName("game.data.animation.entity.character."+ani);
								if(animation)
									CharUtils.setAnim(entity, animClass, false, 0, 0, true);
							}
							
							break;
						case SFSceneGroup.TYPE_PLAYER_THINK:
							talkingUser = this.group.shellApi.smartFox.userManager.getUserById(sfCurPlayer.action_objs[a].getInt(SFSceneGroup.KEY_USER_ID));
							if(talkingUser.isItMe){
								talkingEntity = _group.shellApi.player;
								sfPlayer = _group.mySFPlayer.get(SFScenePlayer);
							} else {
								talkingEntity = _group.getSFPlayerByUsername(talkingUser.name);
								sfPlayer = talkingEntity.get(SFScenePlayer);
							}
							sfPlayer.do_not_disturb = true;
							
							// perform a hard update on character location
							$node.motion.x = sfCurPlayer.last_server_spatial.x;
							$node.motion.y = sfCurPlayer.last_server_spatial.y;
							$node.spatial.x = sfCurPlayer.last_server_spatial.x;
							$node.spatial.y = sfCurPlayer.last_server_spatial.y;
							
							// stop avatar from moving
							$node.motion.zeroAcceleration();
							$node.motion.zeroMotion();
							
							CharUtils.setAnim(entity, Think);
							
							break;

						case SFSceneGroup.TYPE_PLAYER_CANCEL:
							talkingUser = this.group.shellApi.smartFox.userManager.getUserById(sfCurPlayer.action_objs[a].getInt(SFSceneGroup.KEY_USER_ID));
							if(talkingUser.isItMe){
								talkingEntity = _group.shellApi.player;
								sfPlayer = _group.mySFPlayer.get(SFScenePlayer);
							} else {
								talkingEntity = _group.getSFPlayerByUsername(talkingUser.name);
								sfPlayer = talkingEntity.get(SFScenePlayer);
							}
							sfPlayer.do_not_disturb = false;
							
							FSMControl(entity.get(FSMControl)).active = true;
							CharacterMovement(entity.get(CharacterMovement)).active = true;
							
							// override character state
							CharUtils.setState($node.entity, CharacterState.STAND);
							
							break;
						case SFSceneGroup.TYPE_PLAYER_SHARED_OBJ:
							talkingUser = this.group.shellApi.smartFox.userManager.getUserById(sfCurPlayer.action_objs[a].getInt(SFSceneGroup.KEY_USER_ID));
							
							if(talkingUser.isItMe){
								if(SFSceneGroup.DEBUG){
									talkingEntity = _group.mySFPlayer;
								}
							} else {
								talkingEntity = _group.getSFPlayerByUsername(talkingUser.name);
							}
							
							if(talkingEntity){
								var sharedObject:Object = $node.sfScenePlayer.action_objs[a].getSFSObject(SFSceneGroup.KEY_GEN_OBJECT).toObject();
								_group.objectRecieved.dispatch(sharedObject, talkingEntity);
							}
		
							break;
					}
					
					sfCurPlayer.action_objs.splice(a, 1);
					a--;
				}
			}
		}
		
		private function cubicSplineMovement(node:SFScenePlayerNode, time:Number):Boolean
		{
			return false;
			//trace("Spline time =", node.sfScenePlayer.cubicSplineData.time);
			if(node.sfScenePlayer.cubicSplineData.time < node.sfScenePlayer.previousTimeSinceLastPacket)
			{
				node.sfScenePlayer.cubicSplineData.time += time;
				if(node.sfScenePlayer.cubicSplineData.time <= node.sfScenePlayer.previousTimeSinceLastPacket)
				{
					node.motion.x = node.sfScenePlayer.cubicSplineData.x;
					node.motion.y = node.sfScenePlayer.cubicSplineData.y;
					return true;
				}
				else
				{
					node.motion.pause = false;
				}
			}
			return false;
		}
		
		private function newUpdate($entity:Entity):Boolean{
			var sendNewUpdate:Boolean = false;
			
			var new_spatial:Spatial = $entity.get(Spatial);
			var new_motion:Motion = $entity.get(Motion);
			var last_spatial:Spatial = SFScenePlayer(_group.mySFPlayer.get(SFScenePlayer)).last_sent_spatial;
			var last_motion:Motion = SFScenePlayer(_group.mySFPlayer.get(SFScenePlayer)).last_sent_motion;
			
			
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
		
		private function showIconOverEntity($node:SFScenePlayerNode, $entity:Entity, $bitmapData:BitmapData, $button:Boolean = false, $handler:Function = null):Entity{
			
			var sfCurPlayer:SFScenePlayer = $node.sfScenePlayer;

			// remove current icon if one present
			if(sfCurPlayer.icon != null){
				sfCurPlayer.icon.group.removeEntity(sfCurPlayer.icon);
			}
			
			// play thinking animation if not already
			if(sfCurPlayer.icon == null){
				CharUtils.setAnim($entity, Think);
			}
			
			// allow character to move
			FSMControl($entity.get(FSMControl)).active = true;
			CharacterMovement($entity.get(CharacterMovement)).active = true;
			
			// put think icon over character
			var bitmapDataClone:BitmapData = $bitmapData.clone();
			var bitmap:Bitmap = new Bitmap(bitmapDataClone);
			var clip:MovieClip = new MovieClip();
			clip.addChild(bitmap);
			
			var icon:Entity;
			
			if(!$button){
				icon = EntityUtils.createSpatialEntity(_group.scene, clip, _group.scene.hitContainer);
			} else {
				icon = ButtonCreator.createButtonEntity(clip, _group.scene, $handler, _group.scene.hitContainer, null, null, false);
			}
			
			var entSpatial:Spatial = $entity.get(Spatial);
			var thkSpatial:Spatial = icon.get(Spatial);
			
			thkSpatial.x = entSpatial.x - 24;
			thkSpatial.y = entSpatial.y - thkSpatial.height / 2 - 80;
			
			// store icon entity in sfScenePlayer
			sfCurPlayer.icon = icon;
			
			return icon;
		}
		
		private function spatialDistance($spatial1:Spatial, $spatial2:Spatial):Number{
			return Math.sqrt( ($spatial2.x - $spatial1.x)*($spatial2.x - $spatial1.x) + ($spatial2.y - $spatial1.y)*($spatial2.y - $spatial1.y) );
		}
		
		private var _currentTimeBlock:Number = 0.0;
		
		private var _moveTime_SEND:Number = 0.0;
		
		private var _lastMoveToTarget:Boolean = false;
		
		private var _group:SFSceneGroup;
		private var _scene:GameScene;
	}
}