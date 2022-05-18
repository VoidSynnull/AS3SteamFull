package engine.components
{	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TouchEvent;
	
	import ash.core.Component;
	
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	public class Interaction extends Component
	{
		// These signals are dispatched by the InteractionSystem to notify any listeners outside the entity of the interaction.
		// They pass the entity containing them as their parameter Signal(Entity)
		public var down:Signal;
		public var up:Signal;
		public var click:Signal;
		public var touch:Signal;//not really intended for use, but more for formalities
		public var over:Signal;
		public var out:Signal;
		public var keyDown:Signal;
		public var keyUp:Signal;
		public var releaseOutside:Signal;
		public var move:Signal;
		
		// These signals are wired to the handlers from native flash events.  They are added and used by the system.
		public var downNative:NativeSignal;
		public var upNative:NativeSignal;
		public var clickNative:NativeSignal;
		public var touchNative:NativeSignal;
		public var overNative:NativeSignal;
		public var outNative:NativeSignal;
		public var keyDownNative:NativeSignal;
		public var keyUpNative:NativeSignal;
		public var releaseOutsideNative:NativeSignal;
		public var moveNative:NativeSignal;
		
		public var invalidate:Boolean = false;	// true when any flag has been set to true 
		
		// These flags are used by systems to detect when an interaction has occurred.
		public var isDown:Boolean = false;
		//public var isUp:Boolean = false;
		//public var isClicked:Boolean = false;
		//public var isOver:Boolean = false;
		//public var isOut:Boolean = false;
		public var keyIsDown:uint;
		public var keyIsUp:uint;
		//public var isReleasedOutside:Boolean = false;
		//public var isMoved:Boolean = false;
		
		// These flags are used by systems to detect when an interaction has occurred.
		//public var downEvent:Event;
		//public var upEvent:Event;
		//public var clickedEvent:Event;
		//public var overEvent:Event;
		//public var outEvent:Event;
		public var keyDownEvent:Event;
		public var keyUpEvent:Event;
		//public var releasedOutsideEvent:Event;
		//public var movedEvent:Event;
		
		// 'private' flags used by the interaction system only to trigger the above flags
		//public var _isDown:Boolean = false;
		//public var _isUp:Boolean = false;
		//public var _isClicked:Boolean = false;
		//public var _isOver:Boolean = false;
		//public var _isOut:Boolean = false;
		public var _keyIsDown:uint;
		public var _keyIsUp:uint;
		//public var _isReleasedOutside:Boolean = false;
		//public var _isMoved:Boolean = false;
		public var _manualLock:Boolean = false;
		public var _lock:Boolean;

		public function set lock(lock:Boolean):void { _lock = lock; _manualLock = lock; }
		public function get lock():Boolean { return(_lock); }
		
		public function downHandler(event:Event):void
		{
			if(!_lock)
			{
				//invalidate = true;
				//_isDown = true;
				//downEvent = event;
				
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					isDown = true;
					down.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function upHandler(event:Event):void
		{
			if(!_lock)
			{
				//invalidate = true;
				//_isUp = true;
				//upEvent = event;
				
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					isDown = false;
					up.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function clickHandler(event:Event):void
		{
			if(!_lock)
			{
				//invalidate = true;
				//_isClicked = true;
				//clickedEvent = event;
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					click.dispatch(componentManagers[0]);
				}
			}
		}
		//handles all secondary touches because if it handled the original, click would go off twice
		public function touchHandler(event:Event):void
		{
			var t:TouchEvent = event as TouchEvent;
			if(t == null)
				return;
			
			trace("touch: " + t.touchPointID + " primary: " + t.isPrimaryTouchPoint);
			if(!_lock && !t.isPrimaryTouchPoint)
			{
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					click.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function overHandler(event:Event):void
		{
			if(!_lock)
			{
				//invalidate = true;
				//_isOver = true;
				//overEvent = event;
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					over.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function outHandler(event:Event):void
		{
			if(!_lock)
			{
				//invalidate = true;
				//_isOut = true;
				//outEvent = event;
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					out.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function keyDownHandler(event:KeyboardEvent):void
		{
			if(!_lock)
			{
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					invalidate = true;
					_keyIsDown = event.keyCode;
					keyDownEvent = event;
					keyDown.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function keyUpHandler(event:KeyboardEvent):void
		{
			if(!_lock)
			{
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					invalidate = true;
					_keyIsUp = event.keyCode;
					keyUpEvent = event;
					keyUp.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function releaseOutsideHandler(event:Event):void
		{
			if(!_lock)
			{
				//invalidate = true;
				//_isReleasedOutside = true;
				//releasedOutsideEvent = event;
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					releaseOutside.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function moveHandler(event:Event):void
		{
			if(!_lock)
			{
				//invalidate = true;
				//_isMoved = true;
				//movedEvent = event;
				if(componentManagers.length == 1 && !EntityUtils.sleeping(componentManagers[0]))
				{
					move.dispatch(componentManagers[0]);
				}
			}
		}
		
		public function removeAll():void
		{
			if(downNative != null) { downNative.removeAll(); }
			if(upNative != null) { upNative.removeAll(); }
			if(clickNative != null) { clickNative.removeAll(); }
			if(touchNative != null) { touchNative.removeAll(); }
			if(overNative != null) { overNative.removeAll(); }
			if(outNative != null) { outNative.removeAll(); }
			if(releaseOutsideNative != null){releaseOutsideNative.removeAll();}
			if(keyUpNative != null) { keyUpNative.removeAll(); }
			if(keyDownNative != null) { keyDownNative.removeAll(); }
			
			if(down != null) { down.removeAll(); }
			if(up != null) { up.removeAll(); }
			if(click != null) { click.removeAll(); }
			if(over != null) { over.removeAll(); }
			if(out != null) { out.removeAll(); }
			if(releaseOutside != null){releaseOutside.removeAll();}
			if(keyDown != null) { keyDown.removeAll(); }
			if(keyUp != null) { keyUp.removeAll(); }
		}
	}
}
