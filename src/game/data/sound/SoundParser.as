/**
 * Parses XML with scene data.
 */

package game.data.sound
{	
	import flash.utils.Dictionary;
	
	import engine.managers.SoundManager;
	
	import game.data.game.GameEvent;
	import game.util.ArrayUtils;
	import game.util.DataUtils;
	
	public class SoundParser
	{				
		public function parse(xml:XML):Dictionary
		{		
			var data:Dictionary = new Dictionary(true);
			var sounds:XMLList = xml.children();
			var type:String;
			var action:String;
			
			for (var i:uint = 0; i < sounds.length(); i++)
			{	
				type = DataUtils.getString(sounds[i].attribute("type"));
				action = DataUtils.useString(sounds[i].attribute("action"), type);
				
				parseSound(sounds[i], data, type, action);
			}
			
			return(data);
		}
		
		public function parseSound(xml:XML, data:Dictionary, type:String, action:String):void
		{
			var assets:XMLList = xml.children();
			var assetData:Dictionary = new Dictionary();
			var soundData:SoundData;
			
			for (var i:uint = 0; i < assets.length(); i++)
			{					
				soundData = parseAsset(assets[i], type, action);
				
				if(data[soundData.id] == null)
				{
					data[soundData.id] = new Dictionary();
				}
				
				if(action == null)	
				{
					action = type;
				}
				
				if(data[soundData.id][soundData.event] == null)
				{
					data[soundData.id][soundData.event] = new Dictionary();
				}
				
				if(data[soundData.id][soundData.event][action] == null)
				{
					data[soundData.id][soundData.event][action]  = new Dictionary();
				}
				
				data[soundData.id][soundData.event][action] = soundData;
			}
		}
		
		public function parseAsset(xml:XML, type:String, action:String):SoundData
		{
			var prefix:String = "";
			var absoluteUrl:Boolean = DataUtils.useBoolean(xml.attribute("absoluteUrl"), false);
			var data:SoundData = new SoundData();
			var asset:String = xml.children()[0];
			
			if(!absoluteUrl)
			{
				if(type == SoundType.EFFECTS) { prefix = SoundManager.EFFECTS_PATH; }
				else if(type == SoundType.AMBIENT) { prefix = SoundManager.AMBIENT_PATH; }
				else if(type == SoundType.MUSIC) { prefix = SoundManager.MUSIC_PATH; }
			}
			
			if(asset.indexOf(",") > -1)
			{
				data.asset = DataUtils.getArray(asset);
				ArrayUtils.addPrefix(data.asset, prefix);
			}
			else
			{
				if(asset != "none")
				{
					data.asset = prefix + DataUtils.getString(asset);
				}
			}
			
			data.type = type;
			data.action = action;
			data.event = DataUtils.getString(xml.attribute("event"));
			data.triggeredByEvent = DataUtils.getString(xml.attribute("triggeredByEvent"));
			data.id = DataUtils.useString(xml.attribute("id"), SCENE_SOUND);
			data.loop = DataUtils.getBoolean(xml.attribute("loop"));
			data.fade = DataUtils.getBoolean(xml.attribute("fade"));
			data.exclusiveType = DataUtils.getBoolean(xml.attribute("exclusiveType"));
			data.exclusive = DataUtils.getBoolean(xml.attribute("exclusive"));
			data.allowOverlap = DataUtils.useBoolean(xml.attribute("allowOverlap"), true);
			data.baseVolume = DataUtils.useNumber(xml.attribute("baseVolume"), 1);
			data.absoluteUrl = absoluteUrl;
			
			if(!DataUtils.isNull(xml.attribute("modifiers")))
			{
				data.modifiers = DataUtils.getArray(xml.attribute("modifiers"));
			}
			
			if(data.event == null)
			{
				if(data.triggeredByEvent != null)
				{
					data.event = data.triggeredByEvent;
				}
				else
				{
					data.event = GameEvent.DEFAULT;
				}
			}
			
			return(data);
		}
		
		public static const SCENE_SOUND:String = "sceneSound";
	}
}