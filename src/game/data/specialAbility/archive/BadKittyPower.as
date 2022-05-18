// Status: retired
// Usage (1) ads
// Used by avatar pack limited_badkitty_tail

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
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookAspectData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.scene.template.SceneUIGroup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	
	public class BadKittyPower extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				stopBlurr = false;
				
				super.loadAsset(_swfPath, loadComplete);
				
				blurF = new BlurFilter(0, 0, 1);
				
				//CharUtils.lockControls( node.entity, true, true);
				
				SceneUtil.lockInput( super.group );
				
				var charSpatial:Spatial = node.entity.get(Spatial);
				var xPos:Number = charSpatial.x;
				var yPos:Number = charSpatial.y;
				
				direction = node.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
				
				var charGroup:CharacterGroup = super.group.getGroupById("characterGroup") as CharacterGroup;
				objectEntity = charGroup.createNpcPlayer( onCharLoaded, null, new Point(xPos, yPos+40));
				
				var spatial:Spatial = objectEntity.get(Spatial);
				if (direction != CharUtils.DIRECTION_LEFT)
				{
					spatial.scaleX *= -1;
				} 
				
				node.entity.get(Display).alpha = 0;
				
				var vpOffset:Number = super.shellApi.viewportWidth;
				
				var leftEdge:Number;
				var rightEdge:Number;
				leftEdge = xPos - vpOffset;
				
				rightEdge = xPos + vpOffset;
				
			}
		}
		
		private function loadComplete(clip:MovieClip):void
		{
			if (clip == null)
				return;
			
			// remember clip
			_clip = clip;
			
			// Add the MovieClip to scene
			_sceneUIGroup = super.group.getGroupById('ui') as SceneUIGroup;
			_sceneUIGroup.container.addChild(clip);
			
			// Create the new entity and set the display and spatial
			clipEntity = new Entity();
			clipEntity.add(new Display(clip, _sceneUIGroup.container));
			
			clipEntity.add(new Spatial(0, 0));
			super.group.addEntity(clipEntity);
						
			// this converts the content clip for AS3
			var vTimeline:Entity = TimelineUtils.convertClip(clip.content, super.group);
			//TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, endPopupAnim );
		}
		

		private function setFlip():void
		{
			flip *= -1;
			canSetTimeout = true;
		}
		
		private function setCharParts():void
		{
			//var lookAspect:LookAspectData = new LookAspectData( SkinUtils.FACIAL,"limited_badkitty"); 
				var lookData:LookData = new LookData();
				lookData.applyAspect( new LookAspectData( SkinUtils.SHIRT, "limited_badkitty" ) );
				lookData.applyAspect( new LookAspectData( SkinUtils.FACIAL, "limited_badkittymad" ) );
				lookData.applyAspect( new LookAspectData( SkinUtils.PACK, "limited_badkitty" ) );
				lookData.applyAspect( new LookAspectData( SkinUtils.PANTS, 1 ) );
				lookData.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, "0x0" ) );
				//lookData.applyAspect( lookAspect );
				
				//if(SkinUtils.getLook(_char) != null)
				//_char.add(new Skin);
				
				SkinUtils.applyLook( objectEntity, lookData, false );	
		}
		
		private function endPopupAnim():void
		{
			// remove clip
			_sceneUIGroup.container.removeChild(_clip);
			
			//set player visible
			//_node.entity.get(Display).alpha = 1;
			
			// enable user input
			SceneUtil.lockInput(super.group, false);
			
			// make inactive
			super.setActive( false );
		}
		
		public function setChar():void
		{
			blurF.blurX = 40;
			startSpin = true;
			CharUtils.setAnim(objectEntity, Run);
			
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				playerDirection = -1;
			} else {
				playerDirection = 1;
			}
			
			var motion:Motion = new Motion();
			
			objectEntity.add(motion);
			
			objectEntity.get(Motion).velocity.x = 500*playerDirection;
			objectEntity.get(Motion).velocity.y = 0;
		}
		
		public function onCharLoaded( charEntity:Entity = null ):void
		{
			
			//increase max speed and acceleration
			//var charMotionCtrl:CharacterMotionControl = objectEntity.get(CharacterMotionControl);
			//charMotionCtrl.baseAcceleration = 3000;
			//charMotionCtrl.maxVelocityX = 4000;
			
			//CharUtils.removeCollisions(objectEntity);
			setCharParts();
			var timedEvent:TimedEvent = new TimedEvent( 2, 1, setChar);
			SceneUtil.addTimedEvent(super.group, timedEvent);
			
	
			
			//CharUtils.followPath(objectEntity, path, stopBlur, false, false, null, true);
			
			super.setActive(true);
		}
		
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			//update Motion Blur based on player's x velocity
			//var motion:Motion = objectEntity.get( Motion );
			//blurF.blurX = Math.abs(objectEntity.get(Motion).velocity.x)/20;
			
			objectEntity.get(Display).displayObject.filters = [blurF];	
			
			var spatial:Spatial = objectEntity.get(Spatial);
			var display:Display = objectEntity.get(Display);
			var motion:Motion = objectEntity.get(Motion);
		
			//clipEntity.get(Spatial).y = spatial.y;
			
			var boundsX:Number = super.shellApi.camera.viewportWidth;			
			var relativeX:Number = super.shellApi.offsetX(spatial.x);
			var relativeY:Number = super.shellApi.offsetY(spatial.y);
			
			clipEntity.get(Spatial).x = relativeX;
			clipEntity.get(Spatial).y = relativeY;
			
			if(startSpin == true)
			{
				spatial.scaleX = flip;
				if(canSetTimeout)
				{
					var timedEvent:TimedEvent = new TimedEvent( .2 + delay, 1, setFlip);
					SceneUtil.addTimedEvent(super.group, timedEvent);
				}
				//flip *= -1;
			}
			
			
			if(_bounce < 2)
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
				delay = .5;
				if(blurF.blurX > 0)
					blurF.blurX -= 4;
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
		private function setStopBlur():void
		{
			stopBlurr = true;
		}
		
		private function stopBlur(objectEntity:Entity):void
		{
			var timedEvent:TimedEvent = new TimedEvent( 1, 1, endPower);
			SceneUtil.addTimedEvent(super.group, timedEvent);
			objectEntity.get(Motion).velocity.x = 0;
			CharUtils.setAnim(objectEntity, Stand);
			objectEntity.get(Display).displayObject.filters = [];
			
			_bounce = 0;
			delay = 1.8;
		}
		
		private function endPower():void
		{
			SceneUtil.lockInput( super.group, false );
			startSpin = false;
			super.entity.get(Display).alpha = 1;
			stopBlurr = true;
			//remove invisible NPC target
			super.group.removeEntity(objectEntity);
			_sceneUIGroup.container.removeChild(_clip);
			
			super.setActive( false );
			
		}
		
		public var _swfPath:String;
		
		private var _sceneUIGroup:SceneUIGroup;
		private var _bounce:Number = 0;
		private var _update:TimedEvent;
		private var blurF:BlurFilter;
		private var objectEntity:Entity;	
		private var clipEntity:Entity;
		private var direction:String;
		private var playerDirection:Number =1;
		
		private var _lookConverter:LookConverter;
		
		private var _clip:MovieClip;
		private var flip:Number = .36;
		private var startSpin:Boolean = false;
		private var canSetTimeout:Boolean = true;
		private var delay:Number = 0;
		private var stopBlurr:Boolean = false;
	}
}