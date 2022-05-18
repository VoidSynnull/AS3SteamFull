package game.proxy
{
	import flash.utils.Dictionary;
	
	import game.data.character.LookData;

	public interface ILegacyDataManager
	{
		function savePlayerLook( lookData:LookData, callback:Function=null):void
		function getUserField( fieldId:String ):*;
		function getUserFields( fieldIds:Array ):Dictionary;	
		function setUserField( fieldId:String, fieldValue:*):void
	}
}