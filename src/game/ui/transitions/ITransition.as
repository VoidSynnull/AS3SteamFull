package game.ui.transitions
{
	public interface ITransition
	{
		function transitionIn(callback:Function = null):void;
		function transitionOut(callback:Function = null):void;
		function transitionReady():void;
		function get manualClose():Boolean
	}
}