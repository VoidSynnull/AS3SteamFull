package game.ui.elements 
{
	import flash.display.DisplayObjectContainer;
	
	import org.osflash.signals.natives.NativeSignal;

	public class UIElement
	{
		public function UIElement() 
		{
			
		}
		
		public function destroy():void
		{
			if ( displayObject != null )
			{
				if(displayObject.parent)
				{
					displayObject.parent.removeChild( displayObject );
				}
				displayObject = null;
			}
			removeSignals();
		}
		
		public function removeSignals():void
		{
			if (down != null)
			{
				down.removeAll();
			}
			
			if (up != null)
			{
				up.removeAll();
			}
			
			if (click != null)
			{
				click.removeAll();
			}
			
			if (over != null)
			{
				over.removeAll();
			}
			
			if (out != null)
			{
				out.removeAll();
			}
		}
		
		public var displayObject:DisplayObjectContainer;
		public var down:NativeSignal;
		public var up:NativeSignal;
		public var click:NativeSignal;
		public var over:NativeSignal;
		public var out:NativeSignal;
	}
}