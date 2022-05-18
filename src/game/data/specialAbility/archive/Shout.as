// Status: retired
// Usage (1) ads
// Used by avatar marks limited_shaun_belch

package game.data.specialAbility.character
{		
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Proud;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.components.motion.WaveMotion;
	import engine.components.SpatialAddition;
	import game.data.WaveMotionData;
	
	public class Shout extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			_resetMouthCountdown = 0;
			_screenShakeTime = 0;
			
			if ( _shakeTarget == null )
				_shakeTarget = new Spatial();
			
			if (super.data.isActive)
				return;
			
			super.setActive(true);
			
			SceneUtil.lockInput(super.group, true);
			
			var swfPath:String = String( super.data.params.byId( "swfPath" ) );
			super.loadAsset(swfPath, loadComplete);
		}
		
		private function loadComplete(clip:MovieClip):void
		{			
			// Create shout entity and set the display and spatial
			_shoutEntity = new Entity();
			_shoutEntity.add(new Display(clip, super.entity.get(Display).container));
			super.group.addEntity(_shoutEntity);
			var shoutSpatial:Spatial = new Spatial(super.entity.get(Spatial).x, super.entity.get(Spatial).y - 100);
			_shoutEntity.add(shoutSpatial);
			
			// this converts the content clip for AS3
			var vTimeline:Entity = TimelineUtils.convertClip(clip.content, super.group);			
			
			_previousMouth = SkinUtils.getSkinPart( super.entity, SkinUtils.MOUTH).value;
			CharUtils.setAnim(super.entity, Proud);
			_resetMouthCountdown = _RESET_MOUTH_COUNTDOWN_LENGTH;
			
			var cameraEntity:Entity = super.group.getEntityById("camera");
			
			if( cameraEntity.get(SpatialAddition) != null )
			{
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
			}
			else
				cameraEntity.add(new SpatialAddition());
			
			var waveMotion:WaveMotion = new WaveMotion();
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 3;
			waveMotionData.rate = .5;
			waveMotionData.radians = 0;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			
			SceneUtil.addTimedEvent(super.group, new TimedEvent(1.5, 1, endShake));
		}
		
		public var timerTest:Number;
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if ( _resetMouthCountdown > 0 )
			{
				_resetMouthCountdown --;
				if ( _resetMouthCountdown == 0 )
					SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "cry" );
			}
		}
		
		private function endShake():void
		{
			SkinUtils.setSkinPart( super.entity, SkinUtils.MOUTH, _previousMouth );
			
			var cameraEntity:Entity = super.group.getEntityById("camera");
			cameraEntity.remove(WaveMotion);
			var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
			spatialAddition.y = 0;
			
			super.group.removeEntity(_shoutEntity);
			super.setActive(false);
			SceneUtil.lockInput(super.group, false);
		}
		
		private var _shakeTarget:Spatial;
		private var _previousMouth:String;
		private var _resetMouthCountdown:int;
		private var _RESET_MOUTH_COUNTDOWN_LENGTH:int = 5;
		private var _shoutEntity:Entity;
		
		private var _screenShakeTime:Number;
	}
}

