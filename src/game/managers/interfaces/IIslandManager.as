package game.managers.interfaces
{
	import game.data.game.GameData;

	public interface IIslandManager
	{
		function loadScene(scene:*, playerX:Number = NaN, playerY:Number = NaN, direction:String = null, fadeInTime:Number = NaN, fadeOutTime:Number = NaN, onFailure:Function = null):void;
		function loadAndSetupDataForIsland(island:String, callback:Function = null, onFailure:Function = null):void;
		function get gameData():GameData;

		function get hudGroupClass():Class
		function set hudGroupClass( value:Class):void

		function get doorGroupClass():Class
		function set doorGroupClass( value:Class):void
	}
}
