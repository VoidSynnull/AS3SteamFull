package game.components.multiplayer.chat
{
	import ash.core.Component;
	
	import game.components.smartFox.SFScenePlayer;
	
	import org.osflash.signals.Signal;
	
	public class MsgBalloon extends Component
	{
		public var updated:Signal = new Signal(MsgBalloon);
		public var sfPlayer:SFScenePlayer;	// TODO :: Ideally don't have components nested inside other components. mightbe another way to handle this. - Bard

		public function set msg($message:String):void{
			_msg = $message;
			updated.dispatch(this);
		}
		
		public function get msg():String{ return _msg }
		
		private var _msg:String;
		
	}
	
}
