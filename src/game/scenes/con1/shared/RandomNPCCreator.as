package game.scenes.con1.shared
{
	import flash.utils.Dictionary;
	
	import engine.group.Group;
	
	import game.data.character.LookData;
	import game.data.character.PartDefaults;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;

	public class RandomNPCCreator
	{
		public function RandomNPCCreator(group:Group, url:String)
		{
			this.group = group;
			
			group.shellApi.loadFile(group.shellApi.dataPrefix + url, xmlLoaded);
		}
		
		public function destroy():void
		{
			if(loaded)
			{
				loaded.removeAll();
				loaded = null;
			}
			
			if(_lookDict)
				_lookDict = null;
		}
		
		public function createRandomNPC(island:String = "random", randomParts:Boolean = false):LookData
		{
			var partsDefault:PartDefaults = new PartDefaults();
			var lookData:LookData = partsDefault.randomLookData(null);
			
			// Let's pick a random island
			var randomIsland:Array = _lookDict[island];
			if(island == "random")
			{
				randomIsland = _lookDict[getRandomIsland()];
			}
			
			var includedLooks:Array = new Array();
			var look:RandomLookData;
			for each(look in randomIsland)
			{
				if(look.gender == lookData.getAspect(SkinUtils.GENDER).value)
				{
					includedLooks.push(look);
				}
			}
			
			if(includedLooks.length == 0)
			{
				if(lookData.getAspect(SkinUtils.GENDER).value == SkinUtils.GENDER_FEMALE)
					lookData = partsDefault.randomLookData(null, SkinUtils.GENDER_MALE);
				else
					lookData = partsDefault.randomLookData(null, SkinUtils.GENDER_FEMALE);
				
				for each(look in randomIsland)
				{
					if(look.gender == lookData.getAspect(SkinUtils.GENDER).value)
					{
						includedLooks.push(look);
					}
				}
			}
			
			if(includedLooks.length == 1)
			{
				lookData.merge(includedLooks[0].lookData);
			}
			else
			{
				if(!randomParts)
					lookData.merge(includedLooks[int(Math.random() * includedLooks.length)].lookData);
				else
					lookData.merge(randomLookFromMultiple(includedLooks));
			}
				
			
			return lookData;
		}
		
		public function getRandomIsland():String
		{
			var randomDict:int = Math.random() * _dictLength;
			var count:int = 0;
			
			for each(var key:* in _lookDict)
			{
				if(count == randomDict)
				{
					return key[0].island;
				}
				count++;
			}
			
			return null;
		}
		
		private function randomLookFromMultiple(looks:Array):LookData
		{
			var parts:Dictionary = new Dictionary();
			var randLook:LookData = new LookData();
			
			for each(var look:RandomLookData in looks)
			{
				checkIfAdd(parts, look.lookData, SkinUtils.HAIR);
				checkIfAdd(parts, look.lookData, SkinUtils.MOUTH);
				checkIfAdd(parts, look.lookData, SkinUtils.MARKS);
				checkIfAdd(parts, look.lookData, SkinUtils.FACIAL);
				checkIfAdd(parts, look.lookData, SkinUtils.PANTS);
				checkIfAdd(parts, look.lookData, SkinUtils.SHIRT);
				checkIfAdd(parts, look.lookData, SkinUtils.OVERPANTS);
				checkIfAdd(parts, look.lookData, SkinUtils.OVERSHIRT);
				checkIfAdd(parts, look.lookData, SkinUtils.ITEM);
				checkIfAdd(parts, look.lookData, SkinUtils.PACK);
			}
			
			for(var key:String in parts)
			{
				if(Math.random() > .35)
				{
					var randomInt:int = Math.floor(Math.random() * parts[key].length);
					randLook.setValue(key, parts[key][randomInt]);
				}
			}
			
			return randLook;
		}
		
		private function checkIfAdd(dict:Dictionary, lookData:LookData, type:String):void
		{
			var part:* = lookData.getValue(type);
			
			if(part != null)
			{
				if(dict[type] == null) 
					dict[type] = new Array();
				
				dict[type].push(part);	
			}
		}
		
		private function xmlLoaded(xml:XML, handler:Function = null):void
		{
			var currentIsland:String;
			var currentGender:String;
			
			for each(var look:XML in xml.children())
			{
				for each(var subLook:XML in look.children())
				{
					if(subLook.name().localName == "tags")
					{
						for each(var tag:XML in subLook.children())
						{
							if(tag.@*.toString() == "island")
							{
								currentIsland = tag;
							}
							else if(tag.@*.toString() == "gender")
							{
								currentGender = tag;
							}
						}
					}
					else if(subLook.name().localName == "parts")
					{
						if(_lookDict[currentIsland] == null)
						{
							_lookDict[currentIsland] = new Array();
							_dictLength++;
						}
						
						_lookDict[currentIsland].push(new RandomLookData(subLook, currentGender, currentIsland));
					}
				}
			}
			
			loaded.dispatch();
			isLoaded = true;
		}
		
		public var isLoaded:Boolean = false;
		public var loaded:Signal = new Signal();
		private var group:Group;
		private var _dictLength:Number = 0;
		private var _lookDict:Dictionary = new Dictionary();
	}
}