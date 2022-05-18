// Used by:
// Card 2757 using avatar item limited_caprispring

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Jump;
	import game.data.character.LookConverter;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.scene.template.SceneUIGroup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	/**
	 * Jump high with temporary shoes
	 */
	public class CrazyJumping extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				SceneUtil.lockInput( super.group );
				
				loadComplete(node);
			}
		}
		
		private function loadComplete(node:SpecialAbilityNode):void
		{
			var charSpatial:Spatial = super.entity.get(Spatial);
			var xPos:Number = charSpatial.x;
			var yPos:Number = charSpatial.y;
			trampTop = yPos + 23;
			
			direction = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			var charGroup:CharacterGroup = node.owning.group.getGroupById("characterGroup") as CharacterGroup;
			_charEntity = charGroup.createNpcPlayer( onCharLoaded, null, new Point(xPos, yPos+40));
			
			var spatial:Spatial = _charEntity.get(Spatial);
			if (direction != CharUtils.DIRECTION_LEFT)
			{
				spatial.scaleX *= -1;
			} 
			
			node.entity.get(Display).alpha = 0;
			
			var vpOffset:Number = node.owning.group.shellApi.viewportHeight;
		}
		
		public function onCharLoaded( charEntity:Entity = null ):void
		{
			//increase max speed and acceleration
			//var charMotionCtrl:CharacterMotionControl = objectEntity.get(CharacterMotionControl);
			//charMotionCtrl.baseAcceleration = 3000;
			//charMotionCtrl.maxVelocityX = 4000;
			
			if(_feetPart != "")
			{
				SkinUtils.setSkinPart(_charEntity,SkinUtils.FOOT1, _feetPart);
				SkinUtils.setSkinPart(_charEntity,SkinUtils.FOOT2, _feetPart);
			}
			CharUtils.setAnim(_charEntity, Jump);
			
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				playerDirection = -1;
			} else {
				playerDirection = 1;
			}
			
			var motion:Motion = new Motion();
			
			_charEntity.add(motion);
			
			_charEntity.get(Motion).velocity.x = 0;
			_charEntity.get(Motion).velocity.y = MV;
			
			super.setActive(true);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			var spatial:Spatial = _charEntity.get(Spatial);
			var display:Display = _charEntity.get(Display);
			var motion:Motion = _charEntity.get(Motion);
			
			var boundsY:Number = super.shellApi.camera.viewportHeight;			
			var relativeY:Number = super.shellApi.offsetY(spatial.y);
			
			var charSpatial:Spatial = node.entity.get(Spatial);
			
			vSpeed += 12;
			_charEntity.get(Motion).velocity.y = vSpeed;
			
			if(spatial.y >= trampTop)
			{
				_bounce++;
				spatial.y = trampTop - 5;
				vSpeed = MV - (150 * _bounce);
			}
			
			if( (relativeY - display.displayObject.height/2)+40 < 0 )
			{
				stopAll(_charEntity);
			}
		}
		
		private function stopAll(entity:Entity):void
		{
			_bounce = 0;
			
			SceneUtil.lockInput( super.group, false );
			
			super.entity.get(Display).alpha = 1;
			
			//remove NPC player
			super.group.removeEntity(_charEntity);
			
			super.setActive( false );
		}
		
		public var _feetPart:String;
		private var _sceneUIGroup:SceneUIGroup;
		private var _bounce:Number = 0;
		private var _update:TimedEvent;
		private var vSpeed:Number = -400;
		private var MV:Number = -400;
		private var trampTop:Number;
		private var blurF:BlurFilter;
		private var _charEntity:Entity;
		private var trampoline:Entity;
		private var direction:String;
		private var playerDirection:Number =1;
		private var _clip:MovieClip;
		
		private var _lookConverter:LookConverter;
	}
}