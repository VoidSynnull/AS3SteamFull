// Used by:
// Card "curds" on mocktropica island using item mk_curds

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Throw;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.displayObjects.Blob;
	
	/**
	 * Avatar throws curd Blob and it remains on ground
	 * 
	 * optional params:
	 * color		Uint		Color of curd (default is black)
	 */
	public class ThrowCurd extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				var currentState:String = CharUtils.getStateType(entity)
				if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
				{
					super.setActive(true);
					
					// create blob
					var curd:Blob = new Blob(4, _color);
					var mc:MovieClip = new MovieClip();
					mc.addChild(curd);
					
					// create entity
					_curdEntity = new Entity();
					_curdEntity.add(new Display(mc, super.entity.get(Display).container));
					
					// throw animation and trigger
					CharUtils.setAnim(super.entity, Throw);
					CharUtils.getTimeline(super.entity).handleLabel("trigger", curdThrow);
				}
			}
		}
		
		/**
		 * Throw curd when reach trigger label in animation
		 */
		private function curdThrow():void
		{
			var handSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charSpatial:Spatial = super.entity.get(Spatial);
			
			var direction:Number = 1;
			var xPos:Number = charSpatial.x - (handSpatial.x * charSpatial.scale);
			var yPos:Number = charSpatial.y + (handSpatial.y * charSpatial.scale);
			if(charSpatial.scaleX > 0)
			{
				xPos = charSpatial.x + (handSpatial.x * charSpatial.scale);
				direction = -1;
			}
			_curdEntity.add(new Spatial(xPos, yPos));
			
			var motion:Motion = new Motion();
			_curdEntity.add(motion);

			super.group.addEntity(_curdEntity);
			var charGroup:CharacterGroup = super.group.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addColliders(_curdEntity);
			
			var vel:Number = Math.random() * 200 + 150;
			var accel:Number = Math.random() * 150 + 500;
			
			motion.velocity = new Point(vel * direction, -300);
			motion.acceleration = new Point(0, accel);
			motion.friction = new Point(.4 * direction, 0);
			motion.rotationAcceleration = 200;
			_currentCurd = _curdEntity;
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(_currentCurd)
			{
				var motion:Motion = _currentCurd.get(Motion);
				
				if(motion != null)
				{
					if(motion.velocity.y == 0)
					{
						motion.velocity.x = 0;
						motion.rotationVelocity = 0;
						motion.rotationAcceleration = 0;
						motion.rotation = 0;
						motion.acceleration = new Point(0, 0);
						
						var narf:Narf = super.entity.get(Narf);
						if(narf != null)
						{
							narf.targetChanged.dispatch(_currentCurd.get(Spatial), _currentCurd);
							narf.currentCurd = _currentCurd;
						}

						// Timer to kill that entity later
						SceneUtil.addTimedEvent(super.group, new TimedEvent(5, 1, killLastCurd));
						super.setActive(false);
					}
				}
			}
		}
		
		/**
		 * remove last curd 
		 */
		private function killLastCurd():void
		{
			var narf:Narf = super.entity.get(Narf);
			if(narf != null)
			{
				if(narf.currentCurd == _currentCurd)
				{
					narf.targetChanged.dispatch(null, null);
				}
			}
			
			super.group.removeEntity(_currentCurd);
			_currentCurd = null;
		}
		
		public var _color:uint = 0x000000;
		private var _curdEntity:Entity;
		private var _currentCurd:Entity;
	}
}