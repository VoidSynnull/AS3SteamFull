package game.scene.template
{
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.group.Group;
	import engine.systems.AudioSequenceSystem;
	import engine.systems.PositionalAudioSystem;
	
	import game.data.sound.SoundParser;
	import game.systems.SystemPriorities;
	
	public class AudioGroup extends Group
	{
		public function AudioGroup()
		{
			super();
			super.id = GROUP_ID;
		}
		
		public function setupGroup(group:Group, xml:XML):void
		{
			if(xml)
			{
				var soundParser:SoundParser = new SoundParser();
				_soundData = soundParser.parse(xml);
			}
			
			group.addSystem(new PositionalAudioSystem(), SystemPriorities.updateSound);
			group.addSystem(new AudioSequenceSystem(), SystemPriorities.updateSound);
			
			group.addChildGroup(this);
		}
		
		public function addAudioToAllEntities():void
		{
			if(_soundData)
			{
				var entity:Entity;
				
				for(var n:String in _soundData)
				{
					entity = super.parent.getEntityById(n);
					
					if(entity)
					{
						addAudioToEntity(entity, n);
					}
				}
			}
		}
		
		public function addAudioToEntity(entity:Entity, id:String = null):void
		{
			if(id == null)
			{
				var idComponent:Id = entity.get(Id);
				
				if(idComponent != null)
				{
					id = idComponent.id;
				}
			}
			
			var audio:Audio = entity.get(Audio);
			
			if(audio == null)
			{
				audio = new Audio();
				entity.add(audio);
			}
			
			if(id != null)
			{
				if(_soundData != null)
				{
					var allEventAudio:Dictionary = _soundData[id];
					
					if(allEventAudio != null)
					{
						audio.allEventAudio = allEventAudio;
						super.shellApi.setupEventTrigger(audio);
					}
				}
				else
				{
					trace("SoundGroup :: Error : Sound data has not been created.  Call 'create(xml)' first.");
				}
			}
		}
		
		public function get audioData():Dictionary { return(_soundData); }
		private var _soundData:Dictionary;
		public static const GROUP_ID:String = "audioGroup";
	}
}