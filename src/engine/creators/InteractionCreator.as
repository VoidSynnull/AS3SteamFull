/*
 * InteractionCreator
 * 
 * Provides signals for interaction events.  These can be changed per device if necessary
 */


package engine.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	
	import game.ui.elements.UIElement;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	public class InteractionCreator
	{		
		/**
		 * Creates an interaction of a specific type.
		 * In most cases wraps MouseEvents into a Signal.
		 * @param	displayObject
		 * @param	type
		 * @return
		 */
		public static function create(displayObject:DisplayObjectContainer, type:String):NativeSignal
		{
			var event:NativeSignal;
			
			switch(type)
			{
				case UP :
					event = new NativeSignal(displayObject, MouseEvent.MOUSE_UP, MouseEvent);
				break;
				
				case DOWN :
					event = new NativeSignal(displayObject, MouseEvent.MOUSE_DOWN, MouseEvent);
				break;
				
				case OVER :
					event = new NativeSignal(displayObject, MouseEvent.MOUSE_OVER, MouseEvent);
				break;
				
				case CLICK :
					event = new NativeSignal(displayObject, MouseEvent.CLICK, MouseEvent);
				break;
				
				case TOUCH:
					Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
					event = new NativeSignal(displayObject, TouchEvent.TOUCH_TAP, TouchEvent);
				break;
				
				case MOVE :
					event = new NativeSignal(displayObject, MouseEvent.MOUSE_MOVE, MouseEvent);
				break;
				
				case OUT :
					event = new NativeSignal(displayObject, MouseEvent.MOUSE_OUT, MouseEvent);
				break;
				
				case RELEASE_OUT :
					// we hardcode MouseEvent.RELEASE_OUTSIDE to prevent asdocs errors
					event = new NativeSignal(displayObject, "releaseOutside", MouseEvent);
				break;
				
				case KEY_UP :
					event = new NativeSignal(displayObject.stage, KeyboardEvent.KEY_UP, KeyboardEvent);
				break;
				
				case KEY_DOWN :
					event = new NativeSignal(displayObject.stage, KeyboardEvent.KEY_DOWN, KeyboardEvent);
				break;
			}
						
			return(event);
		}
		
		
		
		/**
		 * Adds interaction signals to a UIElement
		 * @param	element
		 * @param	interactions
		 * @return
		 */
		public static function addToUIElement(element:UIElement, interactions:Array = null):UIElement
		{
			if (interactions == null)
			{
				interactions = new Array(InteractionCreator.CLICK, InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.OUT);
			}
			
			var current:String;
			
			for (var n:Number = 0; n < interactions.length; n++)
			{
				current = interactions[n];
				
				element[current] = InteractionCreator.create(element.displayObject, current);
			}
			
			return(element);
		}		
		
		/**
		 * Adds interaction signals to an Interaction component
		 * @param	displayObject
		 * @param	interactions
		 * @param	component
		 * @return
		 */
		public static function addToComponent(displayObject:DisplayObjectContainer, interactions:Array, component:Interaction):Interaction
		{
			var current:String;
			var nativeSignal:NativeSignal;
			var signal:Signal;
			
			// TODO :: Shouldn't replace existing signals
			for (var n:Number = 0; n < interactions.length; n++)
			{
				current = interactions[n];
				
				nativeSignal = InteractionCreator.create(displayObject, current);
				signal = new Signal(Entity);
				nativeSignal.add(component[current + "Handler"]);
				
				component[current] = signal;
				component[current + "Native"] = nativeSignal;
			}
			
			return(component);
		}
		
		/**
		 * Adds Interaction component to an Entity
		 * @param	entity
		 * @param	interactions
		 * @param	displayObject
		 * @return
		 */
		public static function addToEntity(entity:Entity, interactions:Array, displayObject:DisplayObjectContainer=null):Interaction
		{
			if (displayObject == null)
			{
				var display:Display = entity.get(Display);
				if ( display )
				{
					displayObject = display.displayObject;
					display.interactive = true;
				}
				else
				{
					trace( "Error :: InteractionCreator :: addToEntity :: Entity must have a Display component." );
					return(null); 
				}
			}
			
			if (displayObject != null)
			{
				displayObject.mouseEnabled = true;
				var interaction:Interaction = new Interaction();
				addToComponent(displayObject, interactions, interaction);
				entity.add(interaction);
				return(interaction);
			}
			else
			{
				return(null);
			}
		}
		
		/**
		 * Refreshes Interaction in case where display may have changed.
		 * @param entity
		 * @param displayObject
		 */
		public static function refresh( entity:Entity, displayObject:DisplayObjectContainer=null):void
		{
			var interaction:Interaction = entity.get(Interaction);
			if( interaction )
			{
				if (displayObject == null)
				{
					var display:Display = entity.get(Display);
					if ( display )
					{
						displayObject = display.displayObject;
						display.interactive = true;
					}
					else
					{
						trace( "Error :: InteractionCreator :: addToEntity :: Entity must have a Display component." );
						return;
					}
				}
				
				if (displayObject != null)
				{
					displayObject.mouseEnabled = true;

					var current:String;
					var nativeSignal:NativeSignal;
					var signal:Signal;
					
					for (var n:int = 0; n < ALL.length; n++)
					{
						current = ALL[n];
						nativeSignal = interaction[ current + "Native" ] as NativeSignal;
						
						if( nativeSignal)	// check if Interaction has NativeSignal of matching type
						{
							nativeSignal.removeAll();
							nativeSignal = InteractionCreator.create(displayObject, current);
							nativeSignal.add(interaction[current + "Handler"]);
							//interaction[current + "Native"] = nativeSignal;
						}
					}
				}
			}
		}
		
		public static const UP:String = "up";
		public static const DOWN:String = "down";
		public static const OVER:String = "over";
		public static const CLICK:String = "click";
		public static const TOUCH:String = "touch";
		public static const MOVE:String = "move";
		public static const OUT:String = "out";
		public static const RELEASE_OUT:String = "releaseOutside";
		public static const KEY_UP:String = "keyUp";
		public static const KEY_DOWN:String = "keyDown";
		
		private static const ALL:Vector.<String> = new <String>[ UP, DOWN, OVER, CLICK, MOVE, OUT, RELEASE_OUT, KEY_UP, KEY_DOWN ];
	}
}
