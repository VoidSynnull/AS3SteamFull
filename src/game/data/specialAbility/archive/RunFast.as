// Status: retired
// Usage (1) ads
// Used by card 2522

package game.data.specialAbility.character
{
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Run;
	import game.data.character.LookConverter;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	//import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class RunFast extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				blurF = new BlurFilter(0, 0, 1);
				
				SceneUtil.lockInput( super.group );
								
				var charSpatial:Spatial = node.entity.get(Spatial);
				var xPos:Number = charSpatial.x;
				var yPos:Number = charSpatial.y;
				
				direction = node.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
				
				var charGroup:CharacterGroup = super.group.getGroupById("characterGroup") as CharacterGroup;
				objectEntity = charGroup.createNpcPlayer(onCharLoaded, null, new Point(xPos, yPos+40));
				
				var spatial:Spatial = objectEntity.get(Spatial);
				if (direction != CharUtils.DIRECTION_LEFT)
				{
					spatial.scaleX *= -1;
				} 
				
				node.entity.get(Display).alpha = 0;
				
				var vpOffset:Number = scene.shellApi.viewportWidth;
				
				var leftEdge:Number;
				var rightEdge:Number;
				leftEdge = xPos - vpOffset;

				rightEdge = xPos + vpOffset;
				
			}
		}
		
		public function onCharLoaded( charEntity:Entity = null ):void
		{

			//increase max speed and acceleration
			//var charMotionCtrl:CharacterMotionControl = objectEntity.get(CharacterMotionControl);
			//charMotionCtrl.baseAcceleration = 3000;
			//charMotionCtrl.maxVelocityX = 4000;
			
			//CharUtils.removeCollisions(objectEntity);
			
			CharUtils.setAnim(objectEntity, Run);
			
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				playerDirection = -1;
			} else {
				playerDirection = 1;
			}
			
			var motion:Motion = new Motion();
			
			objectEntity.add(motion);
			
			objectEntity.get(Motion).velocity.x = 1200*playerDirection;
			objectEntity.get(Motion).velocity.y = 0;
			
			//CharUtils.followPath(objectEntity, path, stopBlur, false, false, null, true);
			
			super.setActive(true);
		}
		
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			//update Motion Blur based on player's x velocity
			//var motion:Motion = objectEntity.get( Motion );
			//blurF.blurX = Math.abs(objectEntity.get(Motion).velocity.x)/20;
			blurF.blurX = 40;
			objectEntity.get(Display).displayObject.filters = [blurF];	
			
			var spatial:Spatial = objectEntity.get(Spatial);
			var display:Display = objectEntity.get(Display);
			var motion:Motion = objectEntity.get(Motion);
			
			var boundsX:Number = super.shellApi.camera.viewportWidth;			
			var relativeX:Number = super.shellApi.offsetX(spatial.x);
			
			if(_bounce < 4)
			{
			
				if(relativeX + display.displayObject.width/2 > boundsX)
				{
					_bounce++; 
					playerDirection = -1;
					spatial.scaleX *= -1;
					spatial.x -= display.displayObject.width;
					motion.velocity.x *= -1;
				}
				
				if((relativeX - display.displayObject.width/2 < 0) && playerDirection < 0 )
				{
					_bounce++; 
					playerDirection = 1;
					spatial.scaleX *= -1;
					spatial.x += display.displayObject.width;
					motion.velocity.x *= -1;
				}	
			} else {
				var charSpatial:Spatial = node.entity.get(Spatial);
				
				if(spatial.x >= charSpatial.x && playerDirection == 1)
				{
					spatial.x = charSpatial.x;
					stopBlur(objectEntity);
				}
				
				if(spatial.x <= charSpatial.x && playerDirection == -1)
				{
					spatial.x = charSpatial.x;
					stopBlur(objectEntity);
				}
			}

		}
		
		private function stopBlur(entity:Entity):void
		{

			objectEntity.get(Display).displayObject.filters = [];
			_bounce = 0;
			
			SceneUtil.lockInput( super.group, false );
			
			super.entity.get(Display).alpha = 1;
			
			//remove invisible NPC target
			super.group.removeEntity(objectEntity);
			
			super.setActive( false );
			
			// RLH remove special ability from profile (this fixes problem with getting triggered on every scene load)
			super.shellApi.specialAbilityManager.removeSpecialAbility(super.shellApi.player, super.data.id);

		}
		
		private var _bounce:Number = 0;
		private var _update:TimedEvent;
		private var blurF:BlurFilter;
		private var objectEntity:Entity;		
		private var direction:String;
		private var playerDirection:Number =1;
		
		private var _lookConverter:LookConverter;
	}
}