// Used by:
// Card 3275 using items storediscus1, storediscus2

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.CollisionDetection;
	
	import game.components.entity.character.part.MetaPart;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.BlockNinja;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.DiscTrail;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	
	/**
	 * Throw disc that bounces four times and then returns to avatar
	 * 
	 * Optional params:
	 * swfPath		String		Path to disc swf file
	 * color		Uint		Color of disc trail (default is black)
	 */
	public class DiscThrow extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			// if not active
			if(!super.data.isActive)
			{
				var currentState:String = CharUtils.getStateType(entity)
				if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
				{
					var scale:Boolean = false;
					
					// If no parameter specified get the swf's file path from the current player item
					if((_swfPath == null) || (_swfPath != ""))
					{
						scale = true;
						var metaPart:MetaPart = CharUtils.getPart(super.entity, CharUtils.ITEM).get(MetaPart);
						_swfPath = "entity/character/" + metaPart.currentData.partId + "/" + metaPart.currentData.asset + ".swf";
					}
					
					super.loadAsset(_swfPath, loadComplete, scale);
				}
			}
		}
		
		/**
		 * When disc had loaded 
		 * @param clip
		 * @param scale
		 */
		private function loadComplete(clip:MovieClip, scale:Boolean = false):void
		{
			// return if no clip
			if (clip == null)
				return;
			
			super.setActive(true);
			
			// remember clip
			_clip = clip;
			_moveDisc = false;
			
			if(scale)
			{
				clip.scaleX = super.entity.get(Spatial).scaleX;
				clip.scaleY = super.entity.get(Spatial).scaleY;
			}
			
			CharUtils.lockControls(super.entity, true, true);
			SceneUtil.lockInput(super.group, true, true);
			
			CharUtils.setAnim(super.entity, BlockNinja);
			CharUtils.getTimeline(super.entity).handleLabel(Animation.LABEL_ENDING, throwDisc);
		}
		
		/**
		 * Start the throwing action after the animation is done
		 */
		private function throwDisc():void
		{
			_moveDisc = true;
			_bounce = 0; // reset everytime its thrown
			
			CharUtils.getRigAnim(super.entity).ended.remove(throwDisc);
			
			var itemPart:Entity = CharUtils.getPart(super.entity, CharUtils.ITEM);
			itemPart.get(Display).visible = false;
			
			discEntity = new Entity();
			var display:Display = new Display(_clip, super.entity.get(Display).container);
			discEntity.add(display);
			
			var handSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charSpatial:Spatial = super.entity.get(Spatial);
			
			var xPos:Number = charSpatial.x - (handSpatial.x * charSpatial.scale);
			var yPos:Number = charSpatial.y + (handSpatial.y * charSpatial.scale);
			
			var spatial:Spatial = new Spatial(xPos, yPos);
			var motion:Motion = new Motion();
			discEntity.add(spatial);
			discEntity.add(motion);
			
			var trail:DiscTrail = new DiscTrail();
			trail.init(_clip.width, _clip.height, _color, spatial);
			var emitter:Entity = EmitterCreator.create(super.group, display.container, trail, 0, 0, discEntity, "discTrail", spatial);
			
			super.group.addEntity(discEntity);
			
			var inputSpatial:Spatial = super.shellApi.inputEntity.get(Spatial);
			var radians:Number = GeomUtils.radiansBetween(inputSpatial.x, inputSpatial.y, super.shellApi.offsetX(charSpatial.x), super.shellApi.offsetY(charSpatial.y));
			
			spatial.rotation = 180 * radians/Math.PI;
			motion.velocity.x = _initSpeed * Math.cos(radians);
			motion.velocity.y = _initSpeed * Math.sin(radians);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(_moveDisc)
			{
				var boundsX:Number = super.shellApi.camera.viewportWidth;
				var boundsY:Number = super.shellApi.camera.viewportHeight;
				
				var spatial:Spatial = discEntity.get(Spatial);
				var display:Display = discEntity.get(Display);
				var motion:Motion = discEntity.get(Motion);
				var charSpatial:Spatial = super.entity.get(Spatial);
				
				var relativeX:Number = super.shellApi.offsetX(spatial.x);
				var relativeY:Number = super.shellApi.offsetY(spatial.y);
				
				if(_bounce >= 4)
				{
					var returnRadians:Number = GeomUtils.radiansBetween(super.shellApi.offsetX(charSpatial.x), super.shellApi.offsetY(charSpatial.y), relativeX, relativeY);
					spatial.rotation = 180 * returnRadians/Math.PI;
					motion.velocity.x = _initSpeed * Math.cos(returnRadians);
					motion.velocity.y = _initSpeed * Math.sin(returnRadians);
					
					var container:DisplayObjectContainer = super.entity.get(Display).container.parent;
					if(CollisionDetection.isColliding(super.entity.get(Display).displayObject, display.displayObject, container))
					{
						motion.velocity = new Point(0,0);
						discReturned();	
					}
				}
				else
				{
					// Check for bounces
					if(relativeX + display.displayObject.width/2 > boundsX)
					{
						_bounce++; 
						spatial.x -= display.displayObject.width;
						motion.velocity.x *= -1;
					}			
					if(relativeX - display.displayObject.width/2 < 0)
					{
						_bounce++; 
						spatial.x += display.displayObject.width;
						motion.velocity.x *= -1;
					}			
					if(relativeY + display.displayObject.height/2 > boundsY)
					{
						_bounce++;
						spatial.y -= display.displayObject.height;
						motion.velocity.y *= -1;
					}			
					if(relativeY - display.displayObject.height/2 < 0)
					{
						_bounce++;
						spatial.y += display.displayObject.height;
						motion.velocity.y *= -1;
					}
					
					var radians:Number = Math.atan2(motion.velocity.y, motion.velocity.x);
					spatial.rotation = 180 * radians/Math.PI;
				}
			}
		}
		
		/**
		 * When the disc returns to avatar's hand 
		 */
		private function discReturned():void
		{
			super.setActive(false);
			
			// remove disc
			super.group.removeEntity(discEntity);
			_clip = null;
			
			// show disc in hand
			var itemPart:Entity = CharUtils.getPart(super.entity, CharUtils.ITEM);
			itemPart.get(Display).visible = true;
			
			// restore avatar
			SceneUtil.lockInput(super.group, false, false);
			CharUtils.lockControls(super.entity, false, false);
		}
		
		public var _swfPath:String;
		public var _color:uint = 0x000000;
		
		private var _moveDisc:Boolean = false;
		private var _initSpeed:Number = -900;
		private var _bounce:int = 0;
		private var _clip:MovieClip;
		private var discEntity:Entity;
	}
}