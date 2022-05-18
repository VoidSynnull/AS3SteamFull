package game.util
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.render.Shadow;
	import game.components.timeline.Timeline;
	import game.components.ui.Gesture;
	import game.data.display.SpatialData;
	import game.data.ui.GestureData;
	import game.data.ui.GestureState;
	import game.particles.emitter.Ripple;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class GestureUtils
	{
		public static var gesturCreated:Signal = new Signal(Entity);
		public static const HAND_GESTURE_URL:String = "scenes/ftue/shared/handGestures.swf";// change to whatever artists come up with
		public function GestureUtils()
		{
			
		}
		
		private static function handLoaded(asset:*, entity:Entity,group:DisplayGroup, container:DisplayObjectContainer):void
		{
			if(asset == null)
				return;
			var clip:MovieClip = asset.getChildAt(0);
			clip.mouseChildren = clip.mouseEnabled = false;
			var display:Display = EntityUtils.getDisplay(entity);
			display.swapDisplayObject(clip);
			
			createGesture(entity, group, container);
		}
		
		public static function createGesture( asset:*,group:DisplayGroup, container:DisplayObjectContainer = null, onCreated:Function = null):Entity
		{
			if(onCreated != null)
				gesturCreated.addOnce(onCreated);
			
			if(container == null)
				container = group.groupContainer;
			
			var entity:Entity
			if(asset is Entity)
			{
				entity = asset;
				asset = EntityUtils.getDisplayObject(entity);
			}
			else
			{
				if(asset == null)
					asset = HAND_GESTURE_URL;
				
				if(asset is String)
				{
					var clip:MovieClip = group.getAsset(asset, true, true);
					if(clip == null)
					{
						entity = EntityUtils.createSpatialEntity(group, new MovieClip(),container);
						group.loadFileDeluxe(asset, true,true, Command.create(handLoaded,entity, group, container));
						return entity;
					}
					asset = clip.getChildAt(0);
				}
				
				if(asset is MovieClip)
				{
					entity = EntityUtils.createSpatialEntity(group, asset, container);
					asset.mouseChildren = asset.mouseEnabled = false;
				}
			}
			
			addGestureStates(entity, asset)
			
			entity.remove(Sleep);
			stop(entity);
			
			gesturCreated.dispatch(entity);
			
			return entity;
		}
		
		private static function addGestureStates(entity:Entity, asset:MovieClip):void
		{
			var gesture:Gesture = new Gesture(entity);
			entity.add(gesture);
			
			if(asset.totalFrames >1)
			{
				TimelineUtils.convertAllClips(asset,null, entity.group, true, 32, entity);
				gesture.animation = entity;
			}
			else
			{
				var clip:MovieClip = asset.getChildAt(0) as MovieClip;
				var child:Entity = EntityUtils.createSpatialEntity(entity.group, clip);
				EntityUtils.addParentChild(child, entity);
				gesture.animation = child;
			}
		}
		
		public static function performGesture(entity:Entity, data:GestureData):void
		{
			var onComplete:Function;
			if(data.onComplete != null)
			{
				if(data.onComplete is Function)
					onComplete = data.onComplete;
				if(data.onComplete is GestureData)
					onComplete = Command.create(performGesture, entity, data.onComplete);
			}
			
			switch(data.type)
			{
				case GestureData.PRESS:
				{
					press(entity, onComplete)
					break;
				}
				case GestureData.RELEASE:
				{
					release(entity, onComplete)
					break;
				}
				case GestureData.CLICK:
				{
					click(entity, data.start, data.repeat, onComplete);
					break;
				}
				case GestureData.MOVE:
				{
					move(entity, data.end == null? data.start:data.end, data.speed, onComplete);
					break;
				}
				case GestureData.CLICK_AND_DRAG:
				{
					clickAndDrag(entity, data.start, data.end, data.speed, data.repeat, onComplete);
					break;
				}
				case GestureData.MOVE_THEN_CLICK:
				{
					moveThenClick(entity, data.start, data.end, data.speed, data.repeat, onComplete);
					break;
				}
				case GestureData.STOP:
				{
					stop(entity);
					break;
				}
			}
		}
		
		public static function click(entity:Entity, position:Point = null, repeat:int = 0, onComplete:Function = null):void
		{
			EntityUtils.visible(entity);
			if(position != null)
			{
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = position.x;
				spatial.y = position.y;
			}
			
			trace(repeat);
			
			if(repeat != 0)
			{
				trace("not zero so repeat");
				onComplete = Command.create(click,entity, position, --repeat, onComplete);
			}
			
			var releaseMethod:Function = Command.create(release,entity,onComplete);
			
			setState(entity, GestureState.DOWN, false, releaseMethod);
		}
		
		public static function clickAndDrag(entity:Entity, start:Point, end:Point, time:Number = 1, repeat:int = 0, onComplete:Function = null):void
		{
			EntityUtils.visible(entity);
			
			var spatial:Spatial = entity.get(Spatial);
			if(start == null)
			{
				start.x = spatial.x;
				start.y = spatial.y;
			}
			else
			{
				spatial.x = start.x;
				spatial.y = start.y;
			}
			
			if(end == null)
			{
				end = start.clone();
			}
			
			if(repeat != 0)
				onComplete = Command.create(clickAndDrag, entity, start, end, time, --repeat, onComplete);
			
			var releaseMethod:Function = Command.create(release, entity,onComplete);
			
			var drag:Function = Command.create(move,entity,end,time,releaseMethod);
			
			setState(entity, GestureState.DOWN,false,drag);
		}
		
		public static function moveThenClick(entity:Entity, start:Point, end:Point, time:Number, repeat:int = 0, onComplete:Function = null):void
		{
			EntityUtils.visible(entity);
			
			var spatial:Spatial = entity.get(Spatial);
			if(start == null)
			{
				start.x = spatial.x;
				start.y = spatial.y;
			}
			else
			{
				spatial.x = start.x;
				spatial.y = start.y;
			}
			
			if(end == null)
			{
				end = start.clone();
			}
			
			if(repeat != 0)
				onComplete = Command.create(moveThenClick,entity, start, end, time,--repeat, onComplete);
			
			var clickMethod:Function = Command.create(click,entity,null,0,onComplete);
			
			move(entity,end,time,clickMethod);
		}
		
		public static function move(entity:Entity, position:Point, time:Number = 1, onComplete:Function = null):void
		{
			TweenUtils.entityTo(entity, Spatial, time, {x:position.x, y:position.y, ease:Linear.easeNone, onComplete:onComplete});
		}
		
		public static function press(entity:Entity, onComplete:Function = null):void
		{
			setState(entity, GestureState.DOWN, false, onComplete);
		}
		
		public static function release(entity:Entity, onComplete:Function = null):void
		{
			setState(entity, GestureState.UP, false, onComplete);
		}
		
		public static function setState(entity:Entity, targetState:String, instant:Boolean = false, onComplete:Function = null):void
		{
			var gesture:Gesture = entity.get(Gesture);
			
			var timeline:Timeline = gesture.animation.get(Timeline);
			
			var target:GestureState = gesture.getState(targetState);
			
			var startState:String;
			
			if(gesture.state)
				startState = gesture.state.state;
			else
				startState = (targetState == GestureState.UP)?GestureState.DOWN:GestureState.UP;
			
			gesture.state = target;
			
			if(timeline)//if the gesture has a timeline
			{
				if(instant)
				{
					timeline.gotoAndStop(targetState);
					if(onComplete != null)
						onComplete();
					return;
				}
				
				timeline.gotoAndPlay(startState);
				timeline.handleLabel(targetState, timeline.stop);
				if(onComplete != null)
					timeline.handleLabel(targetState,onComplete);
			}
			else// if the gesture is a static asset
			{
				var shadow:Shadow = gesture.animation.get(Shadow);
				
				if(instant)
				{
					target.spatialData.positionSpatial(gesture.animation.get(Spatial));
					
					if(shadow)
						shadow.median = targetState == GestureState.DOWN? 1:0;
					
					if(onComplete != null)
						onComplete();
					return;
				}
				
				var pos:SpatialData = gesture.getState(startState).spatialData;
				
				var from:Object = {x:pos.x, y:pos.y, rotation:pos.rotation, scaleX:pos.scaleX, scaleY:pos.scaleY};
				
				pos = target.spatialData;
				
				var to:Object = {x:pos.x, y:pos.y, rotation:pos.rotation, scaleX:pos.scaleX, scaleY:pos.scaleY};
				if(onComplete)
					to.onComplete = onComplete;
				
				TweenUtils.entityFromTo(gesture.animation, Spatial, .5,from,to);
				
				if(shadow)
				{
					TweenUtils.entityFromTo(gesture.animation, Shadow, .5,{median:targetState == GestureState.DOWN? 1:0},{median:targetState == GestureState.DOWN? 0:1});
				}
				if(gesture.state.state == GestureState.DOWN && gesture.ripple)
				{
					var emitter:Emitter = gesture.ripple.get(Emitter);
					if(emitter)
					{
						var rip:Ripple = emitter.emitter as Ripple;
						SceneUtil.delay(entity.group, rip.lifeTime/rip.ripples,Command.create(riple, emitter));
					}
				}
			}
		}
		
		private static function riple(emitter:Emitter):void
		{
			emitter.emitter.resume();
			emitter.start = true;
		}
		// if you want to hide a gesture, or reset gesture if you want to do multiple gestures in a sequence.
		
		public static function stop(entity:Entity, hide:Boolean = true):void
		{
			entity.remove(Tween);
			var gesture:Gesture = entity.get(Gesture);
			gesture.animation.remove(Tween);
			setState(entity, GestureState.UP, true);
			EntityUtils.visible(entity, !hide);
		}
	}
}