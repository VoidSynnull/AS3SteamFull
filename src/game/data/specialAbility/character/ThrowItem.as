// Used by:
// Card "divination_dust" on arab3 island using item an_divination_sand (throw bomb and get genie smoke clouds)
// Card "bonbons" on timmy island using item bonbons (throw bonbons)
// Card 2552 using item limited_comics_coconut (throw coconut which bounces off of NPC)
// Card 2600 using item limited_dowk_pumpkin_bazooka (shoot pumpkin from bazooka)
// Card 2668 using item limited_ghd_boot (throw boot which lands on NPC's head)
// Card 2671 using item limited_caprisun_blower, limited_caprisun_blower_mobile (shoots paint balloon which colorizes NPC and displays popup animation)
// Card 2741 using item ad_pranks_pie (throw pie which turns NPC yellow with confetti blast)
// Card 3252 using item p_candy_cane-on (shoot snowball out of candy cane)
// Card 3335 using item cuusoo_white_rabbit (throw carrot and turn NPC pink with confetti bomb particles)
// Card 3467 using item 8birthdaycake (throw cake which turns NPC into pixelated pig)

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.FlyingPlatformHealth;
	import game.components.entity.character.Character;
	import game.components.entity.character.part.MetaPart;
	import game.components.hit.CurrentHit;
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.StandNinja;
	import game.data.animation.entity.character.Throw;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.GameScene;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	
	/**
	 * Throw item from hand (can optionally interact with NPCs if use npc_actions action chain)
	 * 
	 * Optional params:
	 * actionClass:			Class		Class used for avatar action (default is Throw)
	 * triggerLabel			String		Animation label that triggers throwing (default is "trigger")
	 * offsetX				Number		Initial x offset of thrown object (default is 0)
	 * offsetY				Number		Initial y offset of thrown object (default is 0)
	 * speedX				Number		Initial horizontal speed (default is random between 200 to 250); need to also pass non-zero speedY to override
	 * speedY				Number		Initial verical speed (default is random between -200 to -300); need to also pass non-zero speedX to override
	 * rotationSpeed		Number		Initial rotation speed (default is 50)
	 * gravity				Number		Initial rotation speed (default is 700)
	 * swfPath				String		Path to swf file of thrown object (if not provided, the item that the avatar is currently holding is thrown)
	 * friction				Number		Horizontal trajectory friction (default is 0.1)
	 * hideInHand			Boolean		Hide item in hand when throwing (default is true)
	 * applyCollision		Boolean		Add colliders to thrown object (default is false)
	 * bounce				Boolean		Object bounces off NPC (default is false)
	 * boomerang			Boolean		Object bounces off NPC and returns (default is false)
	 * knock				Boolean		NPC plays hurt animation and slides away (default is false)
	 * responderClass		Class		Landing responder class
	 * launchSound			String		Sound to play when object is launched
	 * popupPath			String		Path to optional popup animation
	 * colors				Array		Color array or color values for colorizing NPC
	 */
	public class ThrowItem extends SpecialAbility
	{
		/**
		 * Activate special ability 
		 * @param node
		 */
		override public function activate(node:SpecialAbilityNode):void
		{
			if(_loaded && super.data.isActive && _isFlying == false)
				super.data.isActive = false;
			// if not currently active and no popup present
			if (!super.data.isActive)
			{
				var currentState:String = CharUtils.getStateType(entity)
				if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
				{
					// make active
					super.setActive(true);
					
					// set up responder class, if any
					if(_responderClass)
					{
						_responderClassObject = new _responderClass();
						_responderClassObject.init(GameScene(super.group).hitContainer, super.group);
					}
					
					// don't scale loaded file if loading external file
					var scale:Boolean = false;
					var path:String;
					
					// If no swfPath parameter specified, then get the swf's file path for the current player avatar item
					if ((_swfPath == null) || (_swfPath == ""))
					{
						// will need to scale thrown item to match that of avatar's scale
						scale = true;
						// get item part
						var metaPart:MetaPart = CharUtils.getPart(super.entity, CharUtils.ITEM).get(MetaPart);
						// construct path to part
						path = "entity/character/" + metaPart.currentData.partId + "/" + metaPart.currentData.asset + ".swf";
					}
					else
					{
						// if swf path specified
						path = _swfPath;
						
						// if multiple color values provided, then get random position in color array and append to path
						if (_colors.length != 0)
						{
							var pos:int = _swfPath.indexOf(".swf");
							while (true)
							{
								var color:int = Math.floor(_colors.length * Math.random());
								if (color != _currentColor)
								{
									_currentColor = color;
									if(_multipleSkinParts)
										_suffix = color;
									break;
								}
							}
							path = _swfPath.substr(0,pos) + (_currentColor + 1) + ".swf";
						}
					}
					_loaded = false;
					// load file and wait for completion
					super.loadAsset(path, loadComplete, scale);
					
					if (_landingSwfPath != null) {
						// load landing file
						loadAsset(_landingSwfPath, loadLandingComplete);
					}
				}
			}
		}
		/**
		 * When landing file is loaded
		 * @param clip loaded MovieClip
		 * @param scale Boolean
		 */
		private function loadLandingComplete(clip:MovieClip):void {
			// return if no clip
			if (clip == null) {
				trace("ERROR: landing clip not found");
				return;
			}
			_landingClip = clip;
			_landingClip.visible = false;
		}

		
		/**
		 * When file is loaded
		 * @param clip loaded MovieClip
		 * @param scale Boolean
		 */
		private function loadComplete(clip:MovieClip, scale:Boolean = false):void
		{
			// return if no clip
			if (clip == null)
				return;
			
			_clip = clip;
			
			// if need to scale loaded part (needed if using item in hand)
			if (scale)
			{
				clip.scaleX = super.entity.get(Spatial).scaleX;
				clip.scaleY = super.entity.get(Spatial).scaleY;
			}
			// trigger throw animation
			CharUtils.setAnim(super.entity, _actionClass);
			
			// wait for label to actually throw and leave hand
			CharUtils.getTimeline(super.entity).handleLabel(_triggerLabel, throwItem);
			
			//set loaded
			_loaded = true;
		}
		
		/**
		 * Throw item from hand when reach trigger label 
		 */
		private function throwItem():void
		{
			// start counter
			_counter = 0;
			_startTime = getTimer();
			
			// set isFlying flag to true now that the item is flying
			_isFlying = true;
			
			// remove function from rig
			CharUtils.getRigAnim(super.entity).ended.remove(throwItem);
			
			// hide item in hand, if requested
			if (_hideInHand)
			{
				var itemPart:Entity = CharUtils.getPart(super.entity, CharUtils.ITEM);
				itemPart.get(Display).visible = false;
			}
			
			// create entity to be thrown
			_thrownEntity = new Entity();
			var display:Display = new Display(_clip, super.entity.get(Display).container);
			_thrownEntity.add(display);
			
			// get hand and character spatial components
			var handSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charSpatial:Spatial = super.entity.get(Spatial);
			
			// remember starting y position
			_startY = charSpatial.y;
			
			// setup initial position
			var xPos:Number = charSpatial.x - (handSpatial.x * charSpatial.scale) + _offsetX;
			var yPos:Number = _startY + (handSpatial.y * charSpatial.scale) + _offsetY;
			_dir = 1;
			
			// check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			// flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				_dir = -1;
				xPos = charSpatial.x + (handSpatial.x * charSpatial.scale) - _offsetX;
			}
			
			// add spatial and motion components
			var spatial:Spatial = new Spatial(xPos, yPos);
			var motion:Motion = new Motion();		
			_thrownEntity.add(spatial);
			_thrownEntity.add(motion);
			
			// add entity to group
			super.group.addEntity(_thrownEntity);
			
			// setup motion
			motion.friction 	= new Point(_friction, 0);
			if (_boomerang)
				motion.acceleration = new Point(0, 0);
			else
				motion.acceleration = new Point(0, _gravity);
			
			// if both x and y speeds are non-zero, then use those
			if ((_speedX) && (_speedY))
			{
				motion.velocity = new Point(_dir * _speedX, _speedY);
			}
			else
			{
				// else use random values
				motion.velocity = new Point(_dir * (Math.random() * 50 + 200), -100 + Math.random() * -200);
			}
			
			motion.rotationMaxVelocity = _dir*100;
			motion.rotationMinVelocity = -_dir*100;
			motion.rotationAcceleration = 0;
			motion.rotationVelocity = _dir * _rotationSpeed;
			
			// if sound file
			if(_launchSound)
				AudioUtils.playSoundFromEntity(_thrownEntity, SoundManager.EFFECTS_PATH + _launchSound, 600, 0.8, 1.2);
		}
		
		/**
		 * Update special ability 
		 * @param node
		 * @param time
		 */
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(_loaded)
			{
				// if item is airborne
				if (_isFlying)
				{
					// if boomerang has collided with NPC, then decrement counter
					if ((_boomerang) && (_collided))
					{
						_counter--;
					}
					else
					{
						// increment counter
						_counter++;
					}
					
					var display:Display = _thrownEntity.get(Display);
					var spatial:Spatial = _thrownEntity.get(Spatial);
					var motion:Motion = _thrownEntity.get(Motion);		
					var container:DisplayObjectContainer = super.entity.get(Display).container.parent;
					
					// check each NPC
					// check each NPC if not landing clip
					if (_landingClip == null) {
					var npcList:NodeList = group.systemManager.getNodeList( NpcNode );
					var npcNode:NpcNode;
					for( npcNode = npcList.head; npcNode; npcNode = npcNode.next )
					{
						// get NPC entity and display object
						var npcEntity:Entity = npcNode.entity;
						var npcClip:DisplayObjectContainer = npcEntity.get(Display).displayObject;
						
						// exclude pop follower and ad bitmap npcs
						var npcID:Id = npcEntity.get(Id);
						if ((npcID) && (npcID.id.indexOf("popFollower") == 0) || (npcID) && (npcID.id.substr(0,7) == "limited"))
							continue;
						
						// skip mannequins
						if ((npcEntity.has(Character)) && (npcEntity.get(Character).variant == CharacterCreator.VARIANT_MANNEQUIN))
							continue;

						// get bounding box in common parent's coordinate space
						var itemRect:Rectangle = display.displayObject.getBounds(container);
						var npcRect:Rectangle = npcClip.getBounds(container);
						
						// shrink rect for NPC so collision happens further in	
						npcRect.inflate(-20,0);
						
						// find the intersection of the two bounding boxes
						var intersectionRect:Rectangle = npcRect.intersection(itemRect);
						
						// if colliding with NPC
						if ((intersectionRect != null) && (intersectionRect.size.length > 0))
						{
							// setup dictionary for npc_actions
							var npcDict:Dictionary = new Dictionary();
							npcDict["npc"] = npcEntity;
							npcDict["color"] = _colors[_currentColor];
							npcDict["container"] = display.container; // used for particle effects applied to entire NPC
							
							// if popup animation needs to play
							if (_popupPath)
							{
								var path:String = _popupPath;
								// if color array has values, then append color position
								if (_colors.length != 0)
								{
									var pos:int = _popupPath.indexOf(".swf");
									path = _popupPath.substr(0,pos) + (_currentColor + 1) + ".swf";
								}
								// load popup
								npcDict["popup"] = path;
							}
							if(_multipleSkinParts)
								npcDict["suffix"] = (_suffix + 1);
							this.actionCall("npc_actions", npcDict, endActive);
							shellApi.triggerEvent(ITEM_HIT_NPC);
							
							// if bouncing off NPC
							if ((_bounce) || (_boomerang) || (_knock))
							{
								// if first bounce with this item
								if (MovieClip(npcClip).bounceEntity != _thrownEntity)
								{
									// remember bounce item entity
									MovieClip(npcClip).bounceEntity = _thrownEntity;
									// reverse x speed
									motion.velocity.x = -motion.velocity.x;
									// if boomerang then try to go back to starting point
									if (_boomerang)
									{
										// reverse spin
										motion.rotationVelocity = -motion.rotationVelocity;
										// calculate return velocity and adjust for hand position below avatar center
										motion.velocity.y = (_startY - spatial.y + 5) / ((getTimer() - _startTime) / 1000);
										// set collided flag
										_collided = true;
									}
									if (_knock)
									{
										// knock back npc
										if (!npcEntity.has(Motion))
											npcEntity.add(new Motion());
										var npcMotion:Motion = npcEntity.get(Motion);
										npcMotion.velocity.x = -motion.velocity.x / 3;
										npcMotion.friction = new Point(1000, 0);
										CharUtils.setAnim( npcEntity, Hurt, false, 0, 0, true, true);
										// wait for end, then trigger returnToStand
										npcEntity.get(Timeline).handleLabel( "ending", Command.create(returnToStand, npcEntity), false );
									}
								}
								// don't stop flight in this case
								continue;
							}
							
							// stop flight
							motion.velocity = new Point(0,0);
							if(_responderClassObject != null)
							{
								_responderClassObject.activate(npcNode.entity,_thrownEntity, endFlying);
								_isFlying = false;
							}
							else
							{
								endFlying();
							}		
						}
						
					}
					}
					
					// run object collision on thrown items
					if(_applyCollision)
					{
						if(!_thrownEntity.has(CurrentHit))
						{
							MotionUtils.addColliders(_thrownEntity);
						}
						
						var currHit:CurrentHit = _thrownEntity.get(CurrentHit);
						var hitEnt:Entity = currHit.hit;
						if(hitEnt != null)
						{
							if(_responderClassObject != null)
							{
								_responderClassObject.activate(hitEnt,_thrownEntity, endFlying);
								_isFlying = false;
							}
							else
							{
								endFlying();
							}
						}
					}
						// if still flying
					else if (_isFlying)
					{
						if (_landingClip != null) {
						// if at avatar's feet, then end flying
						if (spatial.y >= _startY + 36) {
							// clear collided flag
							_collided = false;
							// place item on ground (align to feet)
							_landingClip.visible = true;
							var _objectEntity:Entity = new Entity();
							_objectEntity.add(new Display(_landingClip, entity.get(Display).container));
							_objectEntity.add(new Spatial(spatial.x, _startY + 36));
							// apply flipping
							_objectEntity.get(Spatial).scaleX *= _dir;
							group.addEntity(_objectEntity);
							endFlying();
						}
					} else {
						// if below avatar by 260 or counter reaches max or counter decrements to zero for boomerang, then end flying
						if ((spatial.y - display.displayObject.height > _startY + 260) || (_counter > 120) || (_counter < 0))
						{
							// clear collided flag
							_collided = false;
							if(_responderClassObject != null)
							{
								_responderClassObject.activate(npcEntity,_thrownEntity, endFlying);
								_isFlying = false;
							}
							else{
								endFlying();
							}
						}
					}
					}
				}
			}
		}
		private function endActive(...args):void
		{
			super.data.isActive = false;
		}
		/**
		 * Stop flying item (when hit NPC or below avatar's feet) 
		 */
		private function endFlying():void
		{
			// turn off flag
			_isFlying = false;
			
			// remove flying object from scene
			super.group.removeEntity(_thrownEntity);
			
			// restore item in hand, if hidden
			if (_hideInHand)
			{
				var itemPart:Entity = CharUtils.getPart(super.entity, CharUtils.ITEM);
				itemPart.get(Display).visible = true;
			}
			
			// make inactive again
			super.setActive(false);
		}
		
		private function returnToStand(npc:Entity):void
		{
			// set stand animation
			CharUtils.setAnim(npc, Stand);
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			// remove responder class
			if(_responderClassObject){
				_responderClassObject.destroy();
				_responderClassObject = null;
			}
			
			// remove thrown entity
			if(_thrownEntity){
				super.group.removeEntity(_thrownEntity);
				_thrownEntity = null;
			}
			
			super.deactivate(node);
		}
		
		public const ITEM_HIT_NPC:String = "throw_item_hit_npc";
		
		public var _actionClass:Class = Throw;
		public var _triggerLabel:String = "trigger";
		public var _offsetX:Number = 0;
		public var _offsetY:Number = 0;
		public var _speedX:Number = 0;
		public var _speedY:Number = 0;
		public var _rotationSpeed:Number = 50;
		public var _gravity:Number = 700;
		public var _friction:Number = 0.1;
		public var _hideInHand:Boolean = true;
		public var _swfPath:String;
		public var _bounce:Boolean = false;
		public var _applyCollision:Boolean = false;
		public var _boomerang:Boolean = false;
		public var _knock:Boolean = false;
		public var _responderClass:Class; 
		public var _launchSound:String;
		public var _landingSwfPath:String;
		public var _popupPath:String;
		public var _colors:Array = [];
		public var _suffix:Number = 0;
		public var _multipleSkinParts:Boolean = false;
		
		private var _landingClip:MovieClip;
		private var _clip:MovieClip;
		private var _isFlying:Boolean = false;
		private var _thrownEntity:Entity;
		private var _startY:Number;
		private var _currentColor:int = -1;
		private var _counter:int = 0;
		private var _collided:Boolean = false;
		private var _startTime:uint;
		private var _loaded:Boolean = false;
		private var _responderClassObject:Object;
		private var _dir:Number = 1.0;
	}
}