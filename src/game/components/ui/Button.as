package game.components.ui
{	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.creators.InteractionCreator;
	
	import game.systems.ui.ButtonSystem;
	
	public class Button extends Component
	{
		public var value:*;

		public var invalidate:Boolean = false;	// set to true when an update to button is necessary
		public var active:Boolean = true;		// if button responds to interactions or not, if false is essentially ignore by ButtonSystem

		private var _currentState:String = InteractionCreator.UP;
		public function get currentState():String	{ return _currentState; }
		public function set state(value:String):void	
		{ 
			switch (value)
			{
				case InteractionCreator.UP:
					this.isDisabled = false;
					_currentState = InteractionCreator.UP;
					invalidate = true;	
					break;
				case InteractionCreator.DOWN:
					this.isDisabled = false;
					_currentState = InteractionCreator.DOWN;
					invalidate = true;	
					break;
				case InteractionCreator.OVER:
					this.isDisabled = false;
					_currentState = InteractionCreator.OVER;
					invalidate = true;	
					break;
				case ButtonSystem.DISABLED:
					this.isDisabled = true;
					break;
				case ButtonSystem.SELECTED:
					this.isSelected = true;
					break;
				default:
					trace("Error :: Button :: invalid state value: " + value );
			}
		}
		
		private var _isSelected:Boolean = false;
		public function get isSelected():Boolean	{ return _isSelected; }
		public function set isSelected( bool:Boolean):void
		{
			if( _isSelected != bool )	// if disabled has changed
			{
				_isSelected = bool;
				invalidate = true;
			}
		}
		public function toggleSelected():void
		{
			_isSelected = !_isSelected;	// if disabled has changed
			invalidate = true;
		}

		public var _disableInvalidate:Boolean = false;
		private var _isDisabled:Boolean = false;
		public function get isDisabled():Boolean	{ return _isDisabled; }
		public function set isDisabled( bool:Boolean):void
		{
			if( _isDisabled != bool )	// if disabled has changed
			{
				_isDisabled = bool;
				invalidate = true;
				_disableInvalidate = true;
				if( !bool )	// isDisabled is turned off, turn active back on
				{
					active = true;
					_currentState = InteractionCreator.UP;
				}
				else
				{
					_currentState = ButtonSystem.DISABLED;
				}
			}
		}
		
		public var isAnimate:Boolean = false;	// if true will call gotoAndPlay, rather than gotoAndStop NOT IMPLEMENTED YET


		public function downHandler(entity:Entity = null):void
		{
			if( !isDisabled )
			{
				invalidate = true;
				_currentState = InteractionCreator.DOWN;
			}
		}
		
		public function overHandler(entity:Entity = null):void
		{
			if( !isDisabled )
			{
				invalidate = true;
				_currentState = InteractionCreator.OVER;
			}
		}
		
		public function upHandler(entity:Entity = null):void
		{
			if( !isDisabled )
			{
				// TODO :: need to check if isOver is actually true, when upHandler is called after down has ended...
				invalidate = true;
				
				/*
				Changed this to OVER because when you get an UP event, you're still technically
				OVER the button. This is leading to incorrect behavior with button states after
				clicking. - Drew
				*/
				//_currentState = InteractionCreator.UP;
				_currentState = InteractionCreator.OVER;
			}
		}

		public function outHandler(entity:Entity = null ):void
		{
			if( !isDisabled )
			{
				invalidate = true;
				_currentState = InteractionCreator.UP;
			}
		}
		
		public function clickHandler(entity:Entity = null):void
		{
		}
	}
}