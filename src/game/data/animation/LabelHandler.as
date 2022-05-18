package game.data.animation
{
	public class LabelHandler
	{
		public function LabelHandler( label:String, handler:Function, listenOnce:Boolean = true )
		{
			this.label = label;
			this.handler = handler;
			this.listenOnce = listenOnce;
		}
		
		public var label:String;
		public var handler:Function;
		public var listenOnce:Boolean;
	}
}