// Status: retired
// Usage (1) ads
// Used by card 2524

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
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
	import game.util.TimelineUtils;
	
	
	//import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class CrazyJumping extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				//CharUtils.lockControls( node.entity, true, true);
				
				SceneUtil.lockInput( super.group );
				
				// get swf path and load
				var swfPath:String = "specialAbility/objects/Trampoline.swf";
				super.loadAsset(swfPath, loadComplete);
			}
		}
		
		private function loadComplete(clip:MovieClip):void
		{
			if (clip == null)
				return;
			
			var charSpatial:Spatial = super.entity.get(Spatial);
			var xPos:Number = charSpatial.x;
			var yPos:Number = charSpatial.y;
			
			// remember clip
			_clip = clip;
			
			// Add the MovieClip to scene
			_sceneUIGroup = super.group.getGroupById('ui') as SceneUIGroup;
			_sceneUIGroup.container.addChild(clip);
			
			// Create the new entity and set the display and spatial
			trampoline = new Entity();
			var display:Display = new Display(clip, super.entity.get(Display).container);
			trampoline.add(display);
			
			var trampSpatial:Spatial = new Spatial(xPos, yPos+23);
			
			trampTop = yPos;
			
			trampoline.add(trampSpatial);
			super.group.addEntity(trampoline);
			
			// this converts the content clip for AS3
			var vTimeline:Entity = TimelineUtils.convertClip(clip.content, super.group);
			//TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, endPopupAnim );
			
			
			
			direction = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			var charGroup:CharacterGroup = scene.getGroupById("characterGroup") as CharacterGroup;
			_charEntity = charGroup.createNpcPlayer( onCharLoaded, null, new Point(xPos, yPos+40));
			
			var spatial:Spatial = _charEntity.get(Spatial);
			if (direction != CharUtils.DIRECTION_LEFT)
			{
				spatial.scaleX *= -1;
			} 
			
			node.entity.get(Display).alpha = 0;
			
			var vpOffset:Number = scene.shellApi.viewportHeight;
			

		}
		
		public function onCharLoaded( charEntity:Entity = null ):void
		{

			//increase max speed and acceleration
			//var charMotionCtrl:CharacterMotionControl = objectEntity.get(CharacterMotionControl);
			//charMotionCtrl.baseAcceleration = 3000;
			//charMotionCtrl.maxVelocityX = 4000;
			
			//CharUtils.removeCollisions(objectEntity);
			
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
			
			//CharUtils.followPath(objectEntity, path, stopAll, false, false, null, true);
			
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
			
			//remove trampoline
			super.group.removeEntity(trampoline);
			
			super.setActive( false );
			
			// RLH remove special ability from profile (this fixes problem with getting triggered on every scene load)
			super.shellApi.specialAbilityManager.removeSpecialAbility(super.shellApi.player, super.data.id);
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			
		}	
		
			
		private var _sceneUIGroup:SceneUIGroup;
		private var _bounce:Number = 0;
		private var _update:TimedEvent;
		private var vSpeed:Number = -300;
		private var MV:Number = -300;
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


