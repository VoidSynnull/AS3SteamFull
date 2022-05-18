package game.ui.elements
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;

	public class TabElement
	{
		public var displayObject:DisplayObjectContainer;
		public var index:uint;
		public var buttonEntity:Entity;

		public var id:String;
		public var title:String;
		
		protected const OPEN:String = "open";
		protected const CLOSE:String = "close";
		protected const OPENED:String = "opened";
		protected const CLOSED:String = "closed";
		
		public function TabElement( id:String = "", title:String = "")
		{
			this.id = id;
			this.title = title;
		}
		
		// 
		/**
		 * Override for setup of unique tabs
		 */
		public function init():void
		{

		}
		
		public function setOpened( bool:Boolean = false ):void
		{
			if( bool )
			{
				Timeline(buttonEntity.get(Timeline)).gotoAndStop( OPENED );
			}
			else
			{
				Timeline(buttonEntity.get(Timeline)).gotoAndStop( CLOSED );
			}
		}
		
		public function open( onOpenedHandler:Function = null ):void
		{
			var timeline:Timeline = buttonEntity.get(Timeline);
			timeline.gotoAndPlay( OPEN );
			
			if( onOpenedHandler != null )
			{
				timeline.handleLabel( OPENED, onOpenedHandler );
			}
		}
		
		public function close( onClosedHandler:Function = null ):void
		{
			var timeline:Timeline = buttonEntity.get(Timeline);
			timeline.gotoAndPlay( CLOSE );
			
			if( onClosedHandler != null )
			{
				timeline.handleLabel( OPENED, onClosedHandler );
			}
		}
	}
}